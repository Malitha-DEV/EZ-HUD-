local playerData = QBX.PlayerData
local speedMultiplier = Config.useMPH and 2.23694 or 3.6
local showingHUD = true
local health = 0
local armor = 0
local isTalking = false
local talkingOnRadio = false
local onRadio = false
local onPhone = false
local voiceRange = 2
local stats = {}
local vehicleStats = {
    fuel = 0,
    engineOn = false,
    beltOn = false,  -- Initialize seatbelt as off
    engine = false
}
local lastFuelUpdate = 0
local lastFuelCheck = nil
local lastCrossroadUpdate = 0
local lastCrossroadCheck = nil
local isUIReady = false
local weaponStats = {
    weapon = nil,
    ammo = 0,
    totalAmmo = 0,
    weaponHash = nil,
    showing = false
}

-- Validate fuel system on startup
local function validateFuelSystem()
    local resourceName = nil
    
    if Config.fuel == 'xfuel' then
        resourceName = 'x-fuel'
    elseif Config.fuel == 'LegacyFuel' then
        resourceName = 'LegacyFuel'
    elseif Config.fuel == 'ps-fuel' then
        resourceName = 'ps-fuel'
    elseif Config.fuel == 'ox_fuel' then
        resourceName = 'ox_fuel'
    elseif Config.fuel == 'okokGasStation' then
        resourceName = 'okokGasStation'
    end
    
    if resourceName then
        local resourceState = GetResourceState(resourceName)
        if resourceState ~= 'started' then
            print("^1[EZ-HUD]^7 WARNING: Fuel system '" .. Config.fuel .. "' (resource: " .. resourceName .. ") is not running!")
            print("^3[EZ-HUD]^7 Falling back to native fuel system")
            return false
        else
            print("^2[EZ-HUD]^7 Fuel system '" .. Config.fuel .. "' validated successfully")
            return true
        end
    end
    
    print("^3[EZ-HUD]^7 Using native fuel system")
    return false
end

local function updateStats()
    -- Only send updates if UI is ready or we're forcing it
    if not isUIReady then return end
    
    -- Validate all values before sending to UI
    local validHealth = math.max(0, math.min(100, health or 0))
    local validArmor = math.max(0, math.min(100, armor or 0))
    local validStats = stats or {}
    
    -- Ensure stats have valid values
    validStats.hunger = math.max(0, math.min(100, validStats.hunger or 100))
    validStats.thirst = math.max(0, math.min(100, validStats.thirst or 100))
    validStats.stress = math.max(0, math.min(100, validStats.stress or 0))
    
    -- Add stamina if enabled
    if Config.useStamina then
        validStats.stamina = math.max(0, math.min(100, validStats.stamina or 100))
        if Config.debug and validStats.stamina then
            print("^2[EZ-HUD]^7 Sending stamina to UI: " .. validStats.stamina)
        end
    end
    
    SendNUIMessage({
        action = 'updateStats', 
        data = {
            showing = IsPauseMenuActive() == false and showingHUD or false,
            health = validHealth,
            armor = validArmor,
            isTalking = isTalking or false,
            talkingOnRadio = talkingOnRadio or false,
            onRadio = onRadio or false,
            onPhone = onPhone or false,
            voiceRange = voiceRange or 2,
            stats = validStats
        }
    })
end

local function updateVehicleStats()
    if not cache.vehicle or not isUIReady then return end
    local veh = cache.vehicle
    
    -- Validate vehicle stats
    local validFuel = math.max(0, math.min(100, vehicleStats.fuel or 0))
    local validRpm = math.max(0, math.min(1, GetVehicleCurrentRpm(veh) or 0))
    local validSpeed = math.max(0, math.ceil(GetEntitySpeed(veh) * speedMultiplier) or 0)
    
    SendNUIMessage({
        action = 'updateVehicle', 
        data = {
            showing = IsPauseMenuActive() == false and showingHUD or false,
            rpm = validRpm,
            speed = validSpeed,
            fuel = validFuel,
            engineOn = vehicleStats.engineOn or false,
            beltOn = vehicleStats.beltOn or false,
        }
    })
end

local function updateWeaponStats()
    if not isUIReady or not Config.useWeaponHUD then return end
    
    local ped = cache.ped
    local currentWeapon = GetSelectedPedWeapon(ped)
    local isArmed = currentWeapon ~= `WEAPON_UNARMED`
    
    if isArmed then
        local ammoInClip = GetAmmoInClip(ped, currentWeapon)
        local totalAmmo = GetAmmoInPedWeapon(ped, currentWeapon)
        
        weaponStats.weapon = currentWeapon
        weaponStats.ammo = ammoInClip
        weaponStats.totalAmmo = totalAmmo - ammoInClip
        weaponStats.weaponHash = currentWeapon
        weaponStats.showing = true
        
        if Config.debug then
            print("^2[EZ-HUD]^7 Weapon: " .. currentWeapon .. " | Clip: " .. ammoInClip .. " | Total: " .. (totalAmmo - ammoInClip))
        end
        
        SendNUIMessage({
            action = 'updateWeapon',
            data = {
                showing = IsPauseMenuActive() == false and showingHUD and isArmed,
                weapon = weaponStats.weapon,
                ammo = weaponStats.ammo,
                totalAmmo = weaponStats.totalAmmo,
                weaponHash = weaponStats.weaponHash
            }
        })
    else
        if weaponStats.showing then -- Only send hide message if previously showing
            weaponStats.showing = false
            SendNUIMessage({
                action = 'updateWeapon',
                data = {
                    showing = false,
                    weapon = nil,
                    ammo = 0,
                    totalAmmo = 0,
                    weaponHash = nil
                }
            })
        end
    end
end

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num + 0.5 * mult)
end

local function initializeUI()
    print("^2[EZ-HUD]^7 Initializing UI...")
    
    -- Set NUI focus to ensure callbacks work
    SetNuiFocus(false, false)
    
    -- Initialize UI with safe default values
    SendNUIMessage({
        action = 'initialize',
        data = {
            config = {
                useMPH = Config.useMPH,
                minimapWalking = Config.minimapWalking,
                fuelSystem = Config.fuel
            }
        }
    })
    
    -- Wait for UI to be ready
    CreateThread(function()
        local attempts = 0
        while not isUIReady and attempts < 30 do
            SendNUIMessage({action = 'ping'})
            Wait(200)
            attempts = attempts + 1
            if Config.debug then
                print("^3[EZ-HUD]^7 UI initialization attempt " .. attempts .. "/30")
            end
        end
        
        if isUIReady then
            print("^2[EZ-HUD]^7 UI initialized successfully")
        else
            print("^1[EZ-HUD]^7 UI failed to initialize - NUI may not be responding")
            print("^3[EZ-HUD]^7 Check F8 console for JavaScript errors")
            print("^3[EZ-HUD]^7 Continuing without UI confirmation...")
            isUIReady = true -- Force continue
        end
    end)
end

-- Handle UI ready response
RegisterNUICallback('uiReady', function(data, cb)
    isUIReady = true
    print("^2[EZ-HUD]^7 UI callback received - NUI is working")
    cb('ok')
end)

-- Handle ping response for testing
RegisterNUICallback('pong', function(data, cb)
    isUIReady = true
    print("^2[EZ-HUD]^7 UI ping response received")
    cb('ok')
end)

local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > Config.fuelUpdateInterval then
        lastFuelUpdate = updateTick
        
        -- Support multiple fuel systems with error handling
        local success, fuelValue = false, 0
        
        if Config.fuel == 'xfuel' then
            -- Codem xFuel system (x-fuel resource)
            success, fuelValue = pcall(function()
                return exports['x-fuel']:GetFuel(vehicle)
            end)
            if success and fuelValue then
                lastFuelCheck = math.floor(fuelValue)
            else
                if Config.debug then print("^3[EZ-HUD]^7 xFuel export failed, using fallback") end
                lastFuelCheck = math.floor(GetVehicleFuelLevel(vehicle))
            end
        elseif Config.fuel == 'LegacyFuel' then
            success, fuelValue = pcall(function()
                return exports.LegacyFuel:GetFuel(vehicle)
            end)
            lastFuelCheck = success and math.floor(fuelValue or 0) or math.floor(GetVehicleFuelLevel(vehicle))
        elseif Config.fuel == 'ps-fuel' then
            success, fuelValue = pcall(function()
                return exports['ps-fuel']:GetFuel(vehicle)
            end)
            lastFuelCheck = success and math.floor(fuelValue or 0) or math.floor(GetVehicleFuelLevel(vehicle))
        elseif Config.fuel == 'ox_fuel' then
            success, fuelValue = pcall(function()
                return Entity(vehicle).state.fuel
            end)
            lastFuelCheck = success and math.floor(fuelValue or 0) or math.floor(GetVehicleFuelLevel(vehicle))
        elseif Config.fuel == 'okokGasStation' then
            success, fuelValue = pcall(function()
                return exports.okokGasStation:GetFuel(vehicle)
            end)
            lastFuelCheck = success and math.floor(fuelValue or 0) or math.floor(GetVehicleFuelLevel(vehicle))
        else
            -- Fallback to vehicle native fuel
            lastFuelCheck = math.floor(GetVehicleFuelLevel(vehicle))
        end
        
        -- Ensure fuel level is within valid range
        if lastFuelCheck < 0 then lastFuelCheck = 0 end
        if lastFuelCheck > 100 then lastFuelCheck = 100 end
    end
    return lastFuelCheck
end

local function getCrossroads()
    local updateTick = GetGameTimer()
    if updateTick - lastCrossroadUpdate > 1500 then
        local pos = GetEntityCoords(cache.ped)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        local street1 = GetStreetNameFromHashKey(street1)
        local street2 = GetStreetNameFromHashKey(street2)
        if street2 then
            lastCrossroadCheck = street1..' x '..street2
        else
            lastCrossroadCheck = street1
        end
    end
    return lastCrossroadCheck
end

local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"}
local function getCardinalDirection(heading)
    local index = math.floor(((heading % 360) + 22.5) / 45) + 1
    return directions[index]
end

local function loadMap()
    CreateThread(function()
        Wait(50)
        print("^2[EZ-HUD]^7 Loading minimap...")
        
        local defaultAspectRatio = 1920 / 1080
        local resolutionX, resolutionY = GetActiveScreenResolution()
        local aspectRatio = resolutionX / resolutionY
        local minimapOffset = 0
        if aspectRatio > defaultAspectRatio then
            minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
        end
        
        -- Try to load custom minimap if enabled
        local hasCustomMinimap = false
        local loadedTexture = nil
        
        if Config.useCustomMinimap then
            local textureNames = {'ez_minimap', 'majestic_minimap'}
            
            for _, textureName in ipairs(textureNames) do
                hasCustomMinimap = lib.requestStreamedTextureDict(textureName, 1000)
                if hasCustomMinimap then
                    loadedTexture = textureName
                    print("^2[EZ-HUD]^7 Loaded custom minimap: " .. textureName)
                    break
                end
            end
        else
            print("^3[EZ-HUD]^7 Custom minimap disabled in config")
        end
        
        SetMinimapClipType(1)
        
        if hasCustomMinimap and loadedTexture then
            AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', loadedTexture, 'radarmasksm')
            AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', loadedTexture, 'radarmasksm')
            print("^2[EZ-HUD]^7 Custom minimap applied successfully")
        else
            print("^3[EZ-HUD]^7 Using default minimap")
        end
        
        -- Set minimap position and properties
        SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset, -0.047, 0.1638, 0.183)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset, 0.0, 0.128, 0.20)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + minimapOffset, 0.025, 0.262, 0.300)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetMinimapClipType(1)
        SetBigmapActive(true, false)
        Wait(50)
        SetBigmapActive(false, false)
        
        if hasCustomMinimap and loadedTexture then
            SetStreamedTextureDictAsNoLongerNeeded(loadedTexture)
        end
        
        print("^2[EZ-HUD]^7 Minimap loading complete")
    end)
end

local function vehicleStressLoop(veh)
    CreateThread(function()
        while veh == cache.vehicle do
            local vehClass = GetVehicleClass(veh)
            local speed = GetEntitySpeed(veh) * speedMultiplier
            local vehHash = GetEntityModel(veh)
            local stressSpeed
            if vehClass == 8 then -- Motorcycle exception for seatbelt
                stressSpeed = Config.minimumSpeed
            else
                stressSpeed = vehicleStats.beltOn and Config.minimumSpeed or Config.unbuckledSpeed
            end
            if speed >= stressSpeed then
                TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
            end
            Wait(10000)
        end
    end)
end

local function vehicleLoop(veh)
    if Config.noHudVehicles[GetEntityModel(veh)] then return end
    if Config.useStress.driving then
        vehicleStressLoop(veh)
    end
    CreateThread(function()
        while veh == cache.vehicle do
            SendNUIMessage({
                action = 'compasstick',
                data  = {
                    direction = getCardinalDirection(GetGameplayCamRot(0).z),
                    roads = getCrossroads(),
                    zone = GetLabelText(GetNameOfZone(GetEntityCoords(cache.ped))),
                },
            })
            updateVehicleStats()
            Wait(Config.vehicleUpdateInterval)
        end
        SendNUIMessage({
            action = 'updateVehicle', 
            data = {showing = false, rpm = 0, speed = 0}
        })
    end)
end

local function holdingWeaponLoop()
    CreateThread(function()
        while cache.weapon do
            if IsPedShooting(cache.ped) and not Config.weaponWLStress[cache.weapon] then
                if math.random() < Config.shootingStressChance then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end
            Wait(0)
        end
    end)
end

lib.onCache('vehicle', function(value) if value then vehicleLoop(value) end end)
lib.onCache('weapon', function(hash)
    if not Config.useStress.shooting then return end
    if hash then
        if cache.weapon then
            cache.weapon = false
            Wait(1000)
        end
        holdingWeaponLoop()
    end
end)

local function GetBlurIntensity(stresslevel)
    for _, v in pairs(Config.intensity) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    for _, v in pairs(Config.effectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout
        end
    end
    return 60000
end

CreateThread(function()
    stats.stress = stats.stress or 0
    while true do
        local effectInterval = GetEffectInterval(stats.stress)
        if stats.stress >= 100 then
            local BlurIntensity = GetBlurIntensity(stats.stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
            if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                SetPedToRagdollWithFall(cache.ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(cache.ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end
            Wait(1000)
            for _ = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
        elseif stats.stress >= Config.screenShake then
            local BlurIntensity = GetBlurIntensity(stats.stress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end
        Wait(effectInterval)
    end
end)

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do 
        if Config.minimapAlwaysOn then
            DisplayRadar(true)
        else
            DisplayRadar(false)
        end
        Wait(1000) 
    end
    
    -- Validate fuel system first
    validateFuelSystem()
    
    -- Initialize UI
    initializeUI()
    Wait(1000) -- Give UI time to initialize
    
    -- Then load map
    loadMap()
    
    -- Ensure minimap is visible after loading
    if Config.minimapAlwaysOn then
        DisplayRadar(true)
        print("^2[EZ-HUD]^7 Minimap set to always visible")
    end
    
    while true do        
        Wait(Config.updateInterval)
        local ped = cache.ped
        local playerId = cache.playerId
        health = math.floor((GetEntityHealth(ped) - 100)/(GetEntityMaxHealth(ped) - 100)*100)
        local isDead = IsEntityDead(ped) or playerData.metadata["inlaststand"] or playerData.metadata["isdead"] or false
        if isDead then health = 0 end
        armor = GetPedArmour(ped)
        
        -- Update stamina based on config
        if Config.useStamina then
            if Config.staminaUpdateMethod == 'native' then
                -- Check if player is underwater and handle oxygen/diving
                if IsEntityInWater(ped) then
                    -- Check if player has qbx_divegear equipped (proper integration)
                    local hasDivingGear = false
                    local qbxGearActive = false
                    
                    -- Try to detect qbx_divegear first (preferred method)
                    if Config.enableQbxDivegear and GetResourceState('qbx_divegear') == 'started' then
                        -- Check if player has diving_gear item and it's active
                        local success, hasGearItem = pcall(function()
                            return exports.ox_inventory:Search('slots', Config.qbxDivegearItem)
                        end)
                        
                        if success and hasGearItem and #hasGearItem > 0 then
                            qbxGearActive = true
                            hasDivingGear = true
                            
                            if Config.debug then
                                print("^2[EZ-HUD]^7 QBX Divegear detected - Item found in inventory")
                            end
                        end
                    end
                    
                    -- Fallback to basic detection if qbx_divegear not available
                    if not qbxGearActive then
                        hasDivingGear = GetPedDrawableVariation(ped, 8) == 123 or -- Scuba mask
                                       GetPedDrawableVariation(ped, 8) == 124 or -- Diving mask
                                       IsPedWearingHelmet(ped) -- General diving helmet check
                    end
                    
                    -- If underwater, use oxygen level instead of stamina
                    local underwaterTime = GetPlayerUnderwaterTimeRemaining(playerId)
                    local maxUnderwaterTime = 25.0 -- Default breath holding time
                    local oxygenLevel = 0
                    
                    if qbxGearActive then
                        -- If using qbx_divegear, try to get their oxygen level
                        -- qbx_divegear uses their own oxygen system, so we sync with native underwater time
                        maxUnderwaterTime = 2000.0 -- qbx_divegear sets max underwater time to 2000
                        oxygenLevel = (underwaterTime / maxUnderwaterTime) * 100
                    elseif hasDivingGear then
                        -- Basic diving gear (non-qbx)
                        maxUnderwaterTime = 120.0 -- Basic diving gear time
                        oxygenLevel = (underwaterTime / maxUnderwaterTime) * 100
                    else
                        -- No diving gear - normal breath holding
                        oxygenLevel = (underwaterTime / maxUnderwaterTime) * 100
                    end
                    
                    -- Clamp oxygen level
                    if oxygenLevel > 100 then oxygenLevel = 100 end
                    if oxygenLevel < 0 then oxygenLevel = 0 end
                    stats.stamina = math.floor(oxygenLevel)
                    
                    -- Handle health reduction when oxygen is low (if enabled)
                    if Config.enableOxygenDamage then
                        if qbxGearActive then
                            -- With qbx_divegear: reduce health when oxygen is completely empty (0%)
                            -- qbx_divegear handles its own oxygen system, so we only damage when native oxygen is empty
                            if oxygenLevel <= 0 then
                                local currentHealth = GetEntityHealth(ped)
                                if currentHealth > 100 then
                                    local newHealth = currentHealth - Config.oxygenDamageWithGear
                                    SetEntityHealth(ped, newHealth)
                                    if Config.debug then
                                        print("^1[EZ-HUD]^7 QBX Diving gear oxygen empty! Health reduced: " .. newHealth)
                                    end
                                end
                            end
                        elseif hasDivingGear then
                            -- With basic diving gear: reduce health when oxygen is empty
                            if oxygenLevel <= 0 then
                                local currentHealth = GetEntityHealth(ped)
                                if currentHealth > 100 then
                                    local newHealth = currentHealth - Config.oxygenDamageWithGear
                                    SetEntityHealth(ped, newHealth)
                                    if Config.debug then
                                        print("^1[EZ-HUD]^7 Basic diving gear oxygen empty! Health reduced: " .. newHealth)
                                    end
                                end
                            end
                        else
                            -- Without diving gear: reduce health when oxygen is low
                            if oxygenLevel <= Config.oxygenWarningThreshold and oxygenLevel > 0 then
                                local currentHealth = GetEntityHealth(ped)
                                if currentHealth > 100 then
                                    local newHealth = currentHealth - Config.oxygenDamageWithoutGear
                                    SetEntityHealth(ped, newHealth)
                                    if Config.debug then
                                        print("^3[EZ-HUD]^7 Low oxygen warning! Health reduced: " .. newHealth)
                                    end
                                end
                            elseif oxygenLevel <= 0 then
                                -- Completely out of breath - faster health reduction
                                local currentHealth = GetEntityHealth(ped)
                                if currentHealth > 100 then
                                    local newHealth = currentHealth - Config.oxygenDamageEmptyWithoutGear
                                    SetEntityHealth(ped, newHealth)
                                    if Config.debug then
                                        print("^1[EZ-HUD]^7 No oxygen! Drowning! Health reduced: " .. newHealth)
                                    end
                                end
                            end
                        end
                    end
                    
                    if Config.debug then
                        local gearStatus = ""
                        if qbxGearActive then
                            gearStatus = " (QBX diving gear)"
                        elseif hasDivingGear then
                            gearStatus = " (basic diving gear)"
                        else
                            gearStatus = " (no gear)"
                        end
                        print("^2[EZ-HUD]^7 Underwater" .. gearStatus .. " - Oxygen: " .. stats.stamina .. "%")
                    end
                else
                    -- Normal stamina when not underwater
                    local currentStamina = GetPlayerStamina(playerId)
                    
                    -- Ensure stamina is properly bounded
                    if currentStamina > 100 then currentStamina = 100 end
                    if currentStamina < 0 then currentStamina = 0 end
                    
                    stats.stamina = math.floor(currentStamina)
                end
            end
        end
        
        isTalking = NetworkIsPlayerTalking(playerId) == 1
        onRadio = LocalPlayer.state['radioChannel'] > 0
        onPhone = LocalPlayer.state['callChannel'] > 0
        --parachute = GetPedParachuteState(ped)   Maybe...?
        --if IsEntityInWater(ped) then
            -- oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
        --end         
        -- Vehicle stats
        if cache.vehicle and not IsThisModelABicycle(cache.vehicle) then
            vehicleStats.fuel = getFuelLevel(cache.vehicle)
            vehicleStats.engine = (GetVehicleEngineHealth(cache.vehicle) / 10) < 50
            vehicleStats.engineOn = GetIsVehicleEngineRunning(cache.vehicle)
        end
        
        -- Minimap display logic
        if Config.minimapAlwaysOn then
            DisplayRadar(true)
        elseif cache.vehicle and not IsThisModelABicycle(cache.vehicle) then
            DisplayRadar(true)
        else
            DisplayRadar(Config.minimapWalking)
        end
        updateStats()
    end
end)

-- Separate thread for weapon HUD updates (more responsive)
CreateThread(function()
    while true do
        if Config.useWeaponHUD then
            updateWeaponStats()
        end
        Wait(Config.weaponUpdateInterval)
    end
end)

CreateThread(function()
    local minimap = RequestScaleformMovie('minimap')
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do
            Wait(1)
        end
    end
    
    -- Set initial zoom once
    if Config.fixMinimapZoom then
        SetRadarZoom(Config.minimapZoom)
        print("^2[EZ-HUD]^7 Minimap zoom set to: " .. Config.minimapZoom)
    end
    
    while true do
        SetBigmapActive(false, false)
        
        -- Only set zoom if not fixing zoom or if zoom has changed
        if not Config.fixMinimapZoom then
            SetRadarZoom(Config.minimapZoom)
        end
        
        Wait(2000) -- Increased interval to reduce performance impact
    end
end)

-- Qbox compatibility events
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(2000)
    playerData = QBX.PlayerData
    stats.hunger = playerData.metadata.hunger
    stats.thirst = playerData.metadata.thirst
    stats.stress = playerData.metadata.stress
    stats.stamina = playerData.metadata.stamina or 100
end)

RegisterNetEvent("qbx_core:client:playerLoaded", function()
    Wait(2000)
    playerData = QBX.PlayerData
    stats.hunger = playerData.metadata.hunger
    stats.thirst = playerData.metadata.thirst
    stats.stress = playerData.metadata.stress
    stats.stamina = playerData.metadata.stamina or 100
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    playerData = {}
end)

RegisterNetEvent("qbx_core:client:playerLoggedOut", function()
    playerData = {}
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    playerData = val
    stats.hunger = playerData.metadata.hunger
    stats.thirst = playerData.metadata.thirst
    stats.stress = playerData.metadata.stress
    stats.stamina = playerData.metadata.stamina or 100
end)

RegisterNetEvent("qbx_core:client:playerDataUpdated", function(val)
    playerData = val
    stats.hunger = playerData.metadata.hunger
    stats.thirst = playerData.metadata.thirst
    stats.stress = playerData.metadata.stress
    stats.stamina = playerData.metadata.stamina or 100
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)
    playerData = QBX.PlayerData
    stats.hunger = playerData.metadata.hunger
    stats.thirst = playerData.metadata.thirst
    stats.stress = playerData.metadata.stress
    stats.stamina = playerData.metadata.stamina or 100
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    stats.hunger = newHunger
    stats.thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stats.stress = newStress
end)

RegisterNetEvent('hud:client:UpdateStamina', function(newStamina) -- Add this event for stamina updates
    stats.stamina = newStamina
end)

AddEventHandler("pma-voice:setTalkingMode", function(mode)
    voiceRange = tonumber(mode)
    updateStats()
end)

AddEventHandler("pma-voice:radioActive", function(radioTalking)
    talkingOnRadio = radioTalking
    updateStats()
end)

-- Multiple seatbelt system compatibility
RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- smallresources seatbelt
    vehicleStats.beltOn = not vehicleStats.beltOn
    if Config.debug then
        print("^2[EZ-HUD]^7 Seatbelt toggled via smallresources: " .. tostring(vehicleStats.beltOn))
    end
    updateVehicleStats()
end)

RegisterNetEvent('seatbelt:toggle', function() -- Alternative seatbelt event
    vehicleStats.beltOn = not vehicleStats.beltOn
    if Config.debug then
        print("^2[EZ-HUD]^7 Seatbelt toggled via alternative event: " .. tostring(vehicleStats.beltOn))
    end
    updateVehicleStats()
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    vehicleStats.beltOn = not vehicleStats.beltOn
    if Config.debug then
        print("^2[EZ-HUD]^7 Seatbelt toggled via HUD event: " .. tostring(vehicleStats.beltOn))
    end
    updateVehicleStats()
end)

-- New seatbelt events for better compatibility
RegisterNetEvent('seatbelt:client:setState', function(state)
    vehicleStats.beltOn = state
    if Config.debug then
        print("^2[EZ-HUD]^7 Seatbelt state set: " .. tostring(vehicleStats.beltOn))
    end
    updateVehicleStats()
end)

-- QBox seatbelt compatibility
RegisterNetEvent('qbx_smallresources:client:SeatBelt', function()
    vehicleStats.beltOn = not vehicleStats.beltOn
    if Config.debug then
        print("^2[EZ-HUD]^7 Seatbelt toggled via QBox: " .. tostring(vehicleStats.beltOn))
    end
    updateVehicleStats()
end)

-- Vehicle enter/exit handling
lib.onCache('vehicle', function(vehicle)
    if vehicle then
        -- Reset seatbelt when entering vehicle
        vehicleStats.beltOn = Config.seatbeltDefaultState
        if Config.debug then
            print("^2[EZ-HUD]^7 Entered vehicle, seatbelt reset to: " .. tostring(vehicleStats.beltOn))
        end
    else
        -- Reset seatbelt when exiting vehicle
        vehicleStats.beltOn = false
        if Config.debug then
            print("^2[EZ-HUD]^7 Exited vehicle, seatbelt off")
        end
    end
    updateVehicleStats()
end)

-- Enhanced seatbelt state checking
CreateThread(function()
    while true do
        if cache.vehicle then
            local previousState = vehicleStats.beltOn
            
            -- Check various seatbelt state methods
            if LocalPlayer.state.seatbelt ~= nil then
                vehicleStats.beltOn = LocalPlayer.state.seatbelt
            elseif LocalPlayer.state.seatbeltOn ~= nil then
                vehicleStats.beltOn = LocalPlayer.state.seatbeltOn
            elseif LocalPlayer.state['seatbelt'] ~= nil then
                vehicleStats.beltOn = LocalPlayer.state['seatbelt']
            end
            
            -- Update UI if state changed
            if previousState ~= vehicleStats.beltOn and Config.debug then
                print("^2[EZ-HUD]^7 Seatbelt state changed via LocalPlayer.state: " .. tostring(vehicleStats.beltOn))
                updateVehicleStats()
            end
        else
            -- Ensure seatbelt is off when not in vehicle
            if vehicleStats.beltOn then
                vehicleStats.beltOn = false
                updateVehicleStats()
            end
        end
        Wait(500) -- Check more frequently for responsiveness
    end
end)

-- Debug commands
RegisterCommand('ez-hud-test', function()
    print("^2[EZ-HUD]^7 Testing UI...")
    print("^2[EZ-HUD]^7 UI Ready: " .. tostring(isUIReady))
    SendNUIMessage({action = 'test', data = {message = "Test from command"}})
end, false)

RegisterCommand('ez-hud-reload', function()
    print("^2[EZ-HUD]^7 Reloading UI...")
    isUIReady = false
    Wait(500)
    initializeUI()
end, false)

RegisterCommand('ez-hud-stamina', function()
    local ped = cache.ped
    local playerId = cache.playerId
    local nativeStamina = GetPlayerStamina(playerId)
    local metadataStamina = (playerData and playerData.metadata and playerData.metadata.stamina) or "N/A"
    
    print("^2[EZ-HUD]^7 Stamina Debug:")
    print("^3Native Stamina:^7 " .. math.floor(nativeStamina))
    print("^3Metadata Stamina:^7 " .. tostring(metadataStamina))
    print("^3Current Stats Stamina:^7 " .. (stats.stamina or "N/A"))
    print("^3Config Use Stamina:^7 " .. tostring(Config.useStamina))
    print("^3Config Method:^7 " .. Config.staminaUpdateMethod)
end, false)

RegisterCommand('ez-hud-minimap', function()
    print("^2[EZ-HUD]^7 Minimap Debug:")
    print("^3Always On:^7 " .. tostring(Config.minimapAlwaysOn))
    print("^3Walking Mode:^7 " .. tostring(Config.minimapWalking))
    print("^3Fix Zoom:^7 " .. tostring(Config.fixMinimapZoom))
    print("^3Zoom Level:^7 " .. Config.minimapZoom)
    print("^3Custom Minimap:^7 " .. tostring(Config.useCustomMinimap))
    
    -- Force show minimap
    DisplayRadar(true)
    SetRadarZoom(Config.minimapZoom)
    print("^2[EZ-HUD]^7 Minimap forced visible with zoom: " .. Config.minimapZoom)
end, false)

RegisterCommand('ez-hud-minimap-toggle', function()
    Config.minimapAlwaysOn = not Config.minimapAlwaysOn
    DisplayRadar(Config.minimapAlwaysOn)
    print("^2[EZ-HUD]^7 Minimap always on: " .. tostring(Config.minimapAlwaysOn))
end, false)

RegisterCommand('ez-hud-seatbelt', function()
    print("^2[EZ-HUD]^7 Seatbelt Debug:")
    print("^3Current State:^7 " .. tostring(vehicleStats.beltOn))
    print("^3In Vehicle:^7 " .. tostring(cache.vehicle ~= nil))
    print("^3LocalPlayer.state.seatbelt:^7 " .. tostring(LocalPlayer.state.seatbelt))
    print("^3LocalPlayer.state.seatbeltOn:^7 " .. tostring(LocalPlayer.state.seatbeltOn))
    print("^3Config System:^7 " .. Config.seatbeltSystem)
    print("^3Default State:^7 " .. tostring(Config.seatbeltDefaultState))
    
    if cache.vehicle then
        local vehClass = GetVehicleClass(cache.vehicle)
        print("^3Vehicle Class:^7 " .. vehClass .. (vehClass == 8 and " (Motorcycle)" or ""))
    end
end, false)

RegisterCommand('ez-hud-seatbelt-toggle', function()
    if cache.vehicle then
        vehicleStats.beltOn = not vehicleStats.beltOn
        print("^2[EZ-HUD]^7 Manually toggled seatbelt: " .. tostring(vehicleStats.beltOn))
        updateVehicleStats()
        
        -- Trigger seatbelt sound/notification if available
        TriggerEvent('seatbelt:client:ToggleSeatbelt')
    else
        print("^1[EZ-HUD]^7 You must be in a vehicle to toggle seatbelt")
    end
end, false)

RegisterCommand('ez-hud-weapon', function()
    local ped = cache.ped
    local currentWeapon = GetSelectedPedWeapon(ped)
    local ammoInClip = GetAmmoInClip(ped, currentWeapon)
    local totalAmmo = GetAmmoInPedWeapon(ped, currentWeapon)
    
    print("^2[EZ-HUD]^7 Weapon Debug:")
    print("^3Current Weapon:^7 " .. currentWeapon)
    print("^3Is Armed:^7 " .. tostring(currentWeapon ~= `WEAPON_UNARMED`))
    print("^3Ammo in Clip:^7 " .. ammoInClip)
    print("^3Total Ammo:^7 " .. totalAmmo)
    print("^3Reserve Ammo:^7 " .. (totalAmmo - ammoInClip))
    print("^3Weapon HUD Enabled:^7 " .. tostring(Config.useWeaponHUD))
    print("^3UI Ready:^7 " .. tostring(isUIReady))
end, false)

RegisterCommand('ez-hud-status', function()
    print("^2[EZ-HUD]^7 System Status:")
    print("^3UI Ready:^7 " .. tostring(isUIReady))
    print("^3Showing HUD:^7 " .. tostring(showingHUD))
    print("^3Health:^7 " .. (health or "N/A"))
    print("^3Armor:^7 " .. (armor or "N/A"))
    print("^3Stamina Enabled:^7 " .. tostring(Config.useStamina))
    print("^3Weapon HUD Enabled:^7 " .. tostring(Config.useWeaponHUD))
    print("^3Vehicle Stats:^7 " .. (cache.vehicle and "In Vehicle" or "On Foot"))
    print("^3Player Data:^7 " .. (playerData and "Loaded" or "Not Loaded"))
    
    -- Test UI communication
    SendNUIMessage({action = 'test', data = {message = "Status check from command"}})
    print("^3Test message sent to UI^7")
end, false)