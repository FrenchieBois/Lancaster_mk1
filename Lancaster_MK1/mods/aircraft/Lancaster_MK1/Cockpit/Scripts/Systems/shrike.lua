----------------------------------------------------------------
-- SHRIKE
----------------------------------------------------------------
-- This module will handle the logic for the seeker head and 
-- deploying the AGM-45 Shrike
----------------------------------------------------------------

dofile(LockOn_Options.common_script_path.."devices_defs.lua")
dofile(LockOn_Options.script_path.."devices.lua")
dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."utils.lua")

local SHRIKE = GetSelf()
local update_time_step = 0.02  --20 time per second
make_default_activity(update_time_step)
device_timer_dt     = 0.02  	--0.2  	

local sensor_data = get_base_data()

function debug_print(message)
    -- print_message_to_user(message)
end

SHRIKE_HORZ_FOV = 6
SHRIKE_VERT_FOV = 6

local aircraft_heading_deg = 0
local aircraft_pitch_deg = 0
local shrike_lock = false
local target_expire_time = 3.0
local shrike_lock_volume = 0
-- local shrike_sidewinder_volume = 0.5

shrike_armed_param = get_param_handle("SHRIKE_ARMED")
shrike_sidewinder_volume = get_param_handle("SHRIKE_SIDEWINDER_VOLUME")

-- populate table with contacts from the RWR
maxContacts = 9
contacts = {}
for i = 1, maxContacts do
    contacts[i] =
    {
        elevation_h 	= get_param_handle("RWR_CONTACT_0" .. i .. "_ELEVATION"),       -- elevation of the target relative to the aircraft
        azimuth_h 		= get_param_handle("RWR_CONTACT_0" .. i .. "_AZIMUTH"),         -- direction of the target relative to the aircraft
        power_h 		= get_param_handle("RWR_CONTACT_0" .. i .. "_POWER"),           -- strength of signal. use to detect contact and relative distance
        unit_type_h		= get_param_handle("RWR_CONTACT_0" .. i .. "_UNIT_TYPE"),       -- name of unit
        
        general_type_h	= get_param_handle("RWR_CONTACT_0" .. i .. "_GENERAL_TYPE"),    -- (0) EWR, (1) Aircraft, (2) Search Radar
        priority_h		= get_param_handle("RWR_CONTACT_0" .. i .. "_PRIORITY"),        -- some value which shows how dangerous the threat is to you
        signal_h		= get_param_handle("RWR_CONTACT_0" .. i .. "_SIGNAL"),          -- (1) Search, (2) Locked, (3) Missile launched
        time_h			= get_param_handle("RWR_CONTACT_0" .. i .. "_TIME"),            -- time since target data was updated
        source_h		= get_param_handle("RWR_CONTACT_0" .. i .. "_SOURCE"),          -- unique id of the object
    }
end

-- create table with shrike targets, tracked by source id
local shrike_targets = {}

function post_initialize()
    local RWR = GetDevice(devices.RWR)
    shrike_armed_param:set(0)
    -- RWR:set_power(true)

    -- initialise sounds
    sndhost             = create_sound_host("SHRIKE","HEADPHONES",0,0,0) -- TODO: look into defining this sound host for HEADPHONES/HELMET
    snd_shrike_tone     = sndhost:create_sound("Aircrafts/A-4E-C/agm-45a-shrike-tone")
    snd_shrike_search   = sndhost:create_sound("Aircrafts/A-4E-C/agm-45a-shrike-search")
    snd_shrike_lock     = sndhost:create_sound("Aircrafts/A-4E-C/agm-45a-shrike-lock")
end

function update()
    -- TODO: Check for AFT MON AC BUS and MONITORED DC BUS
    if get_elec_aft_mon_ac_ok() and get_elec_mon_dc_ok() then
    
        for i = 1, maxContacts do
            -- debug_print(i.." - Signal: "..tostring(contacts[i].signal_h:get()).." Power: "..tostring(contacts[i].power_h:get()).." General Type: "..tostring(contacts[i].general_type_h:get()).." Azimuth: "..tostring(math.rad(contacts[i].azimuth_h:get())).." Elevation: "..tostring(contacts[i].elevation_h:get()).." Unit Type: "..tostring(contacts[i].unit_type_h:get()).." Priority: "..tostring(contacts[i].priority_h:get()).." Time: "..tostring(contacts[i].time_h:get()).." Source: "..tostring(contacts[i].source_h:get()))
            -- debug_print(i.." Raw Azimuth: "..tostring(contacts[i].azimuth_h:get()).." Heading: "..tostring(math.deg(contacts[i].azimuth_h:get())))
            -- debug_print(i.." Raw Elevation: "..tostring(contacts[i].elevation_h:get()).." Elevation: "..tostring(math.deg(contacts[i].elevation_h:get())))
        end
        
        -- get aircraft current heading
        aircraft_heading_deg    = math.deg(sensor_data.getMagneticHeading())
        aircraft_pitch_deg      = math.deg(sensor_data.getPitch())
        local current_time      = get_absolute_model_time()
        
        -- TODO: Delete invalid targets after 3 seconds
        for i, contact in ipairs(contacts) do
            if contact.power_h:get() > 0 and contact.time_h:get() < 0.05 and (contact.general_type_h:get() == 2 or contact.general_type_h:get() == 0) then
                local id = contact.source_h:get()
                -- check if data already exists
                if shrike_targets[id] then
                    -- only update target data if data is new
                    if shrike_targets[id].raw_azimuth ~= contact.azimuth_h:get() then
                        updateTargetData(id, contact, current_time)
                    end
                else -- create new target
                    updateTargetData(id, contact, current_time)
                end
            end
        end

        shrike_lock = false
        -- sort through target list and get deviations
        for i, target in pairs(shrike_targets) do
            -- check contact is still valid based on time last updated.
            if (current_time - target.time_stored) < target_expire_time then
                if checkShrikeLock(target) then
                    shrike_lock = true
                end
            end
        end

    end -- check power is available

    -- update search volume with deviation
    update_lock_volume()

end

function SetCommand(command, value)
end

-- this function parses the raw data format into the target table
function updateTargetData(id, contact, current_time)
    target_data = {
        ['raw_azimuth']     = contact.azimuth_h:get(),
        ['raw_elevation']   = contact.elevation_h:get(),
        ['heading']         = getTargetHeading(math.deg(contact.azimuth_h:get()), aircraft_heading_deg),
        ['elevation']       = getTargetElevation(math.deg(contact.elevation_h:get()), aircraft_pitch_deg),
        ['time_stored']     = current_time
    }
    -- debug_print(contact.source_h:get().."Heading: "..target_data['heading'])
    shrike_targets[id] = target_data
end

function checkShrikeLock(target)
    -- calculate horizontal deviation
    local horz_deviation = math.abs(aircraft_heading_deg - target.heading)

    -- calculate vertical deviation
    local vert_deviation = math.abs((target.elevation + 4) - aircraft_pitch_deg)

    -- check if deviation is within params for a shrike lock
    if horz_deviation < (SHRIKE_HORZ_FOV/2) and vert_deviation < (SHRIKE_VERT_FOV/2) then
        shrike_lock_volume = (((3 - (get_absolute_model_time() - target.time_stored)) / 3) * 0.6) + 0.4
        return true
    else
        return false
    end
end

function getTargetHeading(target_azimuth_deg, aircraft_heading)
    if target_azimuth_deg > 180 then -- target is on the right
        contact_horz_deviation_deg = 360 - target_azimuth_deg
        return (aircraft_heading + contact_horz_deviation_deg) % 360
    else -- target is on the left
        contact_horz_deviation_deg = target_azimuth_deg
        return (aircraft_heading - contact_horz_deviation_deg) % 360
    end
end

function getTargetElevation(target_elevation_deg, aircraft_pitch)
    return aircraft_pitch + target_elevation_deg
end

function update_lock_volume()

    if shrike_armed_param:get() == 1 and (get_elec_aft_mon_ac_ok() and get_elec_mon_dc_ok()) then

        snd_shrike_tone:update(nil, LinearTodB(0.2 * shrike_sidewinder_volume:get()), nil)

        if not snd_shrike_tone:is_playing() then
            snd_shrike_tone:play_continue()
        end

        if not shrike_lock then
            snd_shrike_lock:update(nil, 0, nil)
            snd_shrike_search:update(nil, LinearTodB(1.0 * shrike_sidewinder_volume:get()), nil)
        else
            snd_shrike_lock:update(nil, LinearTodB(1.0 * shrike_sidewinder_volume:get()), nil)
            snd_shrike_search:update(nil, 0, nil)
        end

        if not snd_shrike_lock:is_playing() then
            snd_shrike_lock:play_continue()
        end
        if not snd_shrike_search:is_playing() then
            snd_shrike_search:play_continue()
        end
    else
        snd_shrike_tone:update(nil, 0, nil)
        snd_shrike_search:update(nil, 0, nil)
        snd_shrike_lock:update(nil, 0, nil)
    end

end


need_to_be_closed = false -- close lua state after initialization