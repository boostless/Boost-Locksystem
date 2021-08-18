local searchedVeh = {}
local startedEngine = {}

ESX.RegisterServerCallback('Boost-Locksystem:HasKeys', function(source, cb, _plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem('car_keys', {plate = _plate, description = _U('key_description', _plate)}).count > 0 then
        cb(true)
    else
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
    if xPlayer.getInventoryItem('car_keys', {plate = _plate, description = _U('key_description', _plate)}).count > 0 then
        return
    end
    searchedVeh[_plate] = true
    TriggerClientEvent('Boost-Locksystem:SetUpSearched', -1, searchedVeh)
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

RegisterNetEvent('Boost-Locksystem:RemoveKey')
AddEventHandler('Boost-Locksystem:RemoveKey', function(_plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem('car_keys', {plate = _plate, description = _U('key_description', _plate)}).count > 0 then
        xPlayer.removeInventoryItem('car_keys', 1, {plate = _plate, description = _U('key_description', _plate)})
    end
end)

RegisterNetEvent('Boost-Locksystem:Refresh', function()
    local xPlayers = ESX.GetExtendedPlayers()
    local found = 0
    for i=1, #xPlayers, 1 do
        local xPlayer = xPlayers[i]
        local inventory = xPlayer.getInventory()
        for i=1, tablelength(inventory) do
            if inventory[i].name == 'car_keys' then
                searchedVeh[inventory[i].metadata.plate] = true
                found = found + 1
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
