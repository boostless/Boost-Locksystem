local searchedVeh = {}
local startedEngine = {}
local uiOpen = false
local PlayerPed = nil
local mainThread = nil
local lockThread = nil

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    PlayerPed = PlayerPedId()
	TriggerServerEvent('Boost-Locksystem:Refresh')
end)

CreateThread(function()
    RegisterCommand('search', Search)
end)

mainThread = SetInterval(function()
    local veh = GetVehiclePedIsIn(PlayerPed, true)
    local plate = GetVehicleNumberPlateText(veh)
    local isInVehicle = IsPedInAnyVehicle(PlayerPed, false)
    if not isInVehicle then SetInterval(mainThread, 500) end

    if isInVehicle and GetPedInVehicleSeat(veh, -1) == PlayerPed then
        if startedEngine[plate] == true then
            SetVehicleEngineOn(veh, true, true, false)
        else
            SetVehicleEngineOn(veh, false, false, true)
        end
    end

    if isInVehicle and GetPedInVehicleSeat(veh, -1) == PlayerPed then
        if not startedEngine[plate] then
            SetVehicleEngineOn(veh, false, false, true)
        end
    end
end, 100)

lockThread = SetInterval(function()
    local ped = GetPlayerPed(-1)
    if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
        local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
	    local lock = GetVehicleDoorLockStatus(veh)
	    if lock == Config.LockStateLocked then
	        ClearPedTasks(ped)
	    end
    else SetInterval(lockThread, 500)  end
end, 10)

function Search()
    local vehicle = GetVehiclePedIsIn(PlayerPed, true)
    local plate = GetVehicleNumberPlateText(vehicle)
    local isInVehicle = IsPedInAnyVehicle(PlayerPed, false)
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

RegisterNetEvent('Boost-Locksystem:LockUnlock', function(item, data)
    if not data.metadata.plate then Notification('error', 'The key has no metadata !') return end
    OpenUi(data.metadata.plate)
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
    local playerCoords = GetEntityCoords(PlayerPed)
    local vehLockStatus = GetVehicleDoorLockStatus(veh)
    local isInVehicle = IsPedInAnyVehicle(PlayerPed, false)
    local plate = GetVehicleNumberPlateText(veh)
    if data.plate ~= plate then
        Notification('error', _('key_not_owned_car'))
        return
    end
    if isInVehicle then
        if vehLockStatus == 1 then
            Progress(_('pr_lock'), 1500)
            SetVehicleDoorsLocked(veh, Config.LockStateLocked)
            Notification('success', _('lock_veh'))
        else
            Notification('error', _('locked'))
        end
    else
        if vehLockStatus == 1 then
            if #(playerCoords - GetEntityCoords(veh)) <= 4.0 then
                local SpatelObject = CreateObject(GetHashKey("p_car_keys_01"), 0, 0, 0, true, true, true)
                AttachEntityToEntity(SpatelObject, PlayerPed, GetPedBoneIndex(PlayerPed, 57005), 0.08, 0.0, -0.02, 0.0, -25.0, 130.0, true, true, false, true, 1, true)
                loadAnimDict("veh@break_in@0h@p_m_one@")
                TaskPlayAnim(PlayerPed, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds' ,1.0, 4.0, -1, 49, 0, false, false, false)
                Progress(_('pr_lock'), 1500)
                DeleteEntity(SpatelObject)
                ClearPedTasksImmediately(PlayerPed)
                DeleteEntity(SpatelObject)
                SetVehicleDoorsLocked(veh, Config.LockStateLocked)
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
    local playerCoords = GetEntityCoords(PlayerPed)
    local vehLockStatus = GetVehicleDoorLockStatus(veh)
    local isInVehicle = IsPedInAnyVehicle(PlayerPed, false)
    local plate = GetVehicleNumberPlateText(veh)
    if data.plate ~= plate then
        Notification('error', _('key_not_owned_car'))
        return
    end
    if isInVehicle then
        if vehLockStatus == Config.LockStateLocked then
            Progress(_('pr_unlock'), 1500)
            SetVehicleDoorsLocked(veh, 1)
            Notification('success', _('unlock_veh'))
        else
            Notification('error', _('unlocked'))
        end
    else
        if vehLockStatus == Config.LockStateLocked then
            if #(playerCoords - GetEntityCoords(veh)) <= 4.0 then
                local SpatelObject = CreateObject(GetHashKey("p_car_keys_01"), 0, 0, 0, true, true, true)
                AttachEntityToEntity(SpatelObject, PlayerPed, GetPedBoneIndex(PlayerPed, 57005), 0.08, 0.0, -0.02, 0.0, -25.0, 130.0, true, true, false, true, 1, true)
                loadAnimDict("veh@break_in@0h@p_m_one@")
                TaskPlayAnim(PlayerPed, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds' ,1.0, 4.0, -1, 49, 0, false, false, false)
                Progress(_('pr_unlock'), 1500)
                DeleteEntity(SpatelObject)
                ClearPedTasksImmediately(PlayerPed)
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
    local veh = GetVehiclePedIsIn(PlayerPed, true)
    local plate = GetVehicleNumberPlateText(vehicle)
    local isInVehicle = IsPedInAnyVehicle(PlayerPed, false)
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
        Wait(0)
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
