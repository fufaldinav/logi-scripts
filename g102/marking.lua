local config = {}
-- scope config block
config.scope_bind = "mb2" -- mbX for mouse / X for kb
config.scope_mode = "hold" -- hold / toggle
config.short_scope_marking = true
-- marker config block
config.marker_bind = "mb4" -- mbX for mouse / X for kb
config.marker_timeout = 1500
config.marker_enemy_timeout = 1500
-- debug log
config.debug_log = true

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!! DONT TOUCH NOTHING BELOW THIS COMMENT !!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
if config.debug_log then
    ClearLog()
end

local function debug_message(message, endline)
    if message == nil then
        message = ""
    end

    if endline == nil then
        endline = true
    end

    if config.debug_log then
        OutputLogMessage(message)
    end

    if endline then
        OutputLogMessage("\n")
    end
end

-- ********************
-- *** button class ***
-- ********************
debug_message("Creating buttons... ")

local button_class = {}

function button_class:new(button_bind)
    -- constract
    local _ = {}

    if string.match(button_bind, "mb%d") then
        _.device = "mouse"
        _.keycode = tonumber(string.match(button_bind, "%d", 3))
    else
        _.device = "kb"
        _.keycode = button_bind
    end

    local obj = {}

    obj.get_keycode = function()
        return _.keycode
    end

    obj.get_device = function()
        return _.device
    end

    obj.press_and_release = function()
        local function pause()
            Sleep(math.random(50, 100))
        end

        if _.device == "mouse" then
            PressMouseButton(_.keycode)
            pause()
            ReleaseMouseButton(_.keycode)
            pause()
        else
            PressKey(_.keycode)
            pause()
            ReleaseKey(_.keycode)
            pause()
        end
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- ********************
-- *** scope button ***
-- ********************
local scope_button = button_class:new(config.scope_bind)
debug_message("scope_button.get_keycode() = "..scope_button.get_keycode())
debug_message("scope_button.get_device() = "..scope_button.get_device())

-- *********************
-- *** marker button ***
-- *********************
local marker_button = button_class:new(config.marker_bind)
debug_message("marker_button.get_keycode() = "..marker_button.get_keycode())
debug_message("marker_button.get_device() = "..marker_button.get_device())

-- ********************
-- *** marker class ***
-- ********************
debug_message("Creating markers... ", false)

local marker_class = {}

function marker_class:new(timeout)
    -- _
    local _ = {}
    _.time = 0
    _.timeout = timeout
    _.button = marker_button

    local obj = {}

    -- place marker
    obj.place = function()
        local current_time = GetRunningTime()
        local elapsed_time = current_time - _.time

        if elapsed_time < _.timeout then
            debug_message("[INFO] TIMEOUT!!! left "..(_.timeout - elapsed_time).."ms")

            return
        end

        _.button.press_and_release()
        _.time = GetRunningTime()

        debug_message("[INFO] marker placed in "..current_time.."ms")
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- *********************
-- *** simple marker ***
-- *********************
local simple_marker = marker_class:new(config.marker_timeout)

-- ********************
-- *** enemy marker ***
-- ********************
local enemy_marker = marker_class:new(config.marker_enemy_timeout)

debug_message("done!")

-- *******************
-- *** scope class ***
-- *******************
debug_message("Creating scope... ")

local scope_class = {}

function scope_class:new(marker)

    local _ = {}
    _.marker = marker
    _.mode = config.scope_mode
    _.time = 0
    _.short_scope_marking = config.short_scope_marking
    _.short_scope_timeout = 125

    if _.mode ~= "hold" and _.mode ~= "toggle" then
        debug_message("ERROR! unexpected parametr, scope_mode=\"hold\" forced")
    end

    local obj = {}

    -- getters
    obj.get_mode = function()
        return _.mode
    end

    -- in scope now
    obj.is_on = function()
        return (_.time > 0)
    end

    -- not in scope
    obj.is_off = function()
        return (_.time == 0)
    end

    -- enter in scope
    obj.enter = function()
        if obj.is_on() then
            debug_message("[INFO] already in scope!!!")
            return
        end

        _.time = GetRunningTime()
        EnablePrimaryMouseButtonEvents(true)

        debug_message("[INFO] scope ON")
    end

    -- exit from scope
    obj.exit = function()
        if obj.is_off() then
            debug_message("[INFO] NOT in scope!!!")
            return
        end

        local current_time = GetRunningTime()
        local elapsed_time = current_time - _.time

        debug_message("[INFO] scope OFF after "..elapsed_time.."ms")

        if _.short_scope_marking and elapsed_time < _.short_scope_timeout then
            debug_message("[INFO] short scope detected!")
            _.marker.place()
        end

        _.time = 0
        EnablePrimaryMouseButtonEvents(false)
    end

    -- toggle scope for same name mode
    obj.toggle = function()
        if obj.is_on() then
            obj.exit()
            return
        end

        if obj.is_off() then
            obj.enter()
            return
        end

        debug_message("[ERROR] scope state is undefined")
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- *******************
-- *** scope state ***
-- *******************
local scope = scope_class:new(simple_marker)
debug_message("scope.get_mode() = "..scope.get_mode())

-- **************************
-- *** waiting for events ***
-- **************************
debug_message("Script loaded! GLHF\n")

function OnEvent(event, button, family)
    if button == scope_button.get_keycode() then
        if scope.get_mode() == "hold" then
            if event == "MOUSE_BUTTON_PRESSED" then
                scope.enter()
            end
    
            if event == "MOUSE_BUTTON_RELEASED" then
                scope.exit()
            end
        end

        if scope.get_mode() == "toggle" then
            if event == "MOUSE_BUTTON_RELEASED" then
                scope.toggle()
            end
        end
    end

    if (event == "MOUSE_BUTTON_PRESSED" and button == 1) then
        if scope.is_on() then
            enemy_marker.place()
        end
    end
end
