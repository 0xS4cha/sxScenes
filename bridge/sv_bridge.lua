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

function Bridge.HasIllegals()
    local resource = Config.Integrations.sxIllegals
    return resource and GetResourceState(resource) == 'started' or false
end

local function callIllegals(name, ...)
    if not Bridge.HasIllegals() then return nil end

    local resource = Config.Integrations.sxIllegals
    local ok, a, b = pcall(function(...)
        local proxy = exports[resource]
        return proxy[name](proxy, ...)
    end, ...)

    if not ok then
        Logger:warn('BRIDGE', 'sxIllegals export', name, 'failed:', a)
        return nil
    end
    return a, b
end

local function groupColor(group)
    local rgb = group.rgb or {}
    return ('rgb(%d, %d, %d)'):format(tonumber(rgb.r) or 255, tonumber(rgb.g) or 255, tonumber(rgb.b) or 255)
end

local function serializeGroup(group)
    if not group then return nil end
    return { id = tostring(group.id), name = group.name or tostring(group.id), color = groupColor(group) }
end

function Bridge.GetIllegalGroup(source)
    local group = callIllegals('GetPlayerGroup', source)
    if not group then return nil end

    local grade = callIllegals('GetPlayerGrade', source)
    return serializeGroup(group), tonumber(grade) or 999
end

function Bridge.GetIllegalGroupById(id)
    if not id then return nil end
    return serializeGroup(callIllegals('GetGroup', tonumber(id) or id))
end

function Bridge.GetIllegalGroups()
    local result = {}
    for _, group in ipairs(callIllegals('GetGroups') or {}) do
        result[#result + 1] = serializeGroup(group)
    end
    table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
    return result
end

function Bridge.SendGroupAlert(groupId, title, message, coords)
    callIllegals('SendGroupAlert', tonumber(groupId) or groupId, title, message, coords)
end

local territoryCache = { time = 0, list = {} }

local function getTerritories()
    if GetGameTimer() - territoryCache.time < 10000 then return territoryCache.list end
    territoryCache.time = GetGameTimer()
    territoryCache.list = callIllegals('GetTerritories') or {}
    return territoryCache.list
end

local function isInsidePolygon(point, polygon)
    if type(polygon) ~= 'table' or #polygon < 3 then return false end

    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y
        if ((yi > point.y) ~= (yj > point.y)) and (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

function Bridge.ClearTerritoryCache()
    territoryCache.time = 0
end

function Bridge.GetTerritoryAt(coords)
    if not coords then return nil end
    for _, territory in ipairs(getTerritories()) do
        if isInsidePolygon(coords, territory.coords) then
            return { id = tostring(territory.id), label = territory.label or tostring(territory.id) }
        end
    end
    return nil
end

function Bridge.GetTerritoryOwner(territoryId)
    local owner = callIllegals('GetTerritoryOwner', tonumber(territoryId) or territoryId)
    return owner and owner.groupId and tostring(owner.groupId) or nil
end
