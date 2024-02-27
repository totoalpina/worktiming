-- inspired from the plugin nomodoro created by @dbinagi
-- Thank you for your work!
-- I made some changes to be suited for my personal needs

local Menu
local event
local NuiText

local function on_close() end

local function check_dependencies()
	local ok, t = pcall(require, "nui.menu")
	if ok then
		Menu = t
		NuiText = require("nui.text")
	else
		return false
	end

	ok, t = pcall(require, "nui.utils.autocmd")
	if ok then
		event = t.event
	else
		return false
	end

	return true
end

local has_dependencies = check_dependencies()

local M = {}

local function show(pomodoro, focus_line)
	if not has_dependencies then
		return
	end
	if not focus_line then
		focus_line = 1
	end

	local popup_options = {
		border = {
			style = "rounded",
			padding = { 1, 3 },
		},
		position = "50%",
		size = {
			width = "45%",
		},
		opacity = 1,
		enter = true,
	}

	local menu_options = {
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>" },
			submit = { "<CR>", "<Space>" },
		},
		lines = {
			Menu.separator(tostring(pomodoro.status()), { text_align = "center", char = "" }),
			Menu.item("🪓 Work"),
			Menu.item("☕ Short Break"),
			Menu.item("🍔 Long Break"),
			Menu.item("⏹️  Stop"),
			Menu.separator(
				tostring(vim.g.break_count) .. (vim.g.break_count == 1 and " break taken" or " breaks taken"),
				{ text_align = "center", char = "" }
			),
		},
		on_close = on_close,
		on_submit = function(item)
			if item.text == "🪓 Work" then
				pomodoro.start(vim.g.pomodoro.work_time)
			elseif item.text == "☕ Short Break" then
				pomodoro.start(vim.g.pomodoro.short_break_time)
			elseif item.text == "🍔 Long Break" then
				pomodoro.start(vim.g.pomodoro.long_break_time)
			elseif item.text == "⏹️  Stop" then
				pomodoro.stop()
			elseif item.text == "⏯️  Continue" then
				pomodoro.continue()
			elseif item.text == "⏯️  Pause" then
				pomodoro.pause()
			end
		end,
	}

	if pomodoro.is_pause() then
		table.insert(menu_options.lines, 1, Menu.item("⏯️  Continue"))
	elseif pomodoro.is_running() then
		table.insert(menu_options.lines, 1, Menu.item("⏯️  Pause"))
	end

	local menu = Menu(popup_options, menu_options)

	menu:mount()

	menu:on(event.BufLeave, function()
		menu:unmount()
	end, { once = true })
	menu:map("n", "q", function()
		menu:unmount()
	end, { noremap = true })

	vim.cmd(":! afplay " .. vim.g.pomodoro.texts.sound_file)
	vim.api.nvim_win_set_cursor(menu.winid, { focus_line, 2 })
end

M.show = show
M.has_dependencies = has_dependencies

return M
