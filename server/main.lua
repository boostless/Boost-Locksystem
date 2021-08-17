local searchedVeh = {}
local startedEngine = {}

ESX.RegisterServerCallback('Boost-Locksystem:HasKeys', function(source, cb, _plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local found = false
    for i=1, 50 do
        local slot = exports['linden_inventory']:getPlayerSlot(xPlayer, i)
        if tablelength(slot) ~= 0 then
            if slot.name == 'car_keys' then
                if slot.metadata.plate == _plate then
                    found = true
                    cb(true)
                end
            end
        end
    end
    if not found then
        cb(false)
    end
end)

ESX.RegisterServerCallback('Boost-Locksystem:IsCarRegistered', function(source, cb, _plate)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', 
    {['@plate'] = _plate}, 
    function(result)
        if result[1] ~= nil then
            cb(true)
        else
            cb(false)
        end
    end)
end)

RegisterNetEvent('Boost-Locksystem:AddKeys')
AddEventHandler('Boost-Locksystem:AddKeys', function(_plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem('car_keys', {plate = _plate}).count > 0 then
        return
    end
    searchedVeh[_plate] = true
    TriggerEvent('Boost-Locksystem:Refresh')
    xPlayer.addInventoryItem('car_keys', 1, {plate = _plate, description = _U('key_description',_plate)})
end)


RegisterNetEvent('Boost-Locksystem:CreateKeyCopy')
AddEventHandler('Boost-Locksystem:CreateKeyCopy', function(_plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getJob().name ~= 'mechanic' then
        DropPlayer(xPlayer.source, ':)')
        return
    end
    xPlayer.addInventoryItem('car_keys', 1, {plate = _plate, description = _U('key_description',_plate)})
end)


RegisterNetEvent('Boost-Locksystem:Refresh', function()
    local xPlayers = ESX.GetPlayers()
    local found = 0
    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        for i=1, 50 do
            local slot = exports['linden_inventory']:getPlayerSlot(xPlayer, i)
            if tablelength(slot) ~= 0 then
                if slot.name == 'car_keys' then
                    searchedVeh[slot.metadata.plate] = true
                    found = found + 1
                end
            end
        end
    end
    print('[^6Boost-Locksystem^0] Refreshed ' .. found .. ' searched vehicles !')
    TriggerClientEvent('Boost-Locksystem:SetUpSearched', -1, searchedVeh)
end)

RegisterNetEvent('Boost-Locksystem:SyncEngine', function(_plate, state)
    startedEngine[_plate] = state
    print('[^6Boost-Locksystem^0] Synced ' .. tablelength(startedEngine) .. ' engines !')
    TriggerClientEvent('Boost-Locksystem:SetUpEngine', -1, startedEngine)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    Wait(500)
    TriggerEvent('Boost-Locksystem:Refresh')
end)
  
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end