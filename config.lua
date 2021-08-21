Config = {}
Config.OnlyRegisteredCars = true -- If true only cars in owned_vehicles table could be searched for key
Config.UseProgressBar = true
Config.LockStateLocked = 4 		-- Add the lockstate you use for example 4 or 2
Config.Locale = 'en'


function Notification(type, text)
    if type == 'success' then
        exports.bulletin:SendSuccess(text, 3000, 'bottomleft', true)
    elseif type == 'error' then
        exports.bulletin:SendError(text, 3000, 'bottomleft', true)
    elseif type == 'info' then
        exports.bulletin:SendInfo(text, 3000, 'bottomleft', true)
    end
end

function Progress(text,time)
    if Config.UseProgressBar then
        exports.rprogress:Start(text, 1500)
    end
end