local searchedVeh = {}
local startedEngine = {}
local searchedFile
local ox_inventory = exports.ox_inventory

ESX.RegisterServerCallback('Boost-Locksystem:HasKeys', function(source, cb, _plate)
    cb(HasKeys(source, _plate))    
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

RegisterServerEvent('Boost-Locksystem:AddKeys', function(_plate)
    local _source = source
    if HasKeys(_source, _plate) then
        return
    end
    searchedVeh[_plate] = true
    TriggerEvent('Boost-Locksystem:Refresh')
    if ox_inventory:CanCarryItem(_source, 'car_keys', 1) then
        ox_inventory:AddItem(_source, 'car_keys', 1, {plate = _plate, description = _U('key_description',_plate)})
    end
end)

RegisterServerEvent('Boost-Locksystem:CreateKeyCopy', function(_plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getJob().name ~= 'mechanic' then
        DropPlayer(xPlayer.source, ':)')
        return
    end
    if ox_inventory:CanCarryItem(xPlayer.source, 'car_keys', 1) then
        ox_inventory:AddItem(xPlayer.source, 'car_keys', 1, {plate = _plate, description = _U('key_description',_plate)})
    end
end)

RegisterServerEvent('Boost-Locksystem:RemoveKey', function(_plate)
    HasKeys(source, _plate, true)
end)

RegisterServerEvent('Boost-Locksystem:Refresh', function()
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

RegisterServerEvent('Boost-Locksystem:SyncEngine', function(_plate, state)
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

HasKeys = function(source, plate, remove)
    local keys = ox_inventory:Search(source, 'slots', 'car_keys')
    for k,v in pairs(keys) do
        if v.metadata.plate == plate then
            if remove then
                ox_inventory:RemoveItem(source, 'car_keys', v.slot)
                return true
            else
                return true
            end
        end
    end

    return false
end
  
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end
