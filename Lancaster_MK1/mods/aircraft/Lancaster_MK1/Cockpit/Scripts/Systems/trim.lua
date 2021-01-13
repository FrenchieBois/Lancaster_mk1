local dev = GetSelf()
dofile(LockOn_Options.common_script_path.."devices_defs.lua")
dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."Systems/stores_config.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")
dofile(LockOn_Options.script_path.."utils.lua")

startup_print("trim: load")

local update_time_step = 0.05
make_default_activity(update_time_step) --update will be called 20 times per second

local full_trim_time = 10.0 -- DCS SFM default seems to take 10s to fully trim roll from neutral to right, or pitch from neutral to up, or rudder from neutral to right
local trim_update = update_time_step / full_trim_time

-- some scaling adjustments, input values are in the -1 to 1 range, pass scaled version of these to DCS
local pitch_trim_scale = 0.4 -- thumbsuck value of 0.4, maybe needs to be tweaked
local roll_trim_scale = 0.06  -- thumbsuck value of 0.06, maybe needs to be tweaked
local rudder_trim_scale = 0.27  -- gives approx 7degrees max deflection, as per NATOPS

local sensor_data = get_base_data()

local trim_override_handle = get_param_handle("TRIM_OVERRIDE") -- set by AFCS(autopilot) system when it takes over
trim_override_handle:set(0)
local trim_override = false

local pitch_trim_handle = get_param_handle("PITCH_TRIM")
pitch_trim_handle:set(0.0)
local roll_trim_handle = get_param_handle("ROLL_TRIM")
roll_trim_handle:set(0.0)
local rudder_trim_handle = get_param_handle("RUDDER_TRIM")
rudder_trim_handle:set(0.0)
local pitch_trim_gauge_handle = get_param_handle("PITCH_TRIM_GAUGE")
pitch_trim_gauge_handle:set(0.0)
local yaw_trim_gauge_handle = get_param_handle("YAW_TRIM_GAUGE")
yaw_trim_gauge_handle:set(0.0)
local pitch_trim_knob_handle = get_param_handle("PITCH_TRIM_KNOB")
pitch_trim_knob_handle:set(0.0)
local roll_trim_knob_handle = get_param_handle("ROLL_TRIM_KNOB")
roll_trim_knob_handle:set(0.0)

local pitch_trim_gauge = WMA(0.15,0)
local yaw_trim_gauge = WMA(0.15,0)

dev:listen_command(Keys.TrimStop)
dev:listen_command(Keys.TrimUp)
dev:listen_command(Keys.TrimDown)
dev:listen_command(Keys.TrimRight)
dev:listen_command(Keys.TrimLeft)
dev:listen_command(Keys.TrimRightRudder)
dev:listen_command(Keys.TrimLeftRudder)
dev:listen_command(Keys.TrimCancel)
dev:listen_command(device_commands.rudder_trim)



local optionsData_trimspeed =  get_plugin_option_value("A-4E-C","trimSpeed","local")
local trimspeedfactor 

if optionsData_trimspeed == 0 then
	trimspeedfactor = 1
elseif optionsData_trimspeed == 1 then
	trimspeedfactor = 0.5
else
	trimspeedfactor = 1
end
--print_message_to_user(trimspeedfactor)


function post_initialize()
    startup_print("trim: postinit")

    local dev = GetSelf()
    local sensor_data = get_base_data()
    -- TODO: is there a better way to determine initial SFM pitch trim?
    pitch_trim_handle:set((sensor_data.getStickRollPosition()/100.0)/pitch_trim_scale)  -- for some reason, stick pitch is reported as stick roll in the API
    trim_override_handle:set(0)
    trim_override = false

    startup_print("trim: postinit end")
end

local trimming_updown = 0 -- 1=up,0=neutral,-1=down
local trimming_leftright = 0 -- 1=right,0=neutral,-1=left
local trimming_rudder_leftright = 0 -- 1=right,0=neutral,-1=left

local iCommandPlaneTrimPitchAbs=2022
local iCommandPlaneTrimRollAbs=2023
local iCommandPlaneTrimRudderAbs=2024
local iCommandPlaneTrimCancel=97
local iCommandPlaneTrimRoll	= 2020

function SetCommand(command,value)
    -- "primary" control is the clickable device, key commands trigger the clickable actions...
    -- dev:performClickableAction(device_commands.xxx, value, false)
    -- print_message_to_user("Trim "..command..","..tostring(value))
    if command == Keys.TrimStop then
        trimming_updown = 0
        trimming_leftright = 0
        trimming_rudder_leftright = 0
    elseif command == Keys.TrimUp then
        trimming_updown = 1
    elseif command == Keys.TrimDown then
        trimming_updown = -1
    elseif command == Keys.TrimRight then
        trimming_leftright = 1
    elseif command == Keys.TrimLeft then
        trimming_leftright = -1
    elseif command == Keys.TrimRightRudder then
        trimming_rudder_leftright = 1
    elseif command == Keys.TrimLeftRudder then
        trimming_rudder_leftright = -1
    elseif command == device_commands.rudder_trim then
        local rudder_trim=rudder_trim_handle:get()
        if rudder_trim > 0.9 and value <-0.9 then
            dev:performClickableAction(device_commands.rudder_trim, 1.0, true)
        elseif rudder_trim < -0.9 and value >0.9 then
            dev:performClickableAction(device_commands.rudder_trim, -1.0, true)
        else
            rudder_trim = value
            --print_message_to_user("Rudder Trim "..command..","..tostring(value))
            rudder_trim_handle:set(rudder_trim)
            dispatch_action(nil, iCommandPlaneTrimRudderAbs, rudder_trim*rudder_trim_scale)
        end
    elseif command == Keys.TrimCancel then
        trimming_updown = 0
        trimming_leftright = 0
        trimming_rudder_leftright = 0
        dispatch_action(nil, iCommandPlaneTrimCancel, 0)
        dispatch_action(nil, iCommandPlaneTrimRudderAbs, 0)
        dispatch_action(nil, iCommandPlaneTrimPitchAbs, 0)
        dispatch_action(nil, iCommandPlaneTrimRollAbs, 0)
        dev:performClickableAction(device_commands.rudder_trim, 0, false)
        roll_trim_handle:set(0)
        pitch_trim_handle:set(0)
        rudder_trim_handle:set(0)
    end
end

local prev_trim_override = trim_override
function update()
    -- TODO : take electric system into account
    --[[
    primary AC bus:
    HORIZONTAL STABILIZER TRIM

    primary DC bus:
    TRIM POSITION

    aft monitored AC bus:
    AILERON TRIM
    RUDDER TRIM

    --]]
    -- TODO : take hydraulic system into account
    trim_override = (trim_override_handle:get()==1)
    if prev_trim_override ~= trim_override then
        if trim_override then
            -- trim override started
            --print_message_to_user("trim override started")
        else
            -- trim override stopped, restore trim
            --print_message_to_user("trim override stopped")
            local pitch_trim = pitch_trim_handle:get()
            dispatch_action(nil, iCommandPlaneTrimPitchAbs, pitch_trim*pitch_trim_scale)
            local roll_trim = roll_trim_handle:get()
            dispatch_action(nil, iCommandPlaneTrimRollAbs, roll_trim*roll_trim_scale)
            local rudder_trim = rudder_trim_handle:get()
            dispatch_action(nil, iCommandPlaneTrimRudderAbs, rudder_trim*rudder_trim_scale)
        end
        prev_trim_override = trim_override
    end
    local pitch_trim=pitch_trim_handle:get()
    local roll_trim=roll_trim_handle:get()
    local rudder_trim=rudder_trim_handle:get()

    -- update trim position indicators
    if get_elec_primary_dc_ok() then
        pitch_trim_gauge_handle:set(pitch_trim_gauge:get_WMA(pitch_trim))
        yaw_trim_gauge_handle:set(yaw_trim_gauge:get_WMA(rudder_trim))
    else
        pitch_trim_gauge_handle:set(pitch_trim_gauge:get_WMA(0))
        yaw_trim_gauge_handle:set(yaw_trim_gauge:get_WMA(0))
    end

    -- update trim knob on joystick
    pitch_trim_knob_handle:set(trimming_updown)
    roll_trim_knob_handle:set(trimming_leftright)

    if trim_override then
        return
    end

    if trimming_updown ~= 0 then
        pitch_trim = pitch_trim + trimming_updown * trim_update * trimspeedfactor
        if pitch_trim>1 then
            pitch_trim=1
        elseif pitch_trim<-0.24 then
            pitch_trim=-0.24
        end
        pitch_trim_handle:set(pitch_trim)
        dispatch_action(nil, iCommandPlaneTrimPitchAbs, pitch_trim*pitch_trim_scale)
        --[[
        NOTE: according to NATOPS, longitudinal trim is actually
        provided by repositioning the entire horizontal stabilizer, not just
        the elevators. Not sure how to override this in SFM though, so for
        now we just trim with the elevators.
        --]]
    end
    if trimming_leftright ~= 0 then
        roll_trim = roll_trim + trimming_leftright * trim_update * trimspeedfactor
        if roll_trim>1 then
            roll_trim=1
        elseif roll_trim<-1 then
            roll_trim=-1
        end
        roll_trim_handle:set(roll_trim)
        dispatch_action(nil, iCommandPlaneTrimRoll, trimming_leftright * roll_trim_scale * 0.05)
    end
    if trimming_rudder_leftright ~= 0 then
        rudder_trim = rudder_trim + trimming_rudder_leftright * trim_update * trimspeedfactor
        if rudder_trim>1 then
            rudder_trim=1
        elseif rudder_trim<-1 then
            rudder_trim=-1
        end
        dev:performClickableAction(device_commands.rudder_trim, rudder_trim, true)
        --rudder_trim_handle:set(rudder_trim)
        --dispatch_action(nil, iCommandPlaneTrimRudderAbs, rudder_trim)
    end
end

startup_print("trim: load end")
need_to_be_closed = false -- close lua state after initialization

