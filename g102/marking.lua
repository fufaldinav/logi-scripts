-- scope config block
local scope_bind = "mb2" -- mbX for mouse / X for kb
local scope_mode = "hold" -- hold / toggle
local short_scope_marking = true
-- mark config block
local mark_bind = "mb5" -- mbX for mouse / X for kb
local mark_timeout = 1500
local mark_enemy_timeout = 1500
-- debug
local debug = true

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!! DONT TOUCH NOTHING BELOW BLOCK !!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
function LoadingMessage(message)
    ClearLog()
    OutputLogMessage("Loading "..message.."...")
end

function ScriptLoadedMessage()
    ClearLog()
    OutputLogMessage("Script loaded! GLHF")
end

function DebugMessage(message)
    if debug == true then
        OutputLogMessage(message)
    end
end

-- *********************
-- *** Button class ***
-- *********************
LoadingMessage("Buttons")

Button = {}

function Button:new(bind)
    DebugMessage(bind)
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

    -- getters
    function t:get_keycode() return keycode end
    function t:device() return device end

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
-- *** mark_button ***
-- *******************
local mark_button = Button:new(mark_bind)
-- ******************
-- *** Mark class ***
-- ******************
LoadingMessage("Marks")

Mark = {}

function Mark:new(timeout, click_needed)
    local t = setmetatable({}, { __index = Mark })

    -- private
    local time = 0
    local timeout = (timeout or 1500)
    local button = (mark_button or Button:new("lalt"))
    local click_needed = (click_needed or 1)

    -- place mark
    function t:place()
        local current_time = GetRunningTime()
        local elapsed = current_time - time
        if elapsed < timeout then
            DebugMessage(">>> elapsed: "..elapsed.." timeout: "..timeout.." current time: "..current_time)
            return false
        end

        button.PressAndRelease(click_needed)
        time = GetRunningTime()
    end

    return t
end

-- *******************
-- *** simple mark ***
-- *******************
local simple_mark = Mark:new(mark_timeout, 1)

-- ******************
-- *** enemy mark ***
-- ******************
local enemy_mark = Mark:new(mark_enemy_timeout, 2)

-- ******************
-- *** Scope class ***
-- ******************
LoadingMessage("Scope")

Scope = {}

function Scope:new(mark)
    local t = setmetatable({}, { __index = Scope })

    -- private
    local mark = (mark or Mark:new(1500, 1))
    local mode = (mode or "hold")
    local time = 0
    local short_scope_marking = (short_scope_marking or false)
    local short_scope_timeout = 125

    if mode ~= "hold" and mode ~= "toggle" then
        DebugMessage("ERROR! unexpected parametr scope_mode=\"hold\" forced")
    end

    -- getters
    function t:mode() return mode end

    -- in scope now
    function t:on()
        return time > 0
    end

    -- not in scope
    function t:off()
        return time == 0
    end

    -- enter in scope
    function t:enter()
        if self:on() then DebugMessage("already in scope!!!") return end

        time = GetRunningTime()
        EnablePrimaryMouseButtonEvents(true)

        DebugMessage("***** scope entered")
        DebugMessage("enter_time: "..time)
    end

    -- exit from scope
    function t:exit()
        if self:off() then DebugMessage("already in scope!!!") return end

        local current_time = GetRunningTime()

        DebugMessage("***** scope exited")
        DebugMessage("exit_time: "..GetRunningTime())

        if short_scope_marking and current_time - time > short_scope_timeout then
            mark.place()
            DebugMessage("short click detected! placing mark...")
        end

        time = 0
        EnablePrimaryMouseButtonEvents(false)
    end

    -- toggle scope for same name mode
    function t:toggle()
        if self:on() then self:exit() end
        if self:off() then self:enter() end
    end

    return t
end

-- *******************
-- *** scope state ***
-- *******************
local scope = Scope:new(simple_mark, scope_mode, short_scope_marking)

ScriptLoadedMessage()

-- **************************
-- *** waiting for events ***
-- **************************
function OnEvent(event, button, family)
    if family == scope_button.device() and button == scope_button.get_keycode() then
        if scope.mode() == "hold" then
            if event == "MOUSE_BUTTON_PRESSED" then
                scope.enter()
            end
    
            if event == "MOUSE_BUTTON_RELEASED" then
                scope.exit()
            end
        elseif scope.mode() == "toggle" then
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
