local searchedVeh = {}
local startedEngine = {}
local searchedFile

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

RegisterNetEvent('Boost-Locksystem:RemoveKey')
AddEventHandler('Boost-Locksystem:RemoveKey', function(_plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getInventoryItem('car_keys', {plate = _plate, description = _U('key_description', _plate)}).count > 0 then
        xPlayer.removeInventoryItem('car_keys', 1, {plate = _plate, description = _U('key_description', _plate)})
    end
end)

RegisterNetEvent('Boost-Locksystem:Refresh', function()
    if tablelength(searchedVeh) < 1 then
        searchedFile = LoadResourceFile(GetCurrentResourceName(), './searchedVeh.json')
        searchedVeh = json.decode(searchedFile)
        print('[^6Boost-Locksystem^0] Refreshed ' .. tablelength(json.decode(searchedFile)) .. ' searched vehicles !')
        TriggerClientEvent('Boost-Locksystem:SetUpSearched', -1, searchedVeh)
    else
        searchedFile = LoadResourceFile(GetCurrentResourceName(), './searchedVeh.json')
        SaveResourceFile(GetCurrentResourceName(), 'searchedVeh.json', json.encode(searchedVeh), -1)
        print('[^6Boost-Locksystem^0] Refreshed ' .. tablelength(json.decode(searchedFile)) .. ' searched vehicles !')
        TriggerClientEvent('Boost-Locksystem:SetUpSearched', -1, searchedVeh)
    end
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
