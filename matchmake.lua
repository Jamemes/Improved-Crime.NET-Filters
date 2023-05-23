NetworkMatchMakingSTEAM._overhaul_keys = {
	update_52_3 = "payday2_v1.24.3",
	update_37_1 = "payday2_v1.15.1",
	update_24_2 = "payday2_release_v1.6.2",
	update_10 = "payday2_release_v1.0.34",
	release = "payday2_release_v0.0.22"
}

local function get_key(mod, link)
	dohttpreq(link, function(page)
		local _, st = string.find(tostring(page), 'NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY = \"')
		local key = string.sub(tostring(page), st + 1, -2)
		NetworkMatchMakingSTEAM._overhaul_keys[mod] = key
	end)
end

get_key("res_gold", "https://raw.githubusercontent.com/payday-restoration/restoration-mod/gold/lua/sc/network/matchmaking/networkmatchmakingsteam.lua")
get_key("res_dev", "https://raw.githubusercontent.com/payday-restoration/restoration-mod/dev/lua/sc/network/matchmaking/networkmatchmakingsteam.lua")

local data = NetworkMatchMakingSTEAM.load_user_filters
function NetworkMatchMakingSTEAM:load_user_filters()
	data(self)

	local one_down_filter = ACNF.Options:GetValue("one_down_filter") or "any"
	local mutators_filter = ACNF.Options:GetValue("mutators_filter") or "any"
	local modded_filter = ACNF.Options:GetValue("modded_filter") or "any"
	local job_plan = ACNF.Options:GetValue("job_plan") or -1
	
	managers.network.matchmake:add_lobby_filter("difficulty", managers.user:get_setting("crimenet_filter_difficulty"), ACNF.Options:GetValue("range_filter") or "equal")
	managers.network.matchmake:add_lobby_filter("one_down", 0, one_down_filter == "off" and "equal" or one_down_filter == "on" and "greater_than" or "equalto_or_greater_than")
	managers.network.matchmake:add_lobby_filter("mutators", 0, mutators_filter == "off" and "equal" or mutators_filter == "on" and "greater_than" or "equalto_or_greater_than")
	managers.network.matchmake:add_lobby_filter("mods", "1", modded_filter == "off" and "equal" or modded_filter == "on" and "greater_than" or "equalto_or_greater_than")
	managers.network.matchmake:add_lobby_filter("owner_level", ACNF.Options:GetValue("owner_level_filter") or 0, "equalto_or_greater_than")
	managers.network.matchmake:add_lobby_filter("job_plan", job_plan == 3 and 1 or job_plan == 4 and 2 or job_plan, job_plan > 2 and "not_equal" or "equal")
end

local function set_lobbies_amount(amount)
	if managers.menu:active_menu().logic:selected_node():parameters().name == "crimenet_filters" then
		local lobbies_counter = managers.menu:active_menu().logic:selected_node():item("looking_for_lobbies")
		if lobbies_counter then
			lobbies_counter:parameters().text_id = tostring(amount)
		end
		
		MenuCallbackHandler:refresh_node(lobbies_counter)
	end
end

local data = NetworkMatchMakingSTEAM.search_lobby
function NetworkMatchMakingSTEAM:search_lobby(friends_only, no_filters)
	if ACNF.Options:GetValue("matchmaking_key") ~= "standard" then
		self._search_friends_only = friends_only

		if not self:_has_callback("search_lobby") then
			return
		end

		local function validated_value(lobby, key)
			local value = lobby:key_value(key)

			if value ~= "value_missing" and value ~= "value_pending" then
				return value
			end

			return nil
		end

		local function refresh_lobby()
			if not self.browser then
				return
			end

			local lobbies = self.browser:lobbies()
			local info = {
				room_list = {},
				attribute_list = {}
			}

			if lobbies then
				for _, lobby in ipairs(lobbies) do
					table.insert(info.room_list, {
						owner_id = lobby:key_value("owner_id"),
						owner_name = lobby:key_value("owner_name"),
						room_id = lobby:id(),
						owner_level = lobby:key_value("owner_level")
					})

					local attributes_data = {
						numbers = self:_lobby_to_numbers(lobby),
						mutators = self:_get_mutators_from_lobby(lobby),
						crime_spree = tonumber(validated_value(lobby, "crime_spree")),
						crime_spree_mission = validated_value(lobby, "crime_spree_mission"),
						mods = validated_value(lobby, "mods"),
						one_down = tonumber(validated_value(lobby, "one_down")),
						skirmish = tonumber(validated_value(lobby, "skirmish")),
						skirmish_wave = tonumber(validated_value(lobby, "skirmish_wave")),
						skirmish_weekly_modifiers = validated_value(lobby, "skirmish_weekly_modifiers")
					}

					table.insert(info.attribute_list, attributes_data)
				end
			end

			self:_call_callback("search_lobby", info)
			
			local amount = table.size(info.room_list)
			set_lobbies_amount(amount == 0 and managers.localization:text("cn_menu_no_lobbies") or managers.localization:text("cn_menu_lobbies_amount", {amount = amount}))
			managers.menu_component:set_crimenet_players_online(table.size(info.room_list))
		end

		self.browser = LobbyBrowser(refresh_lobby, function ()
		end)
		
		local matchmake_key = NetworkMatchMakingSTEAM._overhaul_keys[ACNF.Options:GetValue("matchmaking_key")]
		
		if not matchmake_key then
			matchmake_key = NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY
		end
		
		local interest_keys = {}

		if matchmake_key then
			table.insert(interest_keys, matchmake_key)
		end

		self.browser:set_interest_keys(interest_keys)
		self.browser:set_distance_filter(self._distance_filter)

		self.browser:set_lobby_filter(matchmake_key, "true", "equal")

		self.browser:set_max_lobby_return_count(self._lobby_return_count)

		if Global.game_settings.playing_lan then
			self.browser:refresh_lan()
		else
			self.browser:refresh()
		end
	else
		data(self, friends_only, no_filters)
		set_lobbies_amount("")
	end
end
