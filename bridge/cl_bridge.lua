Bridge = {}

function Bridge.Notify(message, kind)
    if GetResourceState('es_extended') == 'started' and Config.Framework ~= 'standalone' then
        TriggerEvent('esx:showNotification', message, kind)
        return
    end

    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

function Bridge.ShowHelp(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

RegisterNetEvent('sxScenes:notify', function(message, kind)
    Bridge.Notify(message, kind)
end)
