Hooks:Add("LocalizationManagerPostInit", "advanced_filters_loc", function(...)
	LocalizationManager:add_localized_strings({
		menu_host_level = "Host level (Greater or Equal)",
		menu_equal = "Equal",
		menu_equalto_or_greater_than = "Greater or Equal",
		menu_equalto_less_than = "Less or Equal",

		cn_menu_no_lobbies = "No active servers",
		cn_menu_lobbies_amount = "Servers Online: $amount;",
	})

	if Idstring("russian"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			menu_host_level = "Уровень лидера лобби (Больше или равно)",
			menu_equal = "Равно",
			menu_equalto_or_greater_than = "Больше или равно",
			menu_equalto_less_than = "Меньше или равно",
			
			cn_menu_no_lobbies = "Нет активных сереров",
			cn_menu_lobbies_amount = "Онлайн сервера: $amount;",
		})
	end

	if Idstring("schinese"):key() == SystemInfo:language():key() then
		LocalizationManager:add_localized_strings({
			menu_host_level = "主机等级 (不小于)",
			menu_equal = "等于",
			menu_equalto_or_greater_than = "不小于",
			menu_equalto_less_than = "不大于",
		})
	end
end)

local data = MenuCrimeNetFiltersInitiator.update_node
function MenuCrimeNetFiltersInitiator:update_node(node)
	data(self, node)

	node:item("divider_difficulty1"):set_visible(self:is_standard())
	node:item("divider_difficulty2"):set_visible(self:is_standard())
	node:item("difficulty_range_filter"):set_visible(self:is_standard())
	node:item("one_down_filter"):set_visible(self:is_standard())
	node:item("modded_filter"):set_visible(self:is_standard())
	node:item("mutators_filter"):set_visible(self:is_standard())
	
	node:item("difficulty_range_filter"):set_value(ACNF.Options:GetValue("range_filter") or "equal")
	node:item("one_down_filter"):set_value(ACNF.Options:GetValue("one_down_filter") or "off")
	node:item("modded_filter"):set_value(ACNF.Options:GetValue("modded_filter") or "any")
	node:item("mutators_filter"):set_value(ACNF.Options:GetValue("mutators_filter") or "off")
	node:item("owner_level_filter"):set_value(ACNF.Options:GetValue("owner_level_filter") or 0)
	node:item("job_plan_filter"):set_value(ACNF.Options:GetValue("job_plan") or -1)
	node:item("matchmaking_key_filter"):set_value(ACNF.Options:GetValue("matchmaking_key") or -1)
	node:item("searching_by_nickname"):set_value(ACNF.Options:GetValue("search_nickname") or "off")
	node:item("nickname_input"):set_value(ACNF.Options:GetValue("nickname") or "")
end

local data = MenuCallbackHandler._reset_filters
function MenuCallbackHandler:_reset_filters(item)
	ACNF.Options:SetValue("range_filter", "equal")
	ACNF.Options:SetValue("one_down_filter", "off")
	ACNF.Options:SetValue("modded_filter", "any")
	ACNF.Options:SetValue("mutators_filter", "off")
	ACNF.Options:SetValue("owner_level_filter", 0)
	ACNF.Options:SetValue("owner_level_filter", -1)
	ACNF.Options:SetValue("matchmaking_key", "standard")
	ACNF.Options:SetValue("search_nickname", "off")
	ACNF.Options:SetValue("nickname", "")

	managers.network.matchmake:add_lobby_filter("difficulty", -1, "equal")
	managers.network.matchmake:add_lobby_filter("one_down", 0, "equal")
	managers.network.matchmake:add_lobby_filter("mutators", 0, "equal")
	managers.network.matchmake:add_lobby_filter("mods", "1", "equalto_or_greater_than")
	managers.network.matchmake:add_lobby_filter("owner_level", 0, "equalto_or_greater_than")
	managers.network.matchmake:add_lobby_filter("job_plan", -1, "equal")
	managers.network.matchmake:add_lobby_filter("host_name", "", "not_equal")
	
	data(self, item)
end

function MenuCallbackHandler:toggle_difficulty_range_filter(item)
	local range_filter = item:value()
	
	if ACNF.Options:GetValue("range_filter") == range_filter then
		return
	end
	
	ACNF.Options:SetValue("range_filter", range_filter)
	managers.network.matchmake:add_lobby_filter("difficulty", managers.network.matchmake:get_lobby_filter("difficulty"), ACNF.Options:GetValue("range_filter") or "equal")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
	managers.crimenet:update_difficulty_filter()
end

function MenuCallbackHandler:choice_difficulty_filter(item)
	local diff_filter = item:value()

	if managers.network.matchmake:get_lobby_filter("difficulty") == diff_filter then
		return
	end

	managers.network.matchmake:add_lobby_filter("difficulty", diff_filter, ACNF.Options:GetValue("range_filter") or "equal")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
	managers.user:set_setting("crimenet_filter_difficulty", diff_filter)
	managers.crimenet:update_difficulty_filter()
end

function MenuCallbackHandler:chocie_one_down_filter(item)
	local one_down_filter = item:value()
	
	if ACNF.Options:GetValue("one_down_filter") == one_down_filter then
		return
	end
	
	ACNF.Options:SetValue("one_down_filter", one_down_filter)
	managers.network.matchmake:add_lobby_filter("one_down", 0, one_down_filter == "off" and "equal" or one_down_filter == "on" and "greater_than" or "equalto_or_greater_than")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:choice_mutators_filter(item)
	local mutators_filter = item:value()
	
	if ACNF.Options:GetValue("mutators_filter") == mutators_filter then
		return
	end
	
	ACNF.Options:SetValue("mutators_filter", mutators_filter)
	managers.network.matchmake:add_lobby_filter("mutators", 0, mutators_filter == "off" and "equal" or mutators_filter == "on" and "greater_than" or "equalto_or_greater_than")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:choice_modded_filter(item)
	local modded_filter = item:value()
	
	if ACNF.Options:GetValue("modded_filter") == modded_filter then
		return
	end
	
	ACNF.Options:SetValue("modded_filter", modded_filter)
	managers.network.matchmake:add_lobby_filter("mods", "1", modded_filter == "off" and "equal" or modded_filter == "on" and "greater_than" or "equalto_or_greater_than")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:choice_owner_level_filter(item)
	local owner_level_filter = item:value()
	
	if ACNF.Options:GetValue("owner_level_filter") == owner_level_filter then
		return
	end
	
	ACNF.Options:SetValue("owner_level_filter", owner_level_filter)
	managers.network.matchmake:add_lobby_filter("owner_level", owner_level_filter, "equalto_or_greater_than")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:choice_job_plan_filter(item)
	local job_plan = item:value()
	
	if ACNF.Options:GetValue("job_plan") == job_plan then
		return
	end
	
	ACNF.Options:SetValue("job_plan", job_plan)
	managers.network.matchmake:add_lobby_filter("job_plan", job_plan == 3 and 1 or job_plan == 4 and 2 or job_plan, job_plan > 2 and "not_equal" or "equal")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:chocie_matchmaking_key(item)
	if ACNF.Options:GetValue("matchmaking_key") == item:value() then
		return
	end
	
	ACNF.Options:SetValue("matchmaking_key", item:value())
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:choice_allow_searching_by_nickname(item)
	local search_nickname = item:value()
	
	if ACNF.Options:GetValue("search_nickname") == search_nickname then
		return
	end
	
	ACNF.Options:SetValue("search_nickname", search_nickname)
	
	local nick_search_allowed = ACNF.Options:GetValue("nickname") ~= "" and ACNF.Options:GetValue("search_nickname") == "on"
	managers.network.matchmake:add_lobby_filter("owner_name", ACNF.Options:GetValue("search_nickname") == "on" and ACNF.Options:GetValue("nickname") or "", nick_search_allowed and "equal" or "not_equal")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

function MenuCallbackHandler:nickname_input_callback(item)
	if ACNF.Options:GetValue("nickname") == item:value() then
		return
	end
	
	ACNF.Options:SetValue("nickname", item:value())

	local nick_search_allowed = ACNF.Options:GetValue("nickname") ~= "" and ACNF.Options:GetValue("search_nickname") == "on"
	managers.network.matchmake:add_lobby_filter("owner_name", ACNF.Options:GetValue("search_nickname") == "on" and ACNF.Options:GetValue("nickname") or "", nick_search_allowed and "equal" or "not_equal")
	managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
end

