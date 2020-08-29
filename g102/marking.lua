-- scope config block
local scope_bind = "mb2" -- mbX for mouse / X for kb
local scope_mode = "hold" -- hold / toggle
local short_scope_marking = true
-- marker config block
local marker_bind = "mb5" -- mbX for mouse / X for kb
local marker_timeout = 1500
local marker_enemy_timeout = 1500
-- debug log
local debug_log = true

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!! DONT TOUCH NOTHING BELOW THIS COMMENT !!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ClearLog()

local function script_loading_message(message)
    OutputLogMessage("Loading "..message.."...\n")
end

local function script_loaded_message()
    OutputLogMessage("Script loaded! GLHF\n")
end

local function debug_message(message)
    if debug_log then
        OutputLogMessage(message)
    end
end

-- *********************
-- *** Button class ***
-- *********************
script_loading_message("Buttons")

local Button = {}

function Button:new(bind)
    local t = setmetatable({}, { __index = Button })

    -- constract
    local device
    local keycode

    -- constract
    if string.match(bind, "mb%d") then
        DebugMessage("1")
        device = "mouse"
        keycode = bind[3]
    else
        DebugMessage("2")
        device = "kb"
        keycode = bind
    end

    -- return local keycode value
    function t:get_keycode()
        return keycode
    end
    -- return local device value
    function t:get_device()
        return device
    end

    -- private
    local function emulate()
        Sleep(math.random(75, 125))

        if device == "mouse" then
            PressAndReleaseMouseButton(keycode)
        else
            PressAndReleaseKey(keycode)
        end
    end

    -- emulate mouse click or kb press and realease n-time
    function t:PressAndRelease(count)
        if count == nil then
            count = 1
        end

        while count > 0 do
            count = count - 1
            emulate()
        end
    end

    return t
end

-- ********************
-- *** scope_button ***
-- ********************
local scope_button = Button:new(scope_bind)

-- *******************
-- *** marker_button ***
-- *******************
local marker_button = Button:new(marker_bind)
-- ******************
-- *** Marker class ***
-- ******************
script_loading_message("Markers")

local Marker = {}

function Marker:new(timeout, click_needed)
    local t = setmetatable({}, { __index = Marker })

    -- private
    local time = 0
    local timeout = (timeout or 1500)
    local button = (marker_button or Button:new("lalt"))
    local click_needed = (click_needed or 1)

    -- place marker
    function t:place()
        local current_time = GetRunningTime()
        local elapsed = current_time - time
        if elapsed < timeout then
            debug_message(">>> elapsed: "..elapsed.." timeout: "..timeout.." current time: "..current_time)
            return false
        end

        button.PressAndRelease(click_needed)
        time = GetRunningTime()
    end

    return t
end

-- *******************
-- *** simple marker ***
-- *******************
local simple_mark = Marker:new(marker_timeout, 1)

-- ******************
-- *** enemy marker ***
-- ******************
local enemy_mark = Marker:new(marker_enemy_timeout, 2)

-- ******************
-- *** Scope class ***
-- ******************
script_loading_message("Scope")

local Scope = {}

function Scope:new(marker)
    local t = setmetatable({}, { __index = Scope })

    -- private
    local marker = (marker or Marker:new(1500, 1))
    local mode = (scope_mode or "hold")
    local time = 0
    local short_scope_marking = (short_scope_marking or false)
    local short_scope_timeout = 125

    if mode ~= "hold" and mode ~= "toggle" then
        debug_message("ERROR! unexpected parametr scope_mode=\"hold\" forced")
    end

    -- getters
    function t:get_mode()
        return mode
    end

    -- in scope now
    local function is_on()
        return (time > 0)
    end

    -- not in scope
    local function is_off()
        return (time == 0)
    end

    -- enter in scope
    function t:enter()
        if self:is_on() then debug_message("already in scope!!!") return end

        time = GetRunningTime()
        EnablePrimaryMouseButtonEvents(true)

        debug_message("***** scope entered")
        debug_message("enter_time: "..time)
    end

    -- exit from scope
    function t:exit()
        if self:is_off() then debug_message("already in scope!!!") return end

        local current_time = GetRunningTime()

        debug_message("***** scope exited")
        debug_message("exit_time: "..GetRunningTime())

        if short_scope_marking and current_time - time > short_scope_timeout then
            marker.place()
            debug_message("short click detected! placing marker...")
        end

        time = 0
        EnablePrimaryMouseButtonEvents(false)
    end

    -- toggle scope for same name mode
    function t:toggle()
        if self:is_on() then self:exit() end
        if self:is_off() then self:enter() end
    end

    return t
end

-- *******************
-- *** scope state ***
-- *******************
local scope = Scope:new(simple_mark, scope_mode, short_scope_marking)

script_loaded_message()

-- **************************
-- *** waiting for events ***
-- **************************
function OnEvent(event, button, family)
    if family == scope_button.get_device() and button == scope_button.get_keycode() then
        if scope.get_mode() == "hold" then
            if event == "MOUSE_BUTTON_PRESSED" then
                scope.enter()
            end
    
            if event == "MOUSE_BUTTON_RELEASED" then
                scope.exit()
            end
        elseif scope.get_mode() == "toggle" then
            if event == "MOUSE_BUTTON_RELEASED" then
                scope.toggle()
            end
        end
    end

    if (event == "MOUSE_BUTTON_PRESSED" and button == 1) then
        if scope.state == true then
            enemy_mark.place()
        end
    end
end
