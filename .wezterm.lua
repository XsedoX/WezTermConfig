local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.font_size = 10
config.term = "xterm-256color"

-- 1. LEADER KEY (Ctrl + b)
config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }

-- 2. HELPER FUNCTIONS
local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
	LeftArrow = "Left",
	DownArrow = "Down",
	UpArrow = "Up",
	RightArrow = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- Pass keys to Vim
				win:perform_action({
					SendKey = { key = key, mods = "CTRL" },
				}, pane)
			else
				-- Handle in WezTerm
				local direction = direction_keys[key]
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction, 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction }, pane)
				end
			end
		end),
	}
end

-- 3. KEY BINDINGS
config.keys = {
	-- SMART SPLITS (Movement)
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),

	-- SMART SPLITS (Resize)
	split_nav("resize", "LeftArrow"),
	split_nav("resize", "DownArrow"),
	split_nav("resize", "UpArrow"),
	split_nav("resize", "RightArrow"),

	-- DIRECT ACTIONS (Your custom bindings preserved for quick access)
	{ mods = "LEADER", key = "v", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER", key = "s", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER", key = "d", action = act.CloseCurrentPane({ confirm = true }) },

	-- SUB-MENUS (Key Tables)
	-- Leader + w (Window Mode)
	{
		mods = "LEADER",
		key = "w",
		action = act.ActivateKeyTable({ name = "window_mode", one_shot = true }),
	},
	-- Leader + t (Tab Mode)
	{
		mods = "LEADER",
		key = "Tab",
		action = act.ActivateKeyTable({ name = "tab_mode", one_shot = true }),
	},
}

-- 4. KEY TABLES (The sub-menus)
config.key_tables = {
	window_mode = {
		-- Uses your custom keys: v, s, d
		{ key = "s", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "v", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "d", action = act.CloseCurrentPane({ confirm = true }) },

		-- Resize Helpers inside the mode
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },

		-- Exit
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},

	tab_mode = {
		-- Uses 'd' for close, 'n' for new (standard)
		{ key = "d", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "Tab", action = act.SpawnTab("CurrentPaneDomain") },

		-- Navigation
		{ key = "[", action = act.ActivateTabRelative(-1) },
		{ key = "]", action = act.ActivateTabRelative(1) },

		-- Exit
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

return config
