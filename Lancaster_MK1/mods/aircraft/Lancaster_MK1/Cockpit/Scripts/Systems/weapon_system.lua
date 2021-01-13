local WeaponSystem     = GetSelf()
dofile(LockOn_Options.common_script_path.."devices_defs.lua")
dofile(LockOn_Options.script_path.."Systems/stores_config.lua")
dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")
dofile(LockOn_Options.script_path.."utils.lua")

local update_rate = 0.006
make_default_activity(update_rate)

startup_print("weapon_system: load")

function debug_print(x)
    -- print_message_to_user(x)
    -- log.alert(x)
end

local sensor_data = get_base_data()
------------------------------------------------
----------------  CONSTANTS  -------------------
------------------------------------------------
local iCommandPlaneWingtipSmokeOnOff = 78
local iCommandPlaneJettisonWeapons = 82
local iCommandPlaneFire = 84
local iCommandPlaneFireOff = 85
local iCommandPlaneChangeWeapon = 101
local iCommandActiveJamming = 136
local iCommandPlaneJettisonFuelTanks = 178
local iCommandPlanePickleOn = 350
local iCommandPlanePickleOff = 351
--local iCommandPlaneDropFlareOnce = 357
--local iCommandPlaneDropChaffOnce = 358

-- station selector switch constants
local STATION_SALVO = -1
local STATION_SHRIKE = STATION_SALVO   -- later A-4E
local STATION_OFF = 0
local STATION_READY = 1
local station_debug_text={"SALVO", "OFF", "READY"}

-- function selector switch constants
local FUNC_OFF = 0
local FUNC_ROCKETS = 1
local FUNC_GM_UNARM = 2
local FUNC_SPRAY_TANK = 3
local FUNC_LABS = 4
local FUNC_BOMBS_GM_ARM = 5
local selector_debug_text={"OFF","ROCKETS","GM UNARM","SPRAY TANK","LABS","BOMBS & GM ARM"}

-- emergency selector switch constants
local EMER_WING = 0
local EMER_1 = 1
local EMER_2 = 2
local EMER_3 = 3
local EMER_4 = 4
local EMER_5 = 5
local EMER_ALL = 6
local emer_selector_debug_text={"WING", "PYLON 1", "PYLON 2", "PYLON 3", "PYLON 4", "PYLON 5", "ALL"}

-- bomb arm switch constants
local BOMB_ARM_TAIL = 0
local BOMB_ARM_OFF = 1
local BOMB_ARM_NOSETAIL = 2
local bomb_arm_debug_text={"TAIL", "OFF", "NOSETAIL"}

-- AWRS constants
local AWRS_quantity_array = { 0,2,3,4,5,6,8,12,16,20,30,40 }
local AWRS_mode_step_salvo = 0
local AWRS_mode_step_pairs = 1
local AWRS_mode_step_single = 2
local AWRS_mode_ripple_single = 3
local AWRS_mode_ripple_pairs = 4
local AWRS_mode_ripple_salvo = 5
local AWRS_mode_debug_text={"STEP SALVO", "STEP PAIRS", "STEP SINGLE", "RIPPLE SINGLE", "RIPPLE PAIRS", "RIPPLE SALVO"}

local GUNPOD_NULL = -1
local GUNPOD_OFF = 0
local GUNPOD_ARMED = 1

local gar8_elevation_adjust_deg=-3    -- adjust seeker 3deg down (might need to remove this if missile pylon is adjusted 3deg down)
local min_gar8_snd_pitch=0.9   -- seek tone pitch adjustment when "bad lock"
local max_gar8_snd_pitch=1.1   -- seek tone pitch adjustment when "good lock"
local gar8_snd_pitch_delta=(max_gar8_snd_pitch-min_gar8_snd_pitch)

------------------------------------------------
--------------  END CONSTANTS  -----------------
------------------------------------------------

-- countermeasure state
local chaff_count = 0
local flare_count = 0
local cm_bank1_show = 0
local cm_bank2_show = 0
local cm_banksel = 0
local cm_auto = false
local cm_enabled = false
local ECM_status = false
local flare_pos = 0
local chaff_pos = 0

-- weapon state
local _previous_master_arm = false
local selected_station = 1
local smoke_state = false
local smoke_equipped = false
local pickle_engaged = false
local gun_ready = false
local gun_firing = false
local trigger_engaged = false
local station_states = { STATION_OFF, STATION_OFF, STATION_OFF, STATION_OFF, STATION_OFF}
local function_selector = FUNC_OFF -- FUNC_OFF,FUNC_ROCKETS,FUNC_GM_UNARM,FUNC_BOMBS_GM_ARM
local bomb_arm_switch = BOMB_ARM_TAIL -- BOMB_ARM_TAIL, BOMB_ARM_OFF, BOMB_ARM_NOSETAIL
local emer_sel_switch = EMER_WING -- EMER_WING, EMER_1..5, EMER_ALL
local AWRS_mode = AWRS_mode_step_salvo
local AWRS_power = get_param_handle("AWRS_POWER")
local AWRS_quantity = 0
local AWRS_interval = 0.1
local AWRS_multiplier = 1
local weapon_interval = AWRS_multiplier*AWRS_interval
 -- fairly arbitrary value (seconds between rockets) (see also http://www.gettyimages.com/detail/video/news-footage/861-51 )

local gunpod_state = { GUNPOD_NULL, GUNPOD_OFF, GUNPOD_OFF, GUNPOD_OFF, GUNPOD_NULL }
local gunpod_charge_state = 0

local emer_bomb_release_countdown = 0

local smoke_actual_state = {}

local check_sidewinder_lock = false
local sidewinder_locked = false

local MASTER_TEST_BTN = get_param_handle("D_MASTER_TEST")
local GLARE_LABS_ANNUN = get_param_handle("D_GLARE_LABS")
local glare_labs_annun_state = false

local shrike_armed_param = get_param_handle("SHRIKE_ARMED")


------------------------------------------------
-----------  AIRCRAFT DEFINITION  --------------
------------------------------------------------

------------------------------------------------
---------  END AIRCRAFT DEFINITION  ------------
------------------------------------------------

WeaponSystem:listen_command(iCommandPlaneWingtipSmokeOnOff)
WeaponSystem:listen_command(Keys.JettisonWeapons)
WeaponSystem:listen_command(Keys.JettisonWeaponsUp)
WeaponSystem:listen_command(iCommandPlaneChangeWeapon)
WeaponSystem:listen_command(iCommandPlaneJettisonFuelTanks)
WeaponSystem:listen_command(Keys.JettisonFC3)
WeaponSystem:listen_command(Keys.PickleOn)
WeaponSystem:listen_command(Keys.PickleOff)
WeaponSystem:listen_command(Keys.PlaneFireOn)
WeaponSystem:listen_command(Keys.PlaneFireOff)
WeaponSystem:listen_command(device_commands.arm_emer_sel)
WeaponSystem:listen_command(device_commands.arm_gun)
WeaponSystem:listen_command(device_commands.arm_bomb)
WeaponSystem:listen_command(device_commands.arm_station1)
WeaponSystem:listen_command(device_commands.arm_station2)
WeaponSystem:listen_command(device_commands.arm_station3)
WeaponSystem:listen_command(device_commands.arm_station4)
WeaponSystem:listen_command(device_commands.arm_station5)
WeaponSystem:listen_command(device_commands.arm_func_selector)
WeaponSystem:listen_command(device_commands.emer_bomb_release)
WeaponSystem:listen_command(device_commands.gunpod_chargeclear)
WeaponSystem:listen_command(device_commands.gunpod_l)
WeaponSystem:listen_command(device_commands.gunpod_c)
WeaponSystem:listen_command(device_commands.gunpod_r)
WeaponSystem:listen_command(Keys.GunpodCharge)
WeaponSystem:listen_command(Keys.GunpodLeft)
WeaponSystem:listen_command(Keys.GunpodCenter)
WeaponSystem:listen_command(Keys.GunpodRight)
WeaponSystem:listen_command(Keys.Station1)
WeaponSystem:listen_command(Keys.Station2)
WeaponSystem:listen_command(Keys.Station3)
WeaponSystem:listen_command(Keys.Station4)
WeaponSystem:listen_command(Keys.Station5)
WeaponSystem:listen_command(Keys.ArmsFuncSelectorCCW)
WeaponSystem:listen_command(Keys.ArmsFuncSelectorCW)
WeaponSystem:listen_command(Keys.GunsReadyToggle)
WeaponSystem:listen_command(device_commands.shrike_sidewinder_volume)
WeaponSystem:listen_command(device_commands.shrike_selector)

WeaponSystem:listen_command(device_commands.AWRS_quantity)
WeaponSystem:listen_command(device_commands.AWRS_drop_interval)
WeaponSystem:listen_command(device_commands.AWRS_multiplier)
WeaponSystem:listen_command(device_commands.AWRS_stepripple)
WeaponSystem:listen_command(Keys.AWRSMultiplierToggle)
WeaponSystem:listen_command(Keys.AWRSQtySelIncrease)
WeaponSystem:listen_command(Keys.AWRSQtySelDecrease)
WeaponSystem:listen_command(Keys.AWRSModeSelCCW)
WeaponSystem:listen_command(Keys.AWRSModeSelCW)
WeaponSystem:listen_command(device_commands.AWRS_drop_interval_AXIS)

WeaponSystem:listen_command(Keys.ChangeCBU2AQuantity)
WeaponSystem:listen_command(Keys.ChangeCBU2BAQuantity)

local shrike_sidewinder_volume = get_param_handle("SHRIKE_SIDEWINDER_VOLUME")

local cbu1a_quantity = get_param_handle("CBU1A_QTY")
local cbu2a_quantity = get_param_handle("CBU2A_QTY")
local cbu2ba_quantity = get_param_handle("CBU2BA_QTY")

local cbu_bomblets_to_release = { 0, 0, 0, 0, 0 }
local cbu2a_quantity_array = {1,2,3,4,6,17}
local cbu2ba_quantity_array = {2,4,6}
local cbu2a_quantity_array_pos = 0
local cbu2ba_quantity_array_pos = 0

function post_initialize()
    startup_print("weapon_system: postinit start")

    sndhost = create_sound_host("COCKPIT_ARMS","HEADPHONES",0,0,0)
    labs_tone = sndhost:create_sound("Aircrafts/A-4E-C/bombtone") -- refers to sdef file, and sdef file content refers to sound file, see DCSWorld/Sounds/sdef/_example.sdef
    aim9seek = sndhost:create_sound("Aircrafts/Cockpits/AIM9")
    aim9lock = sndhost:create_sound("Aircrafts/Cockpits/SidewinderLow")
    --aim9lock2 = sndhost:create_sound("Aircrafts/Cockpits/SidewinderLowQuiet")
    --aim9lock3 = sndhost:create_sound("Aircrafts/Cockpits/SidewinderHigh")

	selected_station = 1
	ECM_status = false
	smoke_state = false
    smoke_equipped = false
	pickle_engaged = false -- if pickle is held down
	
	for i=1, num_stations, 1 do
		smoke_actual_state[i] = false
	end
    local dev = GetSelf()
    local birth = LockOn_Options.init_conditions.birth_place
    station_states = { STATION_OFF, STATION_OFF, STATION_OFF, STATION_OFF, STATION_OFF}
    -- XXX these performClickableAction(....,true) try to play sounds that aren't initialized yet, giving errors in DCS.log
    --   but initializing them first results in clicks when entering the cockpit... should change these (..,true) to false,
    --   and init the relevant variables here
    dev:performClickableAction(device_commands.arm_emer_sel,0.6,true) -- arg 700
    dev:performClickableAction(device_commands.arm_station1,0,true) -- arg 703
    dev:performClickableAction(device_commands.arm_station2,0,true) -- arg 704
    dev:performClickableAction(device_commands.arm_station3,0,true) -- arg 705
    dev:performClickableAction(device_commands.arm_station4,0,true) -- arg 706
    dev:performClickableAction(device_commands.arm_station5,0,true) -- arg 707
    dev:performClickableAction(device_commands.AWRS_quantity,0.0,true) -- arg 740, 0.0 = 0, 0.3=>8
    dev:performClickableAction(device_commands.AWRS_drop_interval,0.4,true) -- arg 742, 0.4=>100ms
    dev:performClickableAction(device_commands.AWRS_stepripple,0.2,true) -- arg 744, 2=>step single
    dev:performClickableAction(device_commands.AWRS_multiplier,0.0,true) -- arg 743, 0=>1x
    dev:performClickableAction(device_commands.arm_bomb,bomb_arm_switch-1,true)
    dev:performClickableAction(device_commands.shrike_sidewinder_volume, 0.5, true)
    
    -- update cbu dispenser release behaviour from mission planner settings
    cbu1a_quantity:set(2)
    cbu2a_quantity_array_pos = get_aircraft_property("CBU2ATPP")
    cbu2a_quantity:set(cbu2a_quantity_array[ cbu2a_quantity_array_pos + 1 ])
    cbu2ba_quantity_array_pos = get_aircraft_property("CBU2BATPP")
    cbu2ba_quantity:set(cbu2ba_quantity_array[ cbu2ba_quantity_array_pos + 1 ])

    if birth == "GROUND_HOT" or birth == "AIR_HOT" then --"GROUND_COLD","GROUND_HOT","AIR_HOT"
        -- set gun_ready when starting hot
        dev:performClickableAction(device_commands.arm_gun,0,true) -- arg 701
        gun_ready = false
        dev:performClickableAction(device_commands.AWRS_quantity,0.05,true) -- arg 740, quantity = 2 to power on the AWE-1
        AWRS_quantity = 2
    elseif birth == "GROUND_COLD" then
        dev:performClickableAction(device_commands.arm_gun,0,true) -- arg 701
        gun_ready = false
    end

    print("weapon_system: postinit end")
end

local time_ticker = 0 -- total time passed, in seconds
local weapon_release_ticker = 0 -- time passed since last release
local weapon_release_count = 0 -- number of weapons that have been released
local max_weapon_release_count = 0  -- number of weapons to release with each pulse
local last_weapon_released = false -- true when last weapon in sequence has been released
local ripple_sequence_position = 0 -- number of ripples that have been released
local once = false
local pylon_order = {1,5,2,4,3}
local next_pylon = 1 -- 1-5
local last_pylon_release = {0,0,0,0,0}  -- last time (see time_ticker) pylon was fired
local last_bomblet_release = {0,0,0,0,0}  -- last time (see time_ticker) bomblet was released from dispenser
local priority_pairs = { 5, 4, 3, 2, 1 }


function prepare_weapon_release()
    weapon_release_count = 0
    max_weapon_release_count = 0
    if AWRS_mode == AWRS_mode_ripple_salvo or AWRS_mode == AWRS_mode_step_salvo then
        -- check number of readied stations
        for i = 1, num_stations do
            if station_states[i] == STATION_READY then
                local station_info = WeaponSystem:get_station_info( i - 1 )
                if station_info.count > 0 then 
                    max_weapon_release_count = max_weapon_release_count + 1
                end
            end
        end
    elseif AWRS_mode == AWRS_mode_ripple_single or AWRS_mode == AWRS_mode_step_single then
        max_weapon_release_count = 1
    elseif AWRS_mode == AWRS_mode_ripple_pairs or AWRS_mode == AWRS_mode_step_pairs then
        max_weapon_release_count = 2
    end
end

local ir_missile_lock_param = get_param_handle("WS_IR_MISSILE_LOCK")
local ir_missile_az_param = get_param_handle("WS_IR_MISSILE_TARGET_AZIMUTH")
local ir_missile_el_param = get_param_handle("WS_IR_MISSILE_TARGET_ELEVATION")
local ir_missile_des_az_param = get_param_handle("WS_IR_MISSILE_SEEKER_DESIRED_AZIMUTH")
local ir_missile_des_el_param = get_param_handle("WS_IR_MISSILE_SEEKER_DESIRED_ELEVATION")

-- call function at the end of a ripple sequence
function ripple_sequence_end()
    debug_print("Ripple Sequence Ended")
    labs_tone:stop()
    pickle_engaged = false
    trigger_engaged = false
    ripple_sequence_position = 0
    glare_labs_annun_state = false -- turn off labs light
end

-- update visual state of the LABS annunciator
function update_labs_annunciator()
    if get_elec_primary_ac_ok() and (MASTER_TEST_BTN:get() == 1 or glare_labs_annun_state) then
        GLARE_LABS_ANNUN:set(1)
    else
        GLARE_LABS_ANNUN:set(0)
    end
end


function check_priority_pair_station(station_id) -- station id is 1 - 5
    -- get priority pair id number
    local pair_station_id = priority_pairs[station_id]
    -- check if priority pair station is readied
    -- return true if station is readied
    if station_states[pair_station_id] == STATION_READY then
        return true
    else
        return false
    end -- station_states
end -- check_priority_pair_station

function check_all_stations_for_pairs_mode()
    local equal_priority_found = false

    -- cycle through stations to find a readied pair of stations with equal priority
    for i = 1, 2 do
        if station_states[i] == STATION_READY then
            local equal_priority_station = priority_pairs[i]
            if station_states[ equal_priority_station ] == STATION_READY then
                -- equal priority pair found
                equal_priority_found = true
            end
        end
    end

    return equal_priority_found
end


function update()
	--ECM_status = WeaponSystem:get_ECM_status()
	
	
	--[[smoke_equipped = false
	for i=1, num_stations, 1 do
		local station = WeaponSystem:get_station_info(i-1)
		
		if station.count > 0 then
			if station.weapon.level3 == wsType_Smoke_Cont then	
				smoke_equipped = true	
				----Uncomment these lines when using EFM
				--if smoke_actual_state[i] ~= smoke_state then
				--	WeaponSystem:launch_station(i-1)
				--	smoke_actual_state[i] = smoke_state
				--end
			end
		end
	end	--]]
    
    
    time_ticker = time_ticker + update_rate
    local _master_arm = get_elec_mon_arms_dc_ok() -- check master arm status
    
    -- print_message_to_user("check sidewinder locked is "..tostring(check_sidewinder_lock))
    -- print_message_to_user("sidewinder locked is "..tostring(ir_missile_lock_param:get()))
    
    -- check if master arm changed from the last update
    if _previous_master_arm ~= _master_arm then
        check_sidewinder(_master_arm)
        check_shrike(_master_arm)
        _previous_master_arm = _master_arm
        debug_print("master arm changed")
    end

    local gear = get_aircraft_draw_argument_value(0) -- nose gear
    -- master arm is disable is gear is down.
    if (gear > 0) then
        _master_arm = false
    end

    -- AWRS is powered by non-zero quantity selector, powered by 28V DC
    if AWRS_quantity > 0 and get_elec_mon_dc_ok() then
        AWRS_power:set(1.0)
    else
        AWRS_power:set(0.0)
    end

    -- see NATOPS 8-3
    local released_weapon = false

    if _master_arm and (pickle_engaged or trigger_engaged) then
        
        local weap_release = false
        
        -- AWRS mode is in ripple single, ripple pairs, or ripple salvo
        if AWRS_mode >= AWRS_mode_ripple_single then
            weapon_release_ticker = weapon_release_ticker + update_rate -- increment timer
        end

        -- interval for next weapon release reached
        if weapon_release_ticker >= weapon_interval then
            weapon_release_ticker = 0
            prepare_weapon_release()
        end

        -- check that number of weapons released in current sequence has not exceeded total number of weapons to be released
        if weapon_release_count < max_weapon_release_count then
            weap_release = true
        end

        -- this was used to output the station info. only used for debugging.
        -- if not once then
        --     print_message_to_user("once")
        --     once=true
        --     for i=1, num_stations, 1 do
        --         local station = WeaponSystem:get_station_info(i-1)
        --         print_message_to_user("station "..tostring(i)..": count="..tostring(station.count)..",state="..tostring(station_states[i])..",l2="..tostring(station.weapon.level2)..",l3="..tostring(station.weapon.level3)..",l4="..tostring(station.weapon.level4))
        --     end
        -- end

        -- check if readied weapon stations are empty. check for number of readied stations which are cbu
        local readied_stations_empty = true


        for i = 1, num_stations do
            if station_states[i] == STATION_READY then
                local station_info = WeaponSystem:get_station_info(i-1)
                debug_print("station "..tostring(i)..": CLSID="..tostring(station_info.CLSID)..": count="..tostring(station_info.count)..",state="..tostring(station_states[i])..",l2="..tostring(station_info.weapon.level2)..",l3="..tostring(station_info.weapon.level3))
                if station_info.count > 0 then 
                    readied_stations_empty = false
                end
            end
        end

        if readied_stations_empty == true then
            debug_print('Stations Empty')
            ripple_sequence_end()
            -- break
        end

        for py = 1, num_stations, 1 do

            if weapon_release_count >= max_weapon_release_count and function_selector ~= FUNC_OFF then
                break
            end

            i = pylon_order[next_pylon]
            next_pylon = next_pylon+1

            if next_pylon > 5 then
                next_pylon = 1
            end

            
            local station = WeaponSystem:get_station_info(i-1)
            
            -- HIPEG/gunpod launcher
            if gunpod_state[i] == GUNPOD_ARMED and station.count > 0 and station.weapon.level2 == wsType_Shell and trigger_engaged and (gunpod_charge_state == 1 and get_elec_aft_mon_ac_ok()) then
                WeaponSystem:launch_station(i-1)
                last_pylon_release[i] = time_ticker
            end
            
            -- conditional checks for RIPPLE PAIRS and STEP PAIRS
            if ((AWRS_mode == AWRS_mode_ripple_pairs) or (AWRS_mode == AWRS_mode_step_pairs)) then
                -- centerline will not release weapons in PAIRS mode.
                if  i == 3 then
                    break

                -- check if priorty pair station is ready else break weapon loop
                -- If no weapons on pairs of equal priority stations, tone will not be heard, no weapons will be dropped.
                elseif check_priority_pair_station(i) == false then
                    break
                end
            end
            
            if station_states[i] == STATION_READY then
                if station.count > 0 and (
                (station.weapon.level2 == wsType_NURS and ((trigger_engaged and function_selector == FUNC_ROCKETS) or (pickle_engaged and function_selector == FUNC_GM_UNARM)) and weap_release) or -- launch unguided rockets
                ((station.weapon.level2 == wsType_Missile) and function_selector == FUNC_BOMBS_GM_ARM and weap_release) or -- launch missiles (pickle and fire trigger)
                ((station.weapon.level2 == wsType_Bomb) and pickle_engaged and function_selector == FUNC_BOMBS_GM_ARM and weap_release) -- launch bombs
                ) then
                    -- Bomb release logic
                    if (station.weapon.level2 == wsType_Bomb) then

                        if bomb_arm_switch == BOMB_ARM_OFF then
                            WeaponSystem:emergency_jettison(i-1)
                        else
                            -- TODO: differentiate between nose&tail and tail arming somehow
                            local can_fire = true
                            
                            -- release cluster bombs
                            -- need to account for SUU-7 and other cluser bombs
                            if (station.weapon.level3 == wsType_Bomb_Cluster) and 
                            (station.weapon.level4 ~= ROCKEYE) then
                                debug_print("Cluster munition found")
                                debug_print("Cluster CLSID"..station.CLSID)
                                -- get dispenser data
                                local dispenser = dispenser_data[station.CLSID]
                                debug_print(tostring(dispenser))
                                -- calculate number of bomblets in a tube to release. 
                                -- this does not factor into the number of tubes as that will be handled by the release code.
                                local bomblets_to_add = math.ceil( dispenser.bomblet_count / dispenser.number_of_tubes )
                                -- add bomblets to release array
                                cbu_bomblets_to_release[i] = bomblets_to_add + cbu_bomblets_to_release[i]
                                -- increment weapon release count after weapon pulse fired
                                released_weapon = true
                                weapon_release_count = weapon_release_count + 1
                                last_pylon_release[i] = time_ticker
                                debug_print("CBU - Weapon Release Count: "..weapon_release_count)
                                -- end sequence if ripple count completed

                                check_ripple_mode()

                            -- release regular bombs
                            elseif can_fire then
                                WeaponSystem:launch_station(i-1)
                                debug_print('Weapon Released')
                                released_weapon = true
                                weapon_release_count = weapon_release_count + 1
                                last_pylon_release[i] = time_ticker

                                check_ripple_mode()
                            end
                        end

                    -- Rockets launch logic
                    elseif (station.weapon.level2 == wsType_NURS) then
                        local can_fire=true

                        -- release rockets
                        if can_fire then
                            WeaponSystem:launch_station(i-1)
                            debug_print('Weapon Released')
                            released_weapon = true
                            weapon_release_count = weapon_release_count + 1
                            last_pylon_release[i] = time_ticker

                            check_ripple_mode()
                        end
                        
                    -- Missile launch logic
                    else
                        WeaponSystem:launch_station(i-1)
                        released_weapon = true
                        weapon_release_count = weapon_release_count + 1
                        last_pylon_release[i] = time_ticker
                    end
                end

                if (station.weapon.level2 == wsType_NURS and ((pickle_engaged and function_selector == FUNC_BOMBS_GM_ARM))) then -- Jettison unguided rockets
                    WeaponSystem:emergency_jettison(i-1)
                end
            end
        end
    end

    if emer_bomb_release_countdown > 0 then
        emer_bomb_release_countdown = emer_bomb_release_countdown - update_rate
        if emer_bomb_release_countdown<=0 then
            emer_bomb_release_countdown=0
            WeaponSystem:performClickableAction(device_commands.emer_bomb_release,0,false)
        end
    end
	
    if released_weapon then
        check_sidewinder(_master_arm) -- re-check sidewinder stores
        check_shrike(_master_arm)
    end

    if check_sidewinder_lock then
        if not sidewinder_locked then
            if ir_missile_lock_param:get() == 1 then
                -- acquired lock
                sidewinder_locked = true
                aim9seek:stop()
                aim9lock:play_continue()
            end
        else
            if ir_missile_lock_param:get() == 0 then
                -- lost lock
                sidewinder_locked = false
                aim9lock:stop()
                check_sidewinder(_master_arm) -- in case we lost lock due to having fired a missile
            else
                -- still locked
                local az=ir_missile_az_param:get()
                local el=ir_missile_el_param:get()
                az=math.deg(az)
                el=math.deg(el)-gar8_elevation_adjust_deg
                local ofs=math.sqrt(az*az+el*el)
                local snd_pitch
                local max_dist=1.0
                if ofs>max_dist then
                    snd_pitch = min_gar8_snd_pitch
                else
                    ofs=ofs/max_dist -- normalize
                    snd_pitch = (1-ofs)*(gar8_snd_pitch_delta)+min_gar8_snd_pitch
                end
                aim9lock:update(snd_pitch, nil, nil)
            end
            -- print_message_to_user("lock az:"..tostring(ir_missile_az_param:get())..",el:"..tostring(ir_missile_el_param:get()))
        end
    end

    release_cbu_bomblets()
    update_labs_annunciator()
end

function release_cbu_bomblets()
    for station_index, quantity in pairs(cbu_bomblets_to_release) do
        if ((time_ticker - last_bomblet_release[station_index]) > 0.0625) then  -- rate limit cluster bomb drop rate to 16 per second
            -- debug_print("release_cbu_bomblets()")
            -- check if bomblet quantity is greater than zero
            if quantity > 0 then
                debug_print("Station: "..station_index.." Quantity: "..quantity)
                -- check that station is not empty, if station is empty then clear quantity for station
                local station_info = WeaponSystem:get_station_info(station_index - 1)
                if station_info.count == 0 then
                    cbu_bomblets_to_release[station_index] = 0

                -- release weapon if station is not empty and quantity is greater than zero
                elseif station_info.count > 0 then
                    debug_print("Count remaining: "..quantity)
                    -- check number of tubes to release
                    local tubes_to_launch = check_number_of_tubes(station_index)
                    debug_print("Tubes to launch: "..tubes_to_launch)
                    for i = 1, tubes_to_launch do
                        WeaponSystem:launch_station(station_index - 1)
                        debug_print('Bomblet Released')
                    end
                    cbu_bomblets_to_release[station_index] = quantity - 1
                    last_bomblet_release[station_index] = time_ticker
                end
            end
        end 
    end
end

function check_number_of_tubes(station_id) -- station id should be 1 - 5
    local station = WeaponSystem:get_station_info(station_id - 1)
    local dispenser = dispenser_data[station.CLSID]
    debug_print(tostring(dispenser))
    -- calculate number of bomblets to release
    local tubes_per_pulse = 0
    if dispenser.variant == "CBU-1/A" then
        tubes_per_pulse = cbu1a_quantity:get()
    elseif dispenser.variant == "CBU-2/A" then
        tubes_per_pulse = cbu2a_quantity:get()
    elseif dispenser.variant == "CBU-2B/A" then
        tubes_per_pulse = cbu2ba_quantity:get()
    end
    return tubes_per_pulse
end

function check_ripple_mode()
    -- AWRS mode is in ripple single
    if AWRS_mode == AWRS_mode_ripple_single then
        ripple_sequence_position = ripple_sequence_position + 1 -- increment ripple sequence position
        
        -- stop sequence if end of sequence
        if ripple_sequence_position >= AWRS_quantity then
            debug_print('End of Ripple Single Sequence')
            ripple_sequence_end()
        end
    end

    -- AWRS mode is in ripple pairs or ripple salvo and both weapons have been released.
    if ((AWRS_mode == AWRS_mode_ripple_pairs) or (AWRS_mode == AWRS_mode_ripple_salvo)) and weapon_release_count == max_weapon_release_count then
        ripple_sequence_position = ripple_sequence_position + 1 -- increment ripple sequence position
        
        -- stop sequence if end of sequence
        if ripple_sequence_position >= AWRS_quantity then
            debug_print('End of Ripple Pairs Sequence')
            ripple_sequence_end()
        end
    end
end

function check_sidewinder(_master_arm)
    local sidewinder=false
    local non_sidewinder=false
    local num_selected=0
    local selected_station=0
    if _master_arm then
        for i=1, num_stations, 1 do
            local station = WeaponSystem:get_station_info(i-1)
            if station_states[i] == STATION_READY then
                num_selected=num_selected+1
                if (
                ((station.weapon.level2 == wsType_Missile) and (station.weapon.level3 == wsType_AA_Missile) and function_selector == FUNC_BOMBS_GM_ARM)
                ) then
                    if selected_station == 0 and station.count > 0 then
                        selected_station = i
                    end
                    sidewinder = true
                else
                    non_sidewinder = true
                end
            end
        end
    end
    if non_sidewinder then
        sidewinder = false
    end
    if selected_station == 0 then
        sidewinder = false
    end
    if sidewinder then
        WeaponSystem:select_station(selected_station-1)
        check_sidewinder_lock = true
        sidewinder_locked = false
        aim9lock:stop()
        aim9seek:play_continue()
        ir_missile_des_el_param:set(math.rad(gar8_elevation_adjust_deg))
    else
        check_sidewinder_lock = false
        aim9seek:stop()
        aim9lock:stop()
    end
end


function check_shrike(_master_arm)

    local non_shrike = false
    local shrike = false
    -- iterate over all readied station to check if all readied stations are shrikes
    if _master_arm then
        for i = 1, num_stations do
            local station = WeaponSystem:get_station_info( i - 1 )
            if station_states[i] == STATION_READY then
                if (
                ((station.weapon.level2 == wsType_Missile) and (station.weapon.level3 == wsType_AS_Missile) and function_selector == FUNC_BOMBS_GM_ARM)
                ) then
                    if station.count > 0 then
                        
                        shrike = true
                    end
                else
                    non_shrike = true
                end -- check weapon type
            end
        end
    end -- _master_arm

    if shrike then
        shrike_armed_param:set(1)
    else
        shrike_armed_param:set(0)
    end
    if non_shrike then
        shrike_armed_param:set(0)
    end
end

function SetCommand(command,value)
    local _master_arm = get_elec_mon_arms_dc_ok()
    local nosegear=get_aircraft_draw_argument_value(0) -- nose gear
    local geardown = ((nosegear~=0) and true or false)
    if (geardown) then
        _master_arm = false
    end
	if command == iCommandPlaneWingtipSmokeOnOff then
		if smoke_equipped == true then
			if smoke_state == false then
				smoke_state = true
			else
				smoke_state = false
			end		
		else
			debug_print("Smoke Not Equipped")
        end
        
	elseif command == Keys.JettisonWeapons then
        WeaponSystem:performClickableAction(device_commands.emer_bomb_release,1,true)

	elseif command == Keys.JettisonWeaponsUp then
        WeaponSystem:performClickableAction(device_commands.emer_bomb_release,0,true)

    elseif command == Keys.JettisonFC3 then
        -- priority order for jettison:
        -- 1: fuel tanks on pylons 2/4
        -- 2: fuel tank on pylon 3
        -- 3: weapons on pylons 1/5
        -- 4: weapons on pylons 2/4
        -- 5: weapons on pylon 3
        -- note, stations are ordered 0 to 4
        if get_elec_26V_ac_ok() then

            local oneJettison = false

            if not oneJettison then
                -- priority 1: fuel tanks on 2/4
                local stationA = WeaponSystem:get_station_info(1)
                local stationB = WeaponSystem:get_station_info(3)
                if stationA.count > 0 and stationA.weapon.level3 == wsType_FuelTank then
                    WeaponSystem:emergency_jettison(1)
                    oneJettison = true
                end
                if stationB.count > 0 and stationB.weapon.level3 == wsType_FuelTank then
                    WeaponSystem:emergency_jettison(3)
                    oneJettison = true
                end
            end

            if not oneJettison then
                -- priority 2: fuel tank on 3
                local stationA = WeaponSystem:get_station_info(2)
                if stationA.count > 0 and stationA.weapon.level3 == wsType_FuelTank then
                    WeaponSystem:emergency_jettison(2)
                    oneJettison = true
                end
            end

            if not oneJettison then
                -- priority 3: weapons on 1/5
                local stationA = WeaponSystem:get_station_info(0)
                local stationB = WeaponSystem:get_station_info(4)
                if stationA.count > 0 then
                    WeaponSystem:emergency_jettison(0)
                    oneJettison = true
                end
                if stationB.count > 0  then
                    WeaponSystem:emergency_jettison(4)
                    oneJettison = true
                end
            end

            if not oneJettison then
                -- priority 3: weapons on 2/4
                local stationA = WeaponSystem:get_station_info(1)
                local stationB = WeaponSystem:get_station_info(3)
                if stationA.count > 0 then
                    WeaponSystem:emergency_jettison_rack(1)
                    WeaponSystem:emergency_jettison(1)
                    oneJettison = true
                end
                if stationB.count > 0  then
                    WeaponSystem:emergency_jettison_rack(3)
                    WeaponSystem:emergency_jettison(3)
                    oneJettison = true
                end
            end

            if not oneJettison then
                -- priority 1: weapon on 3
                local stationA = WeaponSystem:get_station_info(2)
                if stationA.count > 0 then
                    WeaponSystem:emergency_jettison_rack(2)
                    WeaponSystem:emergency_jettison(2)
                    oneJettison = true
                end
            end

            check_sidewinder(_master_arm)  -- re-check sidewinder stores
            check_shrike(_master_arm)
        end

    elseif command == iCommandPlaneChangeWeapon then
		selected_station = selected_station + 1
		if selected_station > num_stations then
			selected_station = 1
        end
        
	elseif command == iCommandPlaneJettisonFuelTanks then
		for i=1, num_stations, 1 do
			local station = WeaponSystem:get_station_info(i-1)
			
			if station.count > 0 and station.weapon.level3 == wsType_FuelTank then
				WeaponSystem:emergency_jettison(i-1)
			end
        end
        
	elseif command == Keys.PickleOn then
        weapon_release_ticker = weapon_interval -- fire first batch immediately
        --prepare_weapon_release()
        if AWRS_mode >= AWRS_mode_ripple_single then -- AWRS is in ripple mode
            next_pylon=1
        end

        pickle_engaged = true
        
        -- if AWRS is setup for bombs or rockets
        if ( function_selector == FUNC_BOMBS_GM_ARM or function_selector == FUNC_GM_UNARM ) and _master_arm then

            -- PAIRS mode conditional logic checks
            if (AWRS_mode == AWRS_mode_ripple_pairs or AWRS_mode == AWRS_mode_step_pairs) then
                
                -- In PAIRS mode, an equal priority pair must exist for LABS tone and light to turn on
                if check_all_stations_for_pairs_mode() then
                    labs_tone:play_continue()
                    glare_labs_annun_state = true -- turn on labs light    
                end

            -- All other AWRS modes
            else
                labs_tone:play_continue()
                glare_labs_annun_state = true -- turn on labs light
            end
        end

    elseif command == Keys.PickleOff then
        pickle_engaged = false
        labs_tone:stop() -- TODO also stop after last auto-release interval bomb is dropped
        glare_labs_annun_state = false -- turn on labs light
        ripple_sequence_position = 0 -- reset ripple sequence

    elseif command == Keys.PlaneFireOn then
        if gun_ready and not geardown then
            if get_elec_aft_mon_ac_ok() then
                dispatch_action(nil,iCommandPlaneFire)
            end
            gun_firing = true
        end
        if AWRS_mode >= AWRS_mode_ripple_single then -- AWRS is in ripple mode
            next_pylon = 1
        end
        trigger_engaged = true
        weapon_release_ticker = weapon_interval -- fire first batch immediately

        -- if AWRS is setup for rockets
        if function_selector == FUNC_ROCKETS and _master_arm then

            -- PAIRS mode conditional logic checks
            if (AWRS_mode == AWRS_mode_ripple_pairs or AWRS_mode == AWRS_mode_step_pairs) then
                
                -- In PAIRS mode, an equal priority pair must exist for LABS tone and light to turn on
                if check_all_stations_for_pairs_mode() then
                    labs_tone:play_continue()
                    glare_labs_annun_state = true -- turn on labs light    
                end

            -- All other AWRS modes    
            else
                labs_tone:play_continue()
                glare_labs_annun_state = true -- turn on labs light
            end
        end

    elseif command == Keys.PlaneFireOff then
        dispatch_action(nil,iCommandPlaneFireOff)
        gun_firing = false
        trigger_engaged = false
        labs_tone:stop()
        glare_labs_annun_state = false -- turn on labs light
        ripple_sequence_position = 0 -- reset ripple sequence

    elseif command == device_commands.arm_gun then
        gun_ready=(value==1) and true or false
        debug_print("Guns: "..(gun_ready and "READY" or "SAFE"))
        if not gun_ready and gun_firing then
            dispatch_action(nil,iCommandPlaneFireOff)
        end

    elseif command == device_commands.arm_func_selector then
        local func=math.floor(math.ceil(value*100)/10)
        next_pylon=1
        if function_selector ~= func then
            function_selector = func
            check_sidewinder(_master_arm)
            check_shrike(_master_arm)
        end
        debug_print("Armament Select: "..selector_debug_text[function_selector+1])
        
    elseif command >= device_commands.arm_station1 and command <= device_commands.arm_station5 then
        station_states[command-device_commands.arm_station1+1] = value
        debug_print("Station "..(command-device_commands.arm_station1+1)..": "..station_debug_text[value+2])
        check_sidewinder(_master_arm)
        check_shrike(_master_arm)
        next_pylon=1

    elseif command >= Keys.Station1 and command <= Keys.Station5 then
        local stationOffset = command - Keys.Station1   -- value of 0 to 4
        if station_states[1+stationOffset] == 0 then
            WeaponSystem:performClickableAction((device_commands.arm_station1+stationOffset), 1, false) -- currently off, so enable pylon
        else
            WeaponSystem:performClickableAction((device_commands.arm_station1+stationOffset), 0, false) -- currently off, so enable pylon
        end
        next_pylon=1

    elseif command == device_commands.gunpod_chargeclear then
        gunpod_charge_state = value
        debug_print("charge/off/clear = "..value)

    elseif command == Keys.GunpodCharge then
        tmp = gunpod_charge_state + 1   -- cycle from off to charge to clear back to off
        if tmp > 1 then
            tmp = -1
        end
        WeaponSystem:performClickableAction(device_commands.gunpod_chargeclear, tmp, false)

    elseif command == device_commands.gunpod_l then
        local gunpod_ready=(value==1) and true or false
        debug_print("GunPod L: "..(gunpod_ready and "READY" or "SAFE"))
        gunpod_state[2] = value

    elseif command == device_commands.gunpod_c then
        local gunpod_ready=(value==1) and true or false
        debug_print("GunPod C: "..(gunpod_ready and "READY" or "SAFE"))
        gunpod_state[3] = value

    elseif command == device_commands.gunpod_r then
        local gunpod_ready=(value==1) and true or false
        debug_print("GunPod R: "..(gunpod_ready and "READY" or "SAFE"))
        gunpod_state[4] = value
    elseif command == Keys.GunpodLeft then
        WeaponSystem:performClickableAction(device_commands.gunpod_l, 1 - gunpod_state[2], false)
    elseif command == Keys.GunpodCenter then
        WeaponSystem:performClickableAction(device_commands.gunpod_c, 1 - gunpod_state[3], false)
    elseif command == Keys.GunpodRight then
        WeaponSystem:performClickableAction(device_commands.gunpod_r, 1 - gunpod_state[4], false)
    elseif command == Keys.GunsReadyToggle then
        gun_ready = not gun_ready
        WeaponSystem:performClickableAction(device_commands.arm_gun, gun_ready and 1 or 0, false)
    elseif command == Keys.ArmsFuncSelectorCCW or command == Keys.ArmsFuncSelectorCW then
        if command == Keys.ArmsFuncSelectorCCW then
            function_selector = function_selector - 1
        else
            function_selector = function_selector + 1
        end

        debug_print("Function Selector Value: "..function_selector)

        if function_selector < FUNC_OFF then
            function_selector = FUNC_OFF
        elseif function_selector > FUNC_BOMBS_GM_ARM then
            function_selector = FUNC_BOMBS_GM_ARM
        end

        check_sidewinder(_master_arm)
        check_shrike(_master_arm)
        WeaponSystem:performClickableAction(device_commands.arm_func_selector,function_selector/10,false)
        next_pylon=1
    elseif command == device_commands.arm_emer_sel then
        local func=math.floor(math.ceil(value*100)/10)
        debug_print("Arm emer select:"..emer_selector_debug_text[emer_sel_switch+1])
        if emer_sel_switch ~= func then
            emer_sel_switch = func
        end
    elseif command == device_commands.arm_bomb then
        bomb_arm_switch = value+1
        debug_print("Arm bomb:"..bomb_arm_debug_text[bomb_arm_switch+1])
    elseif command == device_commands.emer_bomb_release then
        if value==1 then
            if get_elec_26V_ac_ok() then
                debug_print("Emer bomb release:"..emer_selector_debug_text[emer_sel_switch+1])
                for i=1, num_stations, 1 do
                    local station = WeaponSystem:get_station_info(i-1)
                    if ((emer_sel_switch==EMER_ALL) or (emer_sel_switch==i) or (emer_sel_switch==EMER_WING and i~=3)) then
                        WeaponSystem:emergency_jettison_rack(i-1)
                    end
                end
                for i=1, num_stations, 1 do
                    local station = WeaponSystem:get_station_info(i-1)
                    if station.count > 0 and ((emer_sel_switch==EMER_ALL) or (emer_sel_switch==i) or (emer_sel_switch==EMER_WING and i~=3)) then
                        WeaponSystem:emergency_jettison(i-1)
                    end
                end
                check_sidewinder(_master_arm)  -- re-check sidewinder stores
                check_shrike(_master_arm)
            end
            emer_bomb_release_countdown = 0.25 -- seconds until spring pulls back lever
        end
    elseif command == device_commands.AWRS_quantity then
        debug_print("AWRS Quantity: "..value)
        local func=math.floor(math.ceil(value*100)/5) -- 0 to 11
        func = AWRS_quantity_array[func+1]
        debug_print("quantity:"..tostring(func))
        if AWRS_quantity ~= func then
            AWRS_quantity = func
        end

    elseif command == Keys.AWRSQtySelIncrease then
        local currentValue = get_cockpit_draw_argument_value(740)
        if currentValue < 0.53 then
            WeaponSystem:performClickableAction(device_commands.AWRS_quantity, currentValue + 0.05, false)
        end

    elseif command == Keys.AWRSQtySelDecrease then
        local currentValue = get_cockpit_draw_argument_value(740)
        if currentValue > 0.01 then
            WeaponSystem:performClickableAction(device_commands.AWRS_quantity, currentValue - 0.05, false)
        end

    elseif command == device_commands.AWRS_drop_interval then
        local interval=math.ceil(((200-20)/0.9)*value+20) -- interval is from 20 to 200
        AWRS_interval = (interval/1000.0)
        weapon_interval = AWRS_multiplier*AWRS_interval
        debug_print("interval:"..tostring(weapon_interval))
        
    elseif command == device_commands.AWRS_drop_interval_AXIS then
        local normalisedValue = ( ( value + 1 ) / 2 ) * 0.9 -- normalised {-1 to 1} to {0 - 0.9}
        WeaponSystem:performClickableAction(device_commands.AWRS_drop_interval, normalisedValue, false)

    elseif command == device_commands.AWRS_multiplier then
        if value==1 then
            AWRS_multiplier = 10
        else
            AWRS_multiplier = 1
        end
        weapon_interval = AWRS_multiplier*AWRS_interval

    elseif command == Keys.AWRSMultiplierToggle then
        if AWRS_multiplier == 10 then
            WeaponSystem:performClickableAction(device_commands.AWRS_multiplier, 0, false)
        else
            WeaponSystem:performClickableAction(device_commands.AWRS_multiplier, 1, false)
        end

    elseif command == device_commands.AWRS_stepripple then
        local func=math.floor(math.ceil(value*100)/10) --0 to 5
        debug_print("mode:"..value)
        debug_print("mode:"..AWRS_mode_debug_text[func+1])
        if AWRS_mode ~= func then
            AWRS_mode = func
        end

    elseif command == Keys.AWRSModeSelCCW then
        local currentValue = get_cockpit_draw_argument_value(744)
        if currentValue > 0 then
            WeaponSystem:performClickableAction(device_commands.AWRS_stepripple, currentValue - 0.1, false)
        end

    elseif command == Keys.AWRSModeSelCW then
        local currentValue = get_cockpit_draw_argument_value(744)
        if currentValue < 0.5 then
            WeaponSystem:performClickableAction(device_commands.AWRS_stepripple, currentValue + 0.1, false)
        end
        
    elseif command == Keys.ChangeCBU2AQuantity then
        -- check for weight on wheels and engine off
        if (sensor_data.getWOW_LeftMainLandingGear() > 0) and (sensor_data.getEngineLeftRPM() == 0) then
            -- increment position
            cbu2a_quantity_array_pos = (cbu2a_quantity_array_pos + 1) % table.getn(cbu2a_quantity_array)
            debug_print("CBU-2/A quantity changed to "..tostring(cbu2a_quantity_array_pos))
            -- get quantity and set param for kneeboard
            cbu2a_quantity:set(cbu2a_quantity_array[cbu2a_quantity_array_pos+1])
        end

    elseif command == Keys.ChangeCBU2BAQuantity then
        -- check for weight on wheels and engine off
        if (sensor_data.getWOW_LeftMainLandingGear() > 0) and (sensor_data.getEngineLeftRPM() == 0) then
            -- increment position
            cbu2ba_quantity_array_pos = (cbu2ba_quantity_array_pos + 1) % table.getn(cbu2ba_quantity_array)
            debug_print("CBU-2B/A quantity changed to "..tostring(cbu2ba_quantity_array_pos))
            -- get quantity
            cbu2ba_quantity:set(cbu2ba_quantity_array[cbu2ba_quantity_array_pos+1])
        end
    elseif command == device_commands.shrike_sidewinder_volume then
        debug_print("shrike_sidewinder_volume: "..value)
        shrike_sidewinder_volume:set(value)
        aim9seek:update(nil, LinearTodB(shrike_sidewinder_volume:get()), nil)
    elseif command == device_commands.shrike_selector then
        -- print_message_to_user(value)
    end
end

startup_print("weapon_system: load complete")

need_to_be_closed = false -- close lua state after initialization

--[[
Notes from NATOPS
In A-4E modified for AWE-1 or "limited" SHRIKE missile,
"full" SHRIKE, or SIDS (early A-4E aircraft reworked
per A-4 AFC376; late A-4E and all A-4F reworked per
A-4 AFC 386), the switch positions are changed.
(See figure 8-1 and refer to
NAVAIR 01-40AV-IT, A-4 Tactical Manual.) SHRIKE
configured aircraft have the SALVO position replaced
by a SHRIKE PAIRS position. In AWE-1 configured
aircraft, the SALVO position functions in the same
manner as the READY position; therefore, the SALVO
position serves no useful purpose and should not be
used

NOTE
• When the landing gear handle is in the DOWN
position, an armament safety switch interrupts the power supply circuit to the MASTER armament switch and the gun charging
Circuit.
• When the aircraft is on the ground, an armament safety circuit disabling switch may be
used to energize an alternate circuit for
checking the armament system. This circuit
is energized by momentarily closing the disabling switch located in the right-hand wheel
well. Raising the landing gear or moving
the MASTER armament switch to OFF will
restore the armament safety circuit to normal operation.


The bomb
release tone will come on when the bomb release
button is depressed and go off when the last bomb
selected is automatically released. If a step mode
of the AWE-1 is used, the tone will go off at bomb
button release.


Notes from NAVAIR 01-40AV-1TB
Alternate procedure for RKT firing is to place FUNC SEL SW
to GM UNARM and depress bomb button
--]]

--[[
GetDevice(devices.WEAPON_SYSTEM) metatable:
weapons meta["__index"] = {}
weapons meta["__index"]["get_station_info"] = function: 00000000CCCC5780
weapons meta["__index"]["listen_event"] = function: 00000000CCC8E000
weapons meta["__index"]["drop_flare"] = function: 000000003C14E208
weapons meta["__index"]["set_ECM_status"] = function: 00000000CCCC76E0
weapons meta["__index"]["performClickableAction"] = function: 00000000CCE957B0
weapons meta["__index"]["get_ECM_status"] = function: 00000000CCE37BC0
weapons meta["__index"]["launch_station"] = function: 00000000CCC36A30
weapons meta["__index"]["SetCommand"] = function: 00000000CCE52820
weapons meta["__index"]["get_chaff_count"] = function: 00000000CCBDD650
weapons meta["__index"]["emergency_jettison"] = function: 00000000CCC26810
weapons meta["__index"]["set_target_range"] = function: 000000003AB0FDD0
weapons meta["__index"]["set_target_span"] = function: 0000000027E4E970
weapons meta["__index"]["get_flare_count"] = function: 00000000CCCC57D0
weapons meta["__index"]["get_target_range"] = function: 00000000CCC26710
weapons meta["__index"]["get_target_span"] = function: 00000000CCCC7410
weapons meta["__index"]["SetDamage"] = function: 00000000CCC384B0
weapons meta["__index"]["drop_chaff"] = function: 00000000CCE37AA0
weapons meta["__index"]["select_station"] = function: 00000000CC5C26F0
weapons meta["__index"]["listen_command"] = function: 0000000038088060
weapons meta["__index"]["emergency_jettison_rack"] = function: 00000000720F15F0
--]]


--[[
AWRS Quantity Animation Positions
0   = 0
2   = 0.05
3   = 0.10
4   = 0.15
5   = 0.20
6   = 0.25
8   = 0.30
12  = 0.35
16  = 0.40
20  = 0.45
30  = 0.50
40  = 0.55

]]--