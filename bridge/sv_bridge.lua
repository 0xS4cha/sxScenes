Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil

local function detectFramework()
    if Config.Framework == 'standalone' then return 'standalone' end

    if Config.Framework == 'esx' or GetResourceState('es_extended') ~= 'missing' then
        local ok, obj = pcall(function()
            return exports.es_extended:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            return 'esx'
        end

        if Config.Framework == 'esx' then
            Logger:error('BRIDGE', "Config.Framework is 'esx' but es_extended could not be loaded")
        end
    end

    return 'standalone'
end

Bridge.Name = detectFramework()
Logger:info('BRIDGE', "Framework:", Bridge.Name)

local function getPlayer(source)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(source)
end

function Bridge.GetIdentifier(source)
    local xPlayer = getPlayer(source)
    if xPlayer and xPlayer.identifier then
        return xPlayer.identifier
    end
    if ESX then return nil end

    return GetPlayerIdentifierByType(source, 'license')
end

function Bridge.GetPlayerName(source)
    local xPlayer = getPlayer(source)
    if xPlayer and xPlayer.getName then
        local ok, name = pcall(xPlayer.getName)
        if ok and name then return name end
    end

    return GetPlayerName(source) or ('#' .. tostring(source))
end

function Bridge.IsAdmin(source)
    if not source or source <= 0 then return true end

    if Config.Admin.ace and IsPlayerAceAllowed(source, Config.Admin.ace) then
        return true
    end

    local xPlayer = getPlayer(source)
    if xPlayer then
        local group = xPlayer.getGroup and xPlayer.getGroup()
        for _, allowed in ipairs(Config.Admin.groups or {}) do
            if group == allowed then return true end
        end
    end

    return false
end

function Bridge.CanCreate(source)
    if Config.Creator.everyone then return true end
    if Config.Creator.ace and IsPlayerAceAllowed(source, Config.Creator.ace) then return true end
    return Bridge.IsAdmin(source)
end

function Bridge.Notify(source, message, kind)
    TriggerClientEvent('sxScenes:notify', source, message, kind or 'info')
end
