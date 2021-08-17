local searchedVeh = {}
local startedEngine = {}
local uiOpen = false

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
	TriggerServerEvent('Boost-Locksystem:Refresh')
end)

Citizen.CreateThread(function()
    RegisterCommand('search', Search)
end)


Citizen.CreateThread(function()
    local sleep = 0
    while true do
        local playerPed = PlayerPedId()
        local veh = GetVehiclePedIsIn(playerPed, true)
        local plate = GetVehicleNumberPlateText(veh)
        local isInVehicle = IsPedInAnyVehicle(playerPed, false)

        if isInVehicle and GetPedInVehicleSeat(veh, -1) == playerPed then
            sleep = 10
            if startedEngine[plate] == true then
                SetVehicleEngineOn(veh, true, true, false)
            else
                SetVehicleEngineOn(veh, false, false, true)
            end
        else
            sleep = 100
        end
        if isInVehicle and GetPedInVehicleSeat(veh, -1) == playerPed then
            sleep = 10
            if not startedEngine[plate] then
                SetVehicleEngineOn(veh, false, false, true)
            end
        else
            sleep = 100
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    local sleep = 10
	while true do
		local ped = GetPlayerPed(-1)
        if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
            sleep = 10
        	local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
	        local lock = GetVehicleDoorLockStatus(veh)
	        if lock == 4 then
	        	ClearPedTasks(ped)
	        end
        else
            sleep = 150
        end
        Citizen.Wait(sleep)
	end
end)

function Search()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, true)
    local plate = GetVehicleNumberPlateText(vehicle)
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)
    ESX.TriggerServerCallback('Boost-Locksystem:HasKeys', function(hasKeys) 
        if hasKeys then
            Notification('info', _('has_key'))
            return
        end
        if isInVehicle then
            if searchedVeh[plate] then
                Notification('error', _('no_key_veh'))
            else
                if Config.OnlyRegisteredCars then
                    ESX.TriggerServerCallback('Boost-Locksystem:IsCarRegistered', function(isRegistered) 
                        if isRegistered then
                            searchedVeh[plate] = true
                            Notification('success', _('found_key'))
                            TriggerServerEvent('Boost-Locksystem:AddKeys', plate)
                        else
                            Notification('error', _('not_registered'))
                        end
                    end, plate)
                else
                    searchedVeh[plate] = true
                    Notification('success', _('found_key'))
                    TriggerServerEvent('Boost-Locksystem:AddKeys', plate)
                end
            end
        end
    end, plate)
end

RegisterNetEvent('Boost-Locksystem:LockUnlock')
AddEventHandler('Boost-Locksystem:LockUnlock', function(item, wait, cb)
    local metadata = ESX.GetPlayerData().inventory[item.slot].metadata
    OpenUi(metadata.plate)
end)

RegisterNUICallback('Close', function(data)
    CloseUi()
end)

RegisterNUICallback('Lock', function(data)
    local veh = ESX.Game.GetClosestVehicle()
    if veh == -1 then
        Notification('error', _('no_veh_nearby'))
        return
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehLockStatus = GetVehicleDoorLockStatus(veh)
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)
    local plate = GetVehicleNumberPlateText(veh)
    if data.plate ~= plate then
        Notification('error', _('key_not_owned_car'))
        return
    end
    if isInVehicle then
        if vehLockStatus == 1 then
            Progress(_('pr_lock'), 1500)
            SetVehicleDoorsLocked(veh, 4)
            Notification('success', _('lock_veh'))
        else
            Notification('error', _('locked'))
        end
    else
        if vehLockStatus == 1 then
            if #(playerCoords - GetEntityCoords(veh)) <= 4.0 then
                local SpatelObject = CreateObject(GetHashKey("p_car_keys_01"), 0, 0, 0, true, true, true)
                AttachEntityToEntity(SpatelObject, playerPed, GetPedBoneIndex(playerPed, 57005), 0.08, 0.0, -0.02, 0.0, -25.0, 130.0, true, true, false, true, 1, true)
                loadAnimDict("veh@break_in@0h@p_m_one@")
                TaskPlayAnim(playerPed, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds' ,1.0, 4.0, -1, 49, 0, false, false, false)
                Progress(_('pr_lock'), 1500)
                DeleteEntity(SpatelObject)
                ClearPedTasksImmediately(playerPed)
                DeleteEntity(SpatelObject)
                SetVehicleDoorsLocked(veh, 4)
                Notification('success', _('lock_veh'))
            else
                Notification('error',_('too_far_veh'))
            end
        else
            Notification('error', _('locked'))
        end
    end
end)

RegisterNUICallback('Unlock', function(data)
    local veh = ESX.Game.GetClosestVehicle()
    if veh == -1 then
        Notification('error', _('no_veh_nearby'))
        return
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehLockStatus = GetVehicleDoorLockStatus(veh)
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)
    local plate = GetVehicleNumberPlateText(veh)
    if data.plate ~= plate then
        Notification('error', _('key_not_owned_car'))
        return
    end
    if isInVehicle then
        if vehLockStatus == 4 then
            Progress(_('pr_unlock'), 1500)
            SetVehicleDoorsLocked(veh, 1)
            Notification('success', _('unlock_veh'))
        else
            Notification('error', _('unlocked'))
        end
    else
        if vehLockStatus == 4 then
            if #(playerCoords - GetEntityCoords(veh)) <= 4.0 then
                local SpatelObject = CreateObject(GetHashKey("p_car_keys_01"), 0, 0, 0, true, true, true)
                AttachEntityToEntity(SpatelObject, playerPed, GetPedBoneIndex(playerPed, 57005), 0.08, 0.0, -0.02, 0.0, -25.0, 130.0, true, true, false, true, 1, true)
                loadAnimDict("veh@break_in@0h@p_m_one@")
                TaskPlayAnim(playerPed, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds' ,1.0, 4.0, -1, 49, 0, false, false, false)
                Progress(_('pr_unlock'), 1500)
                DeleteEntity(SpatelObject)
                ClearPedTasksImmediately(playerPed)
                DeleteEntity(SpatelObject)
                SetVehicleDoorsLocked(veh, 1)
                Notification('success', _('unlock_veh'))
            else
                Notification('error',_('too_far_veh'))
            end
        else
            Notification('error', _('unlocked'))
        end
    end
end)

RegisterNUICallback('Engine', function(data)
    local playerPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(playerPed, true)
    local plate = GetVehicleNumberPlateText(vehicle)
    local isInVehicle = IsPedInAnyVehicle(playerPed, false)
    local plate = GetVehicleNumberPlateText(veh)
    if isInVehicle then
        if data.plate ~= plate then
            Notification('error', _('key_not_owned_car'))
            return
        end
        if not startedEngine[plate] then
            Progress(_('pr_engine_on'), 2000)
            startedEngine[plate] = true
            TriggerServerEvent('Boost-Locksystem:SyncEngine', plate, true)
        else
            Progress(_('pr_engine_off'), 1000)
            startedEngine[plate] = false
            TriggerServerEvent('Boost-Locksystem:SyncEngine', plate, false)
        end
    end
end)

loadAnimDict = function(anim)
    RequestAnimDict(anim)
    while not HasAnimDictLoaded(anim) do
        Citizen.Wait(0)
    end
end

RegisterNetEvent('Boost-Locksystem:SetUpSearched', function(data)
    searchedVeh = data
end)

RegisterNetEvent('Boost-Locksystem:SetUpEngine', function(data)
    startedEngine = data
end)

function OpenUi(plate)
    if not uiOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({
            show = true,
            plate = plate
        })
        uiOpen = true
    end
end

function CloseUi()
    if uiOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({
            show = false,
            plate = ''
        })
        uiOpen = false
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    CloseUi()
end)
