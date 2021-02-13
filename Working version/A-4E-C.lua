-- Simplified Aerodynamic Model by Helmo
-- mounting 3d model paths and texture paths

--mount_vfs_model_path    (current_mod_path.."/Shapes")
--mount_vfs_liveries_path (current_mod_path.."/Liveries")   -- mounted in entry.lua
--mount_vfs_texture_path  (current_mod_path.."/Textures")   -- mounted in entry.lua

local KG_TO_POUNDS  = 2.20462
local POUNDS_TO_KG  = 1/KG_TO_POUNDS
local FEET_TO_M     = 0.3048
A_4E_C =  {

    Name                 =   'A-4E-C',
    DisplayName            = _('Lancaster-MK1'),
    ViewSettings        = ViewSettings,

    -- enable A-4 for all countries.  It is CHEAP and easy to maintain
	Countries = {"Abkhazia","Australia","Austria","Belarus","Belgium","Brazil","Bulgaria","Canada","China","Croatia",
                 "Czech Republic","Denmark","Egypt","Finland","France","Georgia","Germany","Greece","Hungary",
                 "India","Insurgents","Iran","Iraq","Israel","Italy","Japan","Kazakhstan","The Netherlands","North Korea",
                 "Norway","Pakistan","Poland","Romania","Russia","Saudi Arabia","Serbia","Slovakia","South Korea",
                 "South Ossetia","Spain","Sweden","Switzerland","Syria","Turkey","UK","Ukraine","USA","USAF Aggressors"},

    HumanCockpit         = true,
    HumanCockpitPath    = current_mod_path..'/Cockpit/',

    Picture             = "A-4E-C.png",
    Rate                 = 40, -- RewardPoint in Multiplayer
    Shape                 = "A-4E",

    shape_table_data     =
    {
        {
            file       = 'A-4E';
            life       = 16; -- lifebar
            vis        = 3;  -- visibility gain.
            desrt    = 'Fighter-2-crush'; -- Name of destroyed object file name Alphajet-destr. This is a placeholder.
            fire       = {300, 3}; -- Fire on the ground after destoyed: 300sec 2m
            username = 'A-4E-C';
            index    =  WSTYPE_PLACEHOLDER;
            classname   = "lLandPlane";
			positioning = "BYNORMAL";
        },
        -- no need for this as we are using a built in destroyed model
        -- {
        --     name  = "Alphajet-destr";
        --     file  = "Alphajet-destr";
        --     fire  = {240, 2};  -- 240  2
        -- },

    },
    -------------------------
    -- add model draw args for network transmitting to this draw_args table (32 limit)
    net_animation ={
        0, -- front gear
        3, -- right gear
        5, -- left gear
        9, -- right flap
        10, -- left flap
        11, -- right aileron
        12, -- left aileron
        15, -- right elevator
        16, -- left elevator
        17, -- rudder

        2,  -- nose wheel steering
        21, -- SFM air brake
        13, -- right slat
        14, -- left slat
        25, -- tail hook
        120, -- right spoiler
        123, -- left spoiler
        190, -- left (red) navigation wing-tip light
        191, -- right (green) navigation wing-tip light
        192, -- tail (white) light

        198, -- anticollision (flashing red) top light
        199, -- anticollision (flashing red) bottom light
        208, -- taxi light (white) right main gear door
        402, -- huffer
        500, -- model air brake
        501, -- RAT
        499, -- wheel chocks

    },
	-------------------------
    mapclasskey = "P0091000024",
    attribute   = {wsType_Air, wsType_Airplane, wsType_Fighter, WSTYPE_PLACEHOLDER, "Multirole fighters", "Refuelable" },
    Categories  = {"{78EFB7A2-FD52-4b57-A6A6-3BF0E1D6555F}", "Interceptor",},
    -------------------------
    -- Operating Weight includes:  centerline rack, crew, engine oil, trapped fuel and oil, liquid oxygen, avionics pod, ECM, and misc equipment
    -- A-4E:  10,802 lbs operating weight
    --         + 314 lbs for 2x 20mm cannon (no ammo)
    --         + 140 lbs for 2x AERO 20A rack pylons on stations 2/4
    --         + 128 lbs for 2x AERO 20A rack pylons on stations 1/5
    --         +*398 lbs for 2x empty AERO-1D empty 300G fuel tanks
    --         +  97 lbs for armor plating
    --         +  32 lbs for wing spoilers
    --         +  76 lbs for J52-P-8A engine (versus J52-P-6A)
    --        ------
    -- TOTAL: 11,589 lbs with no ammo, no gas, and empty pylons

    mapclasskey = "P0091000024",
    attribute   = {wsType_Air, wsType_Airplane, wsType_Fighter, WSTYPE_PLACEHOLDER, "Multirole fighters", "Refuelable" },
    Categories  = {"{78EFB7A2-FD52-4b57-A6A6-3BF0E1D6555F}", "Interceptor",},
    -------------------------
    -- Operating Weight includes:  centerline rack, crew, engine oil, trapped fuel and oil, liquid oxygen, avionics pod, ECM, and misc equipment
    -- A-4E:  10,802 lbs operating weight
    --         + 314 lbs for 2x 20mm cannon (no ammo)
    --         + 140 lbs for 2x AERO 20A rack pylons on stations 2/4
    --         + 128 lbs for 2x AERO 20A rack pylons on stations 1/5
    --         +*398 lbs for 2x empty AERO-1D empty 300G fuel tanks
    --         +  97 lbs for armor plating
    --         +  32 lbs for wing spoilers
    --         +  76 lbs for J52-P-8A engine (versus J52-P-6A)
    --        ------
    -- TOTAL: 11,589 lbs with no ammo, no gas, and empty pylons

    M_empty                     =  36900*POUNDS_TO_KG,    -- see above calculation
    M_nominal                   =  50900*POUNDS_TO_KG,    -- combat weight per NATOPS calculated from M_empty + routine payload (14,000 lbs)
    M_max                       =  68000*POUNDS_TO_KG,    -- (Maximum Take Off Weight)
    M_fuel_max                  =  17976*POUNDS_TO_KG,     -- (Internal Fuel Only)             : 800G * ~6.8 lbs/gal for JP-5
    H_max                       =  21400*FEET_TO_M,       -- m  (Maximum Operational Ceiling) : Combat ceiling @ 14,500 lbs w/ 500 fpm climb max
    -------------------------
    length                      =  21.13,                 -- full lenght in m
    height                      =  6.25,                  -- height in m
    wing_area                   =  120.5,                 -- wing area in m2**
    wing_span                   =  31.09 ,                 -- wing span in m
    wing_tip_pos                =  {-15.478, 3.66, 1.275}, -- wingtip coords for visual effects -- x 1.275 y -15.478 z 3.66
    wing_type                   =  0,                     -- FIXED_WING = 0 / VARIABLE_GEOMETRY = 1 / FOLDED_WING = 2 / ARIABLE_GEOMETRY_FOLDED = 3
    flaps_maneuver              =  0.5,                   -- Max flaps in take-off and maneuver (0.5 = 1st stage; 1.0 = 2nd stage) (for AI)
    has_speedbrake              =  false,

    RCS                         =  3.4,                   -- Radar Cross Section m2.  Proportionally scaled RCS of F-16's 4.0.
    IR_emission_coeff           =  0.5,                   -- Normal engine -- IR_emission_coeff = 1 is Su-27 without afterburner. It is reference.
    IR_emission_coeff_ab        =  0.5,                   -- With afterburner

    stores_number               =  5,                     -- Amount of pylons.

    CAS_min                     =  20,                  -- minimal indicated airspeed  m/s?  (50 knots per NATOPS)
    V_opt                       =  200,                   -- Cruise speed (for AI)
    V_take_off                  =  82.3,                  -- Take off speed in m/s (for AI - 150kts)
    V_land                      =  64.3,                  -- Land speed in m/s (for AI) (110 kn)
    V_max_sea_level             =  126.111,                -- Max speed at sea level in m/s (for AI)
    V_max_h                     =  126.111,                 -- Max speed at max altitude in m/s (for AI)
    Vy_max                      =  5.3,                 -- Max climb speed in m/s (for AI - 200 kts)
    Mach_max                    =  0.36,                  -- Max speed in Mach (for AI)
    Ny_min                      =  -3.0,                  -- Min G (for AI)
    Ny_max                      =  4.0,                   -- Max G (for AI)
    Ny_max_e                    =  4.0,                   -- Max G (for AI)
    -- AOA_take_off             =  0.27,                  -- AoA in take off radians (for AI) 16 degrees
    bank_angle_max              =  60,                    -- Max bank angle (for AI)
    range                       =  3700,                  -- Max range in km (for AI)

    thrust_sum_max              =  9600*POUNDS_TO_KG,     -- thrust in kg (J52 P8A: 9300 lb)**
    has_afteburner              =  false,
    has_differential_stabilizer =  false,
    thrust_sum_ab               =  9600*POUNDS_TO_KG,     -- thrust in kg (kN)**
    average_fuel_consumption    =  0.86,                  -- 0.86 TSFC
    is_tanker                   =  false,
    tanker_type                 =  2,                     -- Tanker type if the plane is tanker

    -----------------------------------------------------------------------
    ----------------- SUSPENSION CODE BEGINS
    -----------------------------------------------------------------------
    nose_gear_pos                            = {-9.271, -1.33, 0.1}, -- {2.72, -2.37, 0},    --      2.72,       -2.28,    0 -- {0.804, 0, -9.271}
    main_gear_pos                            = {-3.79, -1.88, 3.431}, -- {-0.79, -2.42, 1.18},    --  0.79,   -2.35,    1.18 -- {-0.913, -3.662, 3.431}
    tand_gear_max                            = 0.4,   -- // tangent on maximum yaw angle of front wheel

    nose_gear_amortizer_direct_stroke        = 0,    -- 1.878 - 1.878, -- down from nose_gear_pos !!!
    nose_gear_amortizer_reversal_stroke      = 0,   -- 1.348 - 1.878, -- up
    main_gear_amortizer_direct_stroke        = 0,     -- 1.592 - 1.592, -- down from main_gear_pos !!!
    main_gear_amortizer_reversal_stroke      = 0,   -- 1.192 - 1.592, -- up

    nose_gear_amortizer_normal_weight_stroke = 0,   -- 0.144
    main_gear_amortizer_normal_weight_stroke = 0,   --

    nose_gear_wheel_diameter                 = 0.441,   -- 0.441, --*
    main_gear_wheel_diameter                 = 0.609,   -- 0.609, --*
    brakeshute_name                          = 0,       -- Landing - brake chute visual shape after separation


    -----------------------------------------------------------------------
    ----------------- SUSPENSION CODE ENDS
    -----------------------------------------------------------------------

    engines_count    = 4,
    engines_nozzles =
    {
        [1] =
        {
            pos =     {4.296,    -8.297,    2.713}, -- nozzle coords
            elevation    =    0.0, -- AFB cone elevation
            smokiness_level     =     0.8,
        }, -- end of [1]
        [2] =
        {
            pos =     {4.807,    -4.276,    2.416}, -- nozzle coords
            elevation    =    0.0, -- AFB cone elevation
            smokiness_level     =     0.8,
        }, -- end of [2]
        [3] =
        {
            pos =     {4.806,    3.045,    2.416}, -- nozzle coords
            elevation    =    0.0, -- AFB cone elevation
            smokiness_level     =     0.8,
        }, -- end of [3]
        [4] =
        {
            pos =     {4.294,    7.066,    2.173}, -- nozzle coords
            elevation    =    0.0, -- AFB cone elevation
            smokiness_level     =     0.8,
        }, -- end of [4]
    }, -- end of engines_nozzles

    crew_size    = 1,
    crew_members =
    {
        [1] =
        {
 			g_suit 			   =  5 -- I'm assuming there are different levels of suits which black you out at different G's. We should try and experiment with different ones.
        }, -- end of [1]
    }, -- end of crew_members
---------------------------------------------------------------------------------------------------------------------------------------------
    fires_pos =
    {
        [1] =     {-0.232,    1.262,    0}, 	-- Fuselage
        [2] =     {-0.2,    -0.5,    0.84}, 		-- wing (inner?) right, WING_R_IN
        [3] =     {-0.75,    -0.5,    -0.8}, 		-- wing (inner?) left, WING_L_IN
        [4] =     {-0.32,    0.265,    1.774},  -- Wing center Right? {-0.82,    0.265,    2.774},
        [5] =     {-0.32,    0.265,    -1.774}, -- Wing center Left?  {-0.82,    0.265,    -2.774},
        [6] =     {-1.0,    -0.5,    4.0},  -- Wing outer Right? {-0.82,    0.255,    4.274}, probably WING_R_OUT
        [7] =     {-1.0,    -0.5,    -4.0}, -- Wing outer Left?  {-0.82,    0.255,    -4.274}, probably WING_L_OUT
        [9] =     {-5.5,    0.2,    0},    		-- left engine
        [10] =     {-7.728,    0.039,    0.5},  -- Right Engine? {0.304,    -0.748,    0.442},
        [11] =     {-7.728,    0.039,    -0.5}, -- ?
    }, -- end of fires_pos
---------------------------------------------------------------------------------------------------------------------------------------------
--sensors
    HumanRadio = {
        frequency = 254.0, -- Maykop (Caucasus) or Nellis (NTTR)
        editable = true,
        minFrequency = 225.000,
        maxFrequency = 399.900,
        modulation = MODULATION_AM
    },

    panelRadio = {
        [1] = {
            name = _("AN/ARC-51A"),
            range = {
                {min = 225.0, max = 399.9}
            },
            channels = {  -- matches L-39C except for channel 8, which was changed to a Georgian airport and #20 which is NTTR only (for now).  This radio goes 1-20 not 0-19.
                [1] = { name = _("Channel 1"),		default = 264.0, modulation = _("AM"), connect = true}, -- mineralnye-vody (URMM) : 264.0
                [2] = { name = _("Channel 2"),		default = 265.0, modulation = _("AM")},	-- nalchik (URMN) : 265.0
                [3] = { name = _("Channel 3"),		default = 256.0, modulation = _("AM")},	-- sochi-adler (URSS) : 256.0
                [4] = { name = _("Channel 4"),		default = 254.0, modulation = _("AM")},	-- maykop-khanskaya (URKH), nellis (KLSV) : 254.0
                [5] = { name = _("Channel 5"),		default = 250.0, modulation = _("AM")},	-- anapa (URKA) : 250.0
                [6] = { name = _("Channel 6"),		default = 270.0, modulation = _("AM")},	-- beslan (URMO) : 270.0
                [7] = { name = _("Channel 7"),		default = 257.0, modulation = _("AM")},	-- krasnodar-pashkovsky (URKK) : 257.0
                [8] = { name = _("Channel 8"),		default = 258.0, modulation = _("AM")},	-- sukhumi-babushara (UGSS) : 255.0
                [9] = { name = _("Channel 9"),		default = 262.0, modulation = _("AM")},	-- kobuleti (UG5X) : 262.0
                [10] = { name = _("Channel 10"),	default = 259.0, modulation = _("AM")},	-- gudauta (UG23) : 259.0
                [11] = { name = _("Channel 11"),	default = 268.0, modulation = _("AM")},	-- tbilisi-soganlug (UG24) : 268.0
                [12] = { name = _("Channel 12"),	default = 269.0, modulation = _("AM")},	-- tbilisi-vaziani (UG27) : 269.0
                [13] = { name = _("Channel 13"),	default = 260.0, modulation = _("AM")},	-- batumi (UGSB) : 260.0
                [14] = { name = _("Channel 14"),	default = 263.0, modulation = _("AM")},	-- kutaisi-kopitnari (UGKO) : 263.0
                [15] = { name = _("Channel 15"),	default = 261.0, modulation = _("AM")},	-- senaki-kolkhi (UGKS) :  261.0
                [16] = { name = _("Channel 16"),	default = 267.0, modulation = _("AM")},	-- tbilisi-lochini (UGTB) : 267.0
                [17] = { name = _("Channel 17"),	default = 251.0, modulation = _("AM")},	-- krasnodar-center (URKI), creech (KINS) : 251.0
                [18] = { name = _("Channel 18"),	default = 253.0, modulation = _("AM")},	-- krymsk (URKW), mccarran (KLAS) : 253.0
                [19] = { name = _("Channel 19"),	default = 266.0, modulation = _("AM")},	-- mozdok (XRMF) : 266.0
                [20] = { name = _("Channel 20"),	default = 252.0, modulation = _("AM")}, -- N/A, groom lake/homey (KXTA) : 252.0
            }
        },
    },

    WorldID =  WSTYPE_PLACEHOLDER, -- A_4E,

    Failures = {
        { id = 'asc',         label = _('ASC'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'autopilot', label = _('AUTOPILOT'), enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'hydro',      label = _('HYDRO'),     enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'l_engine',  label = _('L-ENGINE'),     enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'r_engine',  label = _('R-ENGINE'),     enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'eos',          label = _('EOS'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'helmet',      label = _('HELMET'),     enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        --{ id = 'mlws',      label = _('MLWS'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'rws',          label = _('RWS'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'ecm',       label = _('ECM'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'hud',          label = _('HUD'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
        { id = 'mfd',          label = _('MFD'),         enable = false, hh = 0, mm = 0, mmint = 1, prob = 100 },
    },
---------------------------------------------------------------------------------------------------------------------------------------------
    Tasks = {       -- defined in db_units_planes.lua, nothing is #15
        aircraft_task(CAP),                 -- Task #11 in ME
        aircraft_task(CAS),                 -- Task #31
        aircraft_task(SEAD),                -- Task #29
        --aircraft_task(Reconnaissance),
        aircraft_task(GroundAttack),        -- Task #32
        aircraft_task(AFAC),                -- Task #16
        --aircraft_task(RunwayAttack),
        --aircraft_task(AntishipStrike),
        aircraft_task(Refueling),           -- Task #13
    },
    DefaultTask = aircraft_task(CAS),
---------------------------------------------------------------------------------------------------------------------------------------------
    SFM_Data = {
        aerodynamics = -- Cx = Cx_0 + Cy^2*B2 +Cy^4*B4
        {
            Cy0         = 0.0,      -- zero AoA lift coefficient
            Mzalfa      = 6.2,      -- coefficients for pitch agility
            Mzalfadt    = 0.7,      -- coefficients for pitch agility
            kjx         = 4.5,      -- Inertia parametre X - Dimension (clean) airframe drag coefficient at X (Top) Simply the wing area in square meters (as that is a major factor in drag calculations) - smaller = massive inertia
            kjz         = 0.00125,  -- Inertia parametre Z - Dimension (clean) airframe drag coefficient at Z (Front) Simply the wing area in square meters (as that is a major factor in drag calculations)
            Czbe        = -0.016,   -- coefficient, along Z axis (perpendicular), affects yaw, negative value means force orientation in FC coordinate system
            cx_gear     = 0.07,     -- coefficient, drag, gear ??
            cx_flap     = 0.08,     -- coefficient, drag, full flaps -- 0.006 for first 10 degrees
            cy_flap     = 0.21,     -- coefficient, normal force, lift, flaps -- 0.095 for first 10 degrees

            table_data = {
            --       M       Cx0        Cya      B      B4          Omxmax      Aldop       Cymax
                    {0.00,   0.0220,    0.087,   0.149,  0.00,         0.5,    	22.91,      1.40, },
                    {0.15,   0.0220,    0.087,   0.149,  0.00,         1.0,     22.91,      1.40, },   -- 20 degree slat extension at sea level
                    {0.30,   0.0160,    0.061,   0.149,  0.00,         4.5,     22.91,      1.30, },   -- 0 degree slat extension at sea level
                    {0.40,   0.0160,    0.060,   0.149,  0.00,         6.5,     22.91,      1.22, },
                    {0.48,   0.0160,    0.060,   0.149,  0.00,         7.5,     22.91,      1.05, },
                    {0.50,   0.0160,    0.060,   0.149,  0.00,         8.0,     22.34,      1.00, },
                    {0.55,   0.0160,    0.060,   0.149,  0.00,         8.0,     20.91,      0.96, },
                    {0.60,   0.0160,    0.060,   0.149,  0.00,         8.1,     18.33,      0.91, },
                    {0.65,   0.0175,    0.061,   0.149,  0.00,         8.2,     22.63,      0.89, },
                }


            -- M - Mach number
            -- Cx0 - Coefficient, drag, profile, of the airplane
            -- Cya - Normal force coefficient of the wing and body of the aircraft in the normal direction to that of flight. Inversely proportional to the available G-loading at any Mach value. (lower the Cya value, higher G available) per 1 degree AOA
            -- B2 - Polar 2nd power coeff
            -- B4 - Polar 4th power coeff
            -- Omxmax - roll rate, rad/s
            -- Aldop - Alfadop Max AOA at current M - departure threshold
            -- Cymax - Coefficient, lift, maximum possible (ignores other calculations if current Cy > Cymax)
        }, -- end of aerodynamics
        engine =
        {
            Nmg    =    20.0,    -- RPM at idle
            MinRUD    =    0,    -- Min state of the throttle
            MaxRUD    =    1,    -- Max state of the throttle
            MaksRUD    =    0.999,    -- Military power state of the throttle
            typeng    =    2,
            --[[
                E_TURBOJET = 0
                E_TURBOJET_AB = 1
                E_PISTON = 2
                E_TURBOPROP = 3
                E_TURBOFAN    = 4
                E_TURBOSHAFT = 5
            --]]
            hMaxEng    =    10,    -- Max altitude for safe engine operation in km
            dcx_eng    =    0.0200,    -- Engine drag coeficient
            -- Affects drag of engine when shutdown
            -- cemax/cefor affect sponginess of elevator/inertia at slow speed
            -- affects available g load apparently
            cemax    =    0.037,    -- not used for fuel calulation , only for AI routines to check flight time ( fuel calculation algorithm is built in )
            cefor    =    0.037,    -- not used for fuel calulation , only for AI routines to check flight time ( fuel calculation algorithm is built in )
            dpdh_m    =    6000,    --  altitude coefficient for max thrust
            dpdh_f    =    14000.0,    --  altitude coefficient for AB thrust

            table_data =
            {
            --   M          Pmax
                {0.0,       0.0,0.0}, -- dummy table, required for 2.0+ engine module load
                {2.0,       0.0,0.0},
            }, -- end of table_data
            -- M - Mach number
            -- Pmax - Engine thrust at military power - kilo Newton
            -- Pfor - Engine thrust at AFB
			extended = -- added new abilities for engine performance setup. thrust data now can be specified as 2d table by Mach number and altitude. thrust specific fuel consumption tuning added as well
			{
                -- matching TSFC to mil thrust consumption at altitude at mach per NATOPS navy trials
				TSFC_max =  -- thrust specific fuel consumption by altitude and Mach number for RPM  100%, 2d table
				{
					M 		 = {0, 0.5, 0.8, 0.9, 1.0},
					H		 = {0, 3048, 6096, 9144, 12192},
					TSFC	 = {-- M 0      0.5     0.8       0.9     1.0
								{   0.86,  0.92,  1.012,    1.012,  1.003},--H = 0       -- SL
								{   0.86,  0.99,  1.025,    1.025,  1.016},--H = 3048    -- 10000'
								{   0.86,  0.96,  1.008,    1.008,  0.999},--H = 6096    -- 20000'
								{   0.86,  0.95,  0.984,    0.984,  0.974},--H = 9144    -- 30000'
                                {   0.86,  0.94,  0.976,    0.976,  0.967},--H = 12192   -- 40000'
					}
				},

                -- per ADA057325:
                -- SFC = 0.836 (0% bleed) to 1.415 (15.44% bleed) at low throttle
                -- SFC = 0.777 (0% bleed) to 0.964 (16.84% bleed) at MIL throttle
                -- modeling as 5% bleed, so low power loses 22% efficiency:
				TSFC_throttle_responce =  -- correction to TSFC for different engine RPM, 1d table
				{
					RPM = {0, 50, 55, 75, 100},
					K   = {1, 1.05, 1.22, 1.05, 1.00},   -- Static SL TSFC now part of table above
                    --K   = {1, 1, 1, 1, 1},
				},


                --[[
                thrust_max = -- thrust interpolation table by altitude and mach number, 2d table
				 {
					 M 		 = {0,.1,0.3,0.5,0.7,0.8,0.9,1.1},
					 H		 = {0,250,4572,7620,10668,13716,16764,19812},
					 thrust	 = {-- M   0         0.1       0.3       0.5       0.7      0.8     0.9       1.1
								 {   61370,  59460,  57023, 36653,  36996,  37112,  36813,  34073 },--H = 0 (sea level)
								 {   41370,  39460,  37023, 36653,  36996,  37112,  36813,  34073 },--H = 250 (sea level)
								 {   27254,  25799,  24203, 24599,  26227,  27254,  28353,  29785 },--H = 4572 (15kft)
								 {   20818,  19203,  17548, 17473,  18638,  19608,  20684,  22873 },--H = 7620 (25kft)
								 {   10876,  11076,  11556, 12193,  13024,  13674,  14434,  16098 },--H = 10668 (35kft)
								 {   6025,   6379,   6837,  7433,   8194,   8603,   9101,   10075 },--H = 13716 (45kft)
								 {   3336,   3554,   3990,  4484,   5000,   5307,   5596,   6232  },--H = 16764 (55kft)
								 {   1904,   2042,   2433,  2798,   3212,   3483,   3639,   4097  },--H = 19812 (65kft)

					 },
				 },]]--


                thrust_max = -- thrust interpolation table by altitude and mach number, 2d table.  Modified for carrier takeoffs at/around 71 foot deck height
                {
                    M       =   {0, 0.1, 0.225, 0.23, 0.3, 0.5, 0.7, 0.8, 0.9, 1.1},
                    H       =   {0, 19, 20, 23, 24, 250, 4572, 7620, 10668, 13716, 16764, 19812},
                    thrust  =  {-- M    0     0.1    0.225   0.23,   0.3    0.5     0.7     0.8     0.9     1.1
                                {   41370,  39460,  38060,  38056,  37023,  36653,  36996,  37112,  36813,  34073 },--H = 0 (sea level)
                                {   41370,  39460,  38060,  38056,  37023,  36653,  36996,  37112,  36813,  34073 },--H = 19 (~62.3 feet)
								{   41370,  39460,  38060,  38056,  37023,  36653,  36996,  37112,  36813,  34073 },--H = 20 (~66.6 feet)
							    {   41370,  39460,  38060,  38056,  37023,  36653,  36996,  37112,  36813,  34073 },--H = 23 (~75.5 feet)
                                {   41370,  39460,  38060,  38056,  37023,  36653,  36996,  37112,  36813,  34073 },--H = 24 (~78.7 feet)
                                {   41370,  39460,  38060,  38056,  37023,  36653,  36996,  37112,  36813,  34073 },--H = 250 (820 feet)
                                {   27254,  25799,  24765,  24761,  24203,  24599,  26227,  27254,  28353,  29785 },--H = 4572 (15kft)
                               },
                },


				--rpm_acceleration_time_factor = -- time factor for engine governor  ie RPM += (desired_RPM - RPM ) * t(RPM) * dt
				--{
				--	RPM  = {0, 50, 100},
				--	t    = {0.3,0.3,0.3}
				--},
				--rpm_deceleration_time_factor = -- time factor for engine governor
				--{
				--	RPM  = {0, 50, 100},
				--	t    = {0.3,0.3,0.3}
				--},
				rpm_throttle_responce = -- required RPM according to throttle position
				{
					throttle = {0   ,0.85  ,1.0},
					RPM      = {20  ,97.2  ,100},
				},
				thrust_rpm_responce = -- thrust = K(RPM) * thrust_max(M,H)
				{
					RPM = {0  ,20   ,35   ,48   ,55   ,65   ,75   ,80   ,90.5   ,98.8   ,100},
					K   = {0  ,0.00 ,0.051  ,0.059  ,0.101  ,0.176  ,0.248  ,0.349  ,0.670  ,0.963  ,1},
				},
			},
        }, -- end of engine
    },
---------------------------------------------------------------------------------------------------------------------------------------------
    --damage , index meaning see in  Scripts\Aircrafts\_Common\Damage.lua
    -- Damage = {
    --             [0] = {critical_damage = 5, args = {82}},  							-- 0 - nose center
    --             [3] = {critical_damage = 10, args = {65}}, 							-- 3 - cockpit
    --             [8] = {critical_damage = 10}, 			  							-- 8 - front gear
    --             [11] = {critical_damage = 3}, 			  							-- 11 - engine in left
    --             [12] = {critical_damage = 3}, 			  							-- 12 - engine in right
    --             [15] = {critical_damage = 10},			   							-- 15 - gear left
    --             [16] = {critical_damage = 10}, 										-- 16 - gear right
    --             [17] = {critical_damage = 3}, 										-- 17 - motogondola left (left engine out, left ewu)
    --             [18] = {critical_damage = 3}, 										-- 18 - motogondola right (right engine out, right ewu)
    --             [25] = {critical_damage = 5, args = {53}}, 							-- 25 - eleron left
    --             [26] = {critical_damage = 5, args = {54}}, 							-- 26 - eleron right
    --             [35] = {critical_damage = 10, args = {67}, deps_cells = {25, 37}},  -- 35 - wing in left
    --             [36] = {critical_damage = 10, args = {68}, deps_cells = {26, 38}},  -- 36 - wing in right
    --             [37] = {critical_damage = 4, args = {55}}, 						    -- 37 - flap in left
    --             [38] = {critical_damage = 4, args = {56}}, 						    -- 38 - flap in right
    --             [43] = {critical_damage = 4, args = {61}, deps_cells = {53}}, 		-- 43 - fin bottom left
    --             [44] = {critical_damage = 4, args = {62}, deps_cells = {54}}, 		-- 44 - fin bottom right
    --             [47] = {critical_damage = 5, args = {63}, deps_cells = {51}}, 		-- 47 - stabilizer in left
    --             [48] = {critical_damage = 5, args = {64}, deps_cells = {52}}, 		-- 48 - stabilizer in right
    --             [51] = {critical_damage = 2, args = {59}}, 							-- 51 - elevator in left
    --             [52] = {critical_damage = 2, args = {60}}, 							-- 52 - elevator in right
    --             [53] = {critical_damage = 2, args = {57}}, 							-- 53 - rudder left
    --             [54] = {critical_damage = 2, args = {58}}, 							-- 54 - rudder right
    --             [55] = {critical_damage = 5, args = {81}}, 							-- 55 - tail
    --             [83]    = {critical_damage = 3, args = {134}}, 						-- nose wheel
    --             [84]    = {critical_damage = 3, args = {136}}, 						-- left wheel
    --             [85]    = {critical_damage = 3, args = {135}}, 						-- right wheel
    -- },

    Damage = verbose_to_dmg_properties(
	{
        ["NOSE_CENTER"]             = {critical_damage = 3}, -- 0
        ["NOSE_LEFT_SIDE"]          = {critical_damage = 3}, -- 1
        ["NOSE_RIGHT_SIDE"]         = {critical_damage = 3}, -- 2
        ["NOSE_BOTTOM"]             = {critical_damage = 3}, -- 59

        ["COCKPIT"]                 = {critical_damage = 1}, -- 3
        ["CABIN_LEFT_SIDE"]         = {critical_damage = 3}, -- 4
        ["CABIN_RIGHT_SIDE"]        = {critical_damage = 3}, -- 5
        ["CABIN_BOTTOM"]            = {critical_damage = 3}, -- 6

        ["GUN"]                     = {critical_damage = 2}, -- 7 refuelling probe?
        ["PITOT"]                   = {critical_damage = 1}, -- 60

        ["WHEEL_F"]                 = {critical_damage = 3}, -- 83

        ["FUSELAGE_LEFT_SIDE"]      = {critical_damage = 3, args = {600}}, -- 9
        ["FUSELAGE_RIGHT_SIDE"]     = {critical_damage = 3}, --10
        ["FUSELAGE_TOP"]            = {critical_damage = 3}, -- 99 avionics hump?
        ["FUSELAGE_BOTTOM"]         = {critical_damage = 4}, --82
        ["ENGINE"]                  = {critical_damage = 2},-- 11

        -- ["MTG_L"]                   = {critical_damage = 3}, -- 17 left engine nacelle
        -- ["MTG_R"]                   = {critical_damage = 3}, -- 18 right engine nacelle

        ["AIR_BRAKE_L"]             = {critical_damage = 1}, -- 19
        ["AIR_BRAKE_R"]             = {critical_damage = 1}, -- 20

        ["WING_L_IN"]               = {critical_damage = 5, deps_cells = {"WING_L_CENTER"}}, -- 35
        ["WING_L_CENTER"]           = {critical_damage = 4, deps_cells = {"WING_L_PART_CENTER", "FLAP_L", "WING_L_OUT"}}, -- 29
        ["WING_L_PART_CENTER"]      = {critical_damage = 1.5}, -- 27 -- spoiler
        ["WING_L_OUT"]              = {critical_damage = 3, deps_cells = {"AILERON_L"}}, -- 23
        ["FLAP_L"]                  = {critical_damage = 2}, -- 37
        ["AILERON_L"]               = {critical_damage = 1}, --25
        ["WHEEL_L"]                 = {critical_damage = 3}, -- 84

        ["WING_R_IN"]               = {critical_damage = 5, deps_cells = {"WING_R_CENTER"}}, -- 36
        ["WING_R_CENTER"]           = {critical_damage = 4, deps_cells = {"WING_R_PART_CENTER", "FLAP_R", "WING_R_OUT"}}, -- 30
        ["WING_R_PART_CENTER"]      = {critical_damage = 1.5}, -- 28 -- spoiler
        ["WING_R_OUT"]              = {critical_damage = 3, deps_cells = {"AILERON_R"}}, -- 24
        ["FLAP_R"]                  = {critical_damage = 2}, -- 38
        ["AILERON_R"]               = {critical_damage = 1}, --26
        ["WHEEL_R"]                 = {critical_damage = 3}, -- 85

        ["TAIL"]                    = {critical_damage = 2}, -- 55
        ["TAIL_LEFT_SIDE"]          = {critical_damage = 3}, -- 56
        ["TAIL_RIGHT_SIDE"]         = {critical_damage = 3}, -- 57
        -- ["TAIL_BOTTOM"]             = {critical_damage = 3}, --58
        ["STABILIZATOR_L"]          = {critical_damage = 2, deps_cells = {"ELEVATOR_L"}}, -- 47
        ["ELEVATOR_L"]              = {critical_damage = 1}, -- 51
        ["STABILIZATOR_R"]          = {critical_damage = 2, deps_cells = {"ELEVATOR_R"}}, -- 48
        ["ELEVATOR_R"]              = {critical_damage = 1}, -- 52
        ["RUDDER"]                  = {critical_damage = 1}, --53

        ["FIN_L_TOP"]               = {critical_damage = 4}, --53
        ["FIN_L_BOTTOM"]            = {critical_damage = 4, deps_cells = {"RUDDER", "FIN_L_TOP"}}, --53
        -- ["HOOK"]                    = {critical_damage = 2}, -- 98

    }),


    DamageParts =
    {
        -- [1] = "a4_dmg_wing_right", 	-- Right Wing
        -- [2] = "a4_dmg_wing_left", 	-- Left Wing
        -- [3] = "a4_dmg_fus_front", 	-- nose
        -- [4] = "a4_dmg_fus_back", 	-- tail
    },
---------------------------------------------------------------------------------------------------------------------------------------------
    lights_data = {
        typename = "collection",
        lights = {
            -- STROBES
            [1] = {
                typename = "collection",
                lights = {
                            {typename = "argnatostrobelight", argument = 204, period = 1.2, phase_shift = 0},
                            {typename = "argnatostrobelight", argument = 205, period = 1.2, phase_shift = 0.5},
                },
            },
            -- SPOTS / TAXI & LANDING
            [2] = {
                typename = "collection",
                lights = {  {typename  = "argumentlight", argument  = 208},	-- taxi light
                },
            },
            -- NAVLIGHTS
            [3] = {
                typename = "collection",
                lights = {  {typename  = "argumentlight", argument  = 190},	-- red
                            {typename  = "argumentlight", argument  = 191},	-- green
                            {typename  = "argumentlight", argument  = 192},	-- white
                },
            },
            -- FORMATION
            [4] = {},
            -- TIPS
            [5] = {},
            -- REFUEL
            [6] = {
                typename = "collection",
                lights = {  {typename  = "argumentlight", argument  = 193},	-- probe light
                },
            },
            -- ANTI-COLLISION
            [7] = {},
        }, -- end of lights
    }, -- end of lights_data
}

add_aircraft(A_4E_C)
