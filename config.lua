Config = {}

Config.useMPH = true
Config.minimapWalking = true
Config.minimapAlwaysOn = true -- Keep minimap always visible
Config.fixMinimapZoom = true -- Fix minimap zoom jumping/glitching
Config.minimapZoom = 1000 -- Fixed zoom level (higher = more zoomed out)
Config.fuel = 'xfuel' -- Options: 'LegacyFuel', 'ps-fuel', 'ox_fuel', 'xfuel' (x-fuel resource), 'okokGasStation'
Config.useCustomMinimap = true -- Set to false if having minimap issues
Config.debug = false -- Enable debug mode for troubleshooting

Config.noHudVehicles = {
    [`bmx`] = true,
}

Config.useStress = {
    shooting = true,
    driving = true,
}

-- Stamina Configuration
Config.useStamina = true
Config.staminaIcon = "fas fa-lungs"
Config.staminaColorNormal = "#00ff41"
Config.staminaColorLow = "#ff6b35"
Config.staminaLowThreshold = 20
Config.staminaUpdateMethod = 'native' -- Options: 'native' (GetPlayerStamina), 'metadata' (from player metadata)

-- Oxygen/Diving Configuration
Config.enableOxygenDamage = true -- Enable health reduction when oxygen is low
Config.oxygenDamageWithoutGear = 1 -- Health reduction per update without diving gear (when oxygen < 15%)
Config.oxygenDamageEmptyWithoutGear = 3 -- Health reduction per update without gear when oxygen = 0%
Config.oxygenDamageWithGear = 2 -- Health reduction per update with diving gear (when oxygen = 0%)
Config.oxygenWarningThreshold = 15 -- Oxygen percentage to start health reduction without gear

-- QBX Divegear Integration
Config.enableQbxDivegear = true -- Enable qbx_divegear integration (automatic detection)
Config.qbxDivegearItem = 'diving_gear' -- Item name for qbx_divegear detection

Config.useWeaponHUD = true -- Set to false to disable weapon HUD
Config.weaponUpdateInterval = 100 -- Weapon HUD update interval in milliseconds

-- Seatbelt System Configuration
Config.seatbeltSystem = 'auto' -- Options: 'auto', 'smallresources', 'custom', 'qbox', 'esx'
Config.seatbeltKey = 'B' -- Default seatbelt toggle key
Config.seatbeltDefaultState = false -- Default seatbelt state when entering vehicle

Config.screenShake = 75 -- Minimum stress level for screen shaking
Config.shootingStressChance = 0.1 -- Percentage stress chance when shooting (0-1) (default = 10%)
Config.unbuckledSpeed = 50 -- Going over this Speed will cause stress
Config.minimumSpeed = 400 -- Going over this Speed will cause stress
Config.stressWLJobs = {
    police = true,
    --ambulance = true,
}

Config.weaponWLStress = { -- Disable gaining stress from weapons in this table
    [`weapon_petrolcan`] = true,
    [`weapon_hazardcan`] = true,
    [`weapon_fireextinguisher`] = true
}

Config.intensity = {
    [1] = {
        min = 50,
        max = 60,
        intensity = 1500,
    },
    [2] = {
        min = 60,
        max = 70,
        intensity = 2000,
    },
    [3] = {
        min = 70,
        max = 80,
        intensity = 2500,
    },
    [4] = {
        min = 80,
        max = 90,
        intensity = 2700,
    },
    [5] = {
        min = 90,
        max = 100,
        intensity = 3000,
    },
}

Config.effectInterval = {
    [1] = {
        min = 50,
        max = 60,
        timeout = math.random(50000, 60000)
    },
    [2] = {
        min = 60,
        max = 70,
        timeout = math.random(40000, 50000)
    },
    [3] = {
        min = 70,
        max = 80,
        timeout = math.random(30000, 40000)
    },
    [4] = {
        min = 80,
        max = 90,
        timeout = math.random(20000, 30000)
    },
    [5] = {
        min = 90,
        max = 100,
        timeout = math.random(15000, 20000)
    }
}

-- Debug and Compatibility Options
-- Config.debug is defined above
Config.updateInterval = 500 -- HUD update interval in milliseconds
Config.vehicleUpdateInterval = 50 -- Vehicle HUD update interval in milliseconds
Config.fuelUpdateInterval = 2000 -- Fuel check interval in milliseconds

-- Voice System Compatibility
Config.voiceSystem = 'pma-voice' -- Options: 'pma-voice', 'saltychat', 'tokovoip'