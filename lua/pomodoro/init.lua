-- inspired from the plugin nomodoro created by @dbinagi
-- Thank you for your work!
-- I made some changes to be suited for my personal needs

-- Check if already loaded
if vim.g.loaded_pomodoro then
	return
end
vim.g.loaded_pomodoro = true

local menu = require("pomodoro.menu")

local command = vim.api.nvim_create_user_command

local start_time = 0
local total_minutes = 0

local DONE = 0
local RUNNING = 1
local PAUSE = 2
local state = DONE

local already_notified_end = false

vim.g.break_count = 0

--- The default options
local DEFAULT_OPTIONS = {
	work_time = 25,
	short_break_time = 5,
	long_break_time = 15,
	break_cycle = 4,
	menu_available = true,
	texts = {
		play_command = "",
		sound_file = "",
		on_break_complete = "It's time for more knowledge!",
		on_work_complete = "Let's take a break!",
		work = "STAY FOCUSED for : ",
		break_time = "You still enjoy a break for : ",
		status_icon = "🍅 ",
		timer_format = "!%0M:%0S", -- To include hours: '!%0H:%0M:%0S'
	},
	on_work_complete = function() end,
	on_break_complete = function() end,
}

-- Local functions

local previous_time_remaining = nil
local new_start = nil
local function time_remaining_seconds(duration, start)
	if state == PAUSE then
		if not previous_time_remaining then
			previous_time_remaining = duration * 60 - os.difftime(os.time(), new_start or start)
			new_start = nil
		end
		return previous_time_remaining
	end
	if previous_time_remaining and not new_start then
		new_start = os.difftime(os.time(), duration * 60 - previous_time_remaining)
		previous_time_remaining = nil
	end
	return duration * 60 - os.difftime(os.time(), new_start or start)
end

local function time_remaining(duration, start)
	return os.date(vim.g.pomodoro.texts.timer_format, time_remaining_seconds(duration, start))
end

local function is_work_time(duration)
	return duration == vim.g.pomodoro.work_time
end

-- Plugin functions

local pomodoro = {}

function pomodoro.start(minutes)
	start_time = os.time()
	total_minutes = minutes
	already_notified_end = false
	state = RUNNING
end

function pomodoro.pause()
	state = PAUSE
end

function pomodoro.continue()
	state = RUNNING
end

function pomodoro.is_pause()
	return state == PAUSE
end

function pomodoro.is_running()
	return state == RUNNING
end

function pomodoro.start_break()
	if pomodoro.is_short_break() then
		pomodoro.start(vim.g.pomodoro.short_break_time)
	else
		pomodoro.start(vim.g.pomodoro.long_break_time)
	end
end

function pomodoro.is_short_break()
	return vim.g.break_count % vim.g.pomodoro.break_cycle ~= 0 or vim.g.break_count == 0
end

function pomodoro.setup(options)
	local new_config = vim.tbl_deep_extend("force", DEFAULT_OPTIONS, options)
	vim.g.pomodoro = new_config
	menu.has_dependencies = new_config.menu_available
end

local previous_status = nil
function pomodoro.status()
	local status_string = "🍎 - Idle - 🍎"

	if previous_status then
		if pomodoro.is_pause() then
			return previous_status
		else
			previous_status = nil
		end
	end

	if pomodoro.is_running() or pomodoro.is_pause() then
		if time_remaining_seconds(total_minutes, start_time) <= 0 then
			state = DONE
			-- if is_work_time(total_minutes) then
			-- 	status_string = vim.g.pomodoro.texts.on_work_complete
			-- 	if not already_notified_end then
			-- 		vim.g.pomodoro.on_work_complete()
			-- 		already_notified_end = true
			-- 		pomodoro.show_menu(2 + (pomodoro.is_short_break() and 0 or 1))
			-- 	end
			-- else
			-- 	status_string = vim.g.pomodoro.texts.on_break_complete
			-- 	if not already_notified_end then
			-- 		vim.g.pomodoro.on_break_complete()
			-- 		already_notified_end = true
			-- 		vim.g.break_count = vim.g.break_count + 1
			-- 		pomodoro.show_menu()
			-- 	end
			-- end
		else
			if is_work_time(total_minutes) then
				status_string = vim.g.pomodoro.texts.status_icon
					.. vim.g.pomodoro.texts.work
					.. time_remaining(total_minutes, start_time)
			else
				status_string = vim.g.pomodoro.texts.status_icon
					.. vim.g.pomodoro.texts.break_time
					.. time_remaining(total_minutes, start_time)
			end
		end
	end

	if pomodoro.is_pause() then
		previous_status = status_string
	end

	return status_string
end

function pomodoro.stop()
	state = DONE
end

function pomodoro.show_menu(focus_line)
	menu.show(pomodoro, focus_line)
end

-- Expose commands

command("PomoWork", function()
	pomodoro.start(vim.g.pomodoro.work_time)
end, {})

command("PomoPause", function()
	if pomodoro.is_running() then
		pomodoro.pause()
	end
end, {})

command("PomoContinue", function()
	if pomodoro.is_pause() then
		pomodoro.continue()
	end
end, {})

command("PomoBreak", function()
	pomodoro.start_break()
end, {})

command("PomoStop", function()
	pomodoro.stop()
end, {})

command("PomoStatus", function()
	print(pomodoro.status())
end, {})

command("PomoTimer", function(opts)
	pomodoro.start(opts.args)
end, { nargs = 1 })

if menu.has_dependencies then
	command("PomoMenu", function()
		pomodoro.show_menu()
	end, {})
end

return pomodoro
