local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.font_size = 10
config.term = "xterm-256color"
config.font = wezterm.font("JetBrainsMono NF")
config.color_scheme = "Catppuccin Mocha"
config.hide_tab_bar_if_only_one_tab = true
config.max_fps = 144
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

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

-- 1. LEADER KEY (Ctrl + b)
config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 2000 }

-- 2. HELPER FUNCTIONS
local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

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

local function program_exists(name)
	local success, _, _ = wezterm.run_child_process({ "where.exe", name })
	return success
end

local function load_powershell_on_windows(configParam)
	local windows_shells = { "pwsh.exe", "powershell.exe", "cmd.exe" }

	if wezterm.target_triple == "x86_64-pc-windows-msvc" then
		for _, shell in ipairs(windows_shells) do
			if program_exists(shell) then
				configParam.default_prog = { shell }
				break
			end
		end
	end
end

load_powershell_on_windows(config)

local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

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

	-- SUB-MENUS (Key Tables)
	-- Leader + w (Window Mode)
	{
		mods = "LEADER",
		key = "w",
		action = act.ActivateKeyTable({ name = "window_mode", one_shot = true }),
	},
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
		{ key = "v", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "s", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "d", action = act.CloseCurrentPane({ confirm = true }) },
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
