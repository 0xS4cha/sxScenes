SX.Scenes = {}
SX.Modules:Register("Scenes", 20)

local Scenes = {}
local cooldowns = {}

local function generateId()
    local id
    repeat
        id = 'SCN-' .. Generate.Code({ includeNumbers = true, includeLetters = true, length = 6 }):upper()
    until not Scenes[id]
    return id
end

local function toNumber(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

local function toVector(input)
    local kind = type(input)
    if kind ~= 'table' and kind ~= 'vector3' and kind ~= 'vector4' then return nil end
    local x, y, z = toNumber(input.x), toNumber(input.y), toNumber(input.z)
    if not x or not y or not z then return nil end
    return { x = Utils.Round(x, 3), y = Utils.Round(y, 3), z = Utils.Round(z, 3) }
end

local function distance(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

local function computeCenter(props)
    local x, y, z = 0.0, 0.0, 0.0
    for _, prop in ipairs(props) do
        x, y, z = x + prop.coords.x, y + prop.coords.y, z + prop.coords.z
    end
    local count = #props
    return { x = Utils.Round(x / count), y = Utils.Round(y / count), z = Utils.Round(z / count) }
end

local function playerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return Utils.ToCoords(GetEntityCoords(ped))
end

local function sanitizeLabel(label)
    label = Utils.Trim(type(label) == 'string' and label or '')
    if label == '' then return nil, 'missing_label' end
    return label:sub(1, Config.Limits.labelLength)
end

function SanitizeProps(input)
    if type(input) ~= 'table' then return nil, 'invalid_data' end

    local props = {}
    for _, entry in ipairs(input) do
        if type(entry) ~= 'table' then return nil, 'invalid_data' end

        local model = Catalog.NormalizeModel(entry.model)
        if not model or not Catalog.IsAllowed(model) then return nil, 'invalid_model' end

        local coords = toVector(entry.coords)
        local rotation = toVector(entry.rotation) or { x = 0.0, y = 0.0, z = 0.0 }
        if not coords then return nil, 'invalid_data' end

        props[#props + 1] = {
            model = model,
            coords = coords,
            rotation = rotation,
            collision = entry.collision ~= false,
        }

        if #props > Config.Limits.props then return nil, 'too_many_props' end
    end

    if #props == 0 then return props, nil, nil end

    local center = computeCenter(props)
    for _, prop in ipairs(props) do
        if distance(prop.coords, center) > Config.Limits.radius then
            return nil, 'too_spread'
        end
    end

    return props, nil, center
end

local function toClient(scene)
    return {
        id = scene.id,
        label = scene.label,
        ownerName = scene.ownerName,
        public = scene.public,
        center = scene.center,
        props = scene.props,
        group = scene.group and { id = scene.group, name = scene.groupName or scene.group, color = scene.groupColor } or nil,
        territory = scene.territory and { id = scene.territory, label = scene.territoryLabel or scene.territory } or nil,
        bucket = scene.bucket or 0,
        created = scene.created,
        updated = scene.updated,
        revision = scene.revision,
    }
end

function SerializeScene(scene, withOwner)
    local data = toClient(scene)
    if withOwner then data.owner = scene.owner end
    return data
end

local function broadcast(scene, previous)
    if scene and scene.public and Config.Public.enabled then
        TriggerClientEvent('sxScenes:sync', -1, toClient(scene))
    elseif previous then
        TriggerClientEvent('sxScenes:unpublish', -1, previous)
    end
end

local function persist(scene)
    scene.updated = os.time()
    scene.revision = (scene.revision or 0) + 1
    Storage.Save('scenes', scene.id, scene)
end

function GetScene(id)
    return Scenes[id]
end

function GetScenes()
    return Scenes
end

local function sortByCreation(list)
    table.sort(list, function(a, b) return (a.created or 0) < (b.created or 0) end)
    return list
end

function GetOwnerScenes(identifier)
    local list = {}
    for _, scene in pairs(Scenes) do
        if scene.owner == identifier and not scene.group then
            list[#list + 1] = scene
        end
    end
    return sortByCreation(list)
end

function GetGroupScenes(groupId)
    local list = {}
    if not groupId then return list end
    groupId = tostring(groupId)
    for _, scene in pairs(Scenes) do
        if scene.group == groupId then
            list[#list + 1] = scene
        end
    end
    return sortByCreation(list)
end

local function applyGroup(scene, group)
    if group then
        scene.group = tostring(group.id)
        scene.groupName = group.name
        scene.groupColor = group.color
    else
        scene.group = nil
        scene.groupName = nil
        scene.groupColor = nil
    end
end

local function territoriesEnabled()
    return Config.Territories.enabled and Bridge.HasIllegals()
end

function GetTerritoryAt(center)
    if not territoriesEnabled() or not center then return nil end
    return Bridge.GetTerritoryAt(center)
end

local function applyTerritory(scene, territory)
    scene.territory = territory and territory.id or nil
    scene.territoryLabel = territory and territory.label or nil
end

function CanPublishInTerritory(source, territory, groupId)
    if not territory or not territoriesEnabled() or not Config.Territories.requireOwner then return true end
    if source and Bridge.IsAdmin(source) then return true end

    local owner = Bridge.GetTerritoryOwner(territory.id)
    return owner == nil or owner == groupId
end

function CountPublicScenes()
    local count = 0
    for _, scene in pairs(Scenes) do
        if scene.public then count = count + 1 end
    end
    return count
end

function CreateScene(data)
    local label, err = sanitizeLabel(data.label)
    if not label then return nil, err end

    local props, propsErr, center = SanitizeProps(data.props or {})
    if not props then return nil, propsErr end

    local scene = {
        id = generateId(),
        label = label,
        owner = data.owner,
        ownerName = data.ownerName or data.owner,
        public = data.public == true and Config.Public.enabled,
        props = props,
        center = center or Utils.ToCoords(data.center) or { x = 0.0, y = 0.0, z = 0.0 },
        bucket = math.floor(tonumber(data.bucket) or 0),
        created = os.time(),
    }
    applyGroup(scene, data.group)
    applyTerritory(scene, #props > 0 and GetTerritoryAt(scene.center) or nil)

    Scenes[scene.id] = scene
    persist(scene)
    broadcast(scene)
    TriggerEvent('sxScenes:sceneCreated', SerializeScene(scene, true))
    return scene
end

function UpdateScene(id, data)
    local scene = Scenes[id]
    if not scene then return nil, 'not_found' end

    local label = scene.label
    if data.label ~= nil then
        local err
        label, err = sanitizeLabel(data.label)
        if not label then return nil, err end
    end

    local props, center = scene.props, scene.center
    local territoryChanged = false
    if data.props ~= nil then
        local err, newCenter
        props, err, newCenter = SanitizeProps(data.props)
        if not props then return nil, err end
        center = newCenter or center
        territoryChanged = true
    end

    local wasPublic = scene.public
    scene.label = label
    scene.props = props
    scene.center = center
    if data.public ~= nil then
        scene.public = data.public == true and Config.Public.enabled
    end
    if data.group ~= nil then
        applyGroup(scene, data.group or nil)
    end
    if data.bucket ~= nil then
        scene.bucket = math.floor(tonumber(data.bucket) or 0)
    end
    if territoryChanged then
        applyTerritory(scene, #props > 0 and GetTerritoryAt(center) or nil)
    elseif data.territory ~= nil then
        applyTerritory(scene, data.territory or nil)
    end

    persist(scene)
    broadcast(scene, wasPublic and not scene.public and scene.id or nil)
    TriggerEvent('sxScenes:sceneUpdated', SerializeScene(scene, true))
    return scene
end

function DeleteScene(id)
    local scene = Scenes[id]
    if not scene then return false end

    Scenes[id] = nil
    Storage.Delete('scenes', id)
    TriggerClientEvent('sxScenes:remove', -1, id)
    TriggerEvent('sxScenes:sceneDeleted', SerializeScene(scene, true))
    return true, scene
end

local function respond(ok, payload)
    if ok then return { ok = true, data = payload } end
    return { ok = false, error = payload }
end

local function onCooldown(source)
    local now = GetGameTimer()
    if cooldowns[source] and now - cooldowns[source] < 500 then return true end
    cooldowns[source] = now
    return false
end

local function canPublish(source)
    if not Config.Public.enabled then return false end
    return Config.Public.playersCanPublish or Bridge.IsAdmin(source)
end

local function groupsEnabled()
    return Config.Groups.enabled and Bridge.HasIllegals()
end

local function playerGroup(source)
    if not groupsEnabled() then return nil, nil, nil end
    return Bridge.GetIllegalGroup(source)
end

local GROUP_PERMISSIONS = {
    { key = 'canCreateScenes', grade = 'createGrade' },
    { key = 'canEditScenes', grade = 'editGrade' },
    { key = 'canPublishScenes', grade = 'publishGrade' },
    { key = 'canDeleteScenes', grade = 'deleteGrade' },
}

local function groupAllowed(grade, perms, key, threshold)
    if grade == 0 then return true end
    if Config.Groups.rankPermissions and type(perms) == 'table' and perms[key] ~= nil then
        return perms[key] == true
    end
    return grade <= Config.Groups[threshold]
end

function RegisterScenePermissions()
    if not groupsEnabled() or not Config.Groups.rankPermissions then return false end

    local list = {}
    for _, entry in ipairs(GROUP_PERMISSIONS) do
        list[#list + 1] = { key = entry.key, label = GetPhrase('group_perm_' .. entry.key) }
    end
    return Bridge.RegisterGroupPermissions(list)
end

function GetScenePermissions(source, scene)
    if Bridge.IsAdmin(source) then
        return { view = true, edit = true, publish = Config.Public.enabled, delete = true }
    end

    if not scene.group then
        local owner = scene.owner == Bridge.GetIdentifier(source)
        return { view = owner, edit = owner, publish = owner and canPublish(source), delete = owner }
    end

    local group, grade, perms = playerGroup(source)
    if not group or group.id ~= scene.group then
        return { view = false, edit = false, publish = false, delete = false }
    end

    return {
        view = true,
        edit = groupAllowed(grade, perms, 'canEditScenes', 'editGrade'),
        publish = groupAllowed(grade, perms, 'canPublishScenes', 'publishGrade') and canPublish(source),
        delete = groupAllowed(grade, perms, 'canDeleteScenes', 'deleteGrade'),
    }
end

local function canManage(source, scene)
    return GetScenePermissions(source, scene).edit
end

local function playerBucket(source)
    return GetPlayerRoutingBucket(source) or 0
end

local function inSameBucket(source, scene)
    if not Config.Buckets.enabled or Bridge.IsAdmin(source) then return true end
    return playerBucket(source) == (scene.bucket or 0)
end

local function isNear(source, scene)
    if Bridge.IsAdmin(source) or #scene.props == 0 then return true end
    local coords = playerCoords(source)
    return coords ~= nil and distance(coords, scene.center) <= Config.Limits.editDistance
end

local function playerCallback(name, handler)
    RegisterServerCallback(name, function(source, ...)
        if not Bridge.GetIdentifier(source) then return respond(false, 'not_loaded') end
        if onCooldown(source) then return respond(false, 'cooldown') end
        return handler(source, ...)
    end)
end

local function withPermissions(source, scene)
    local data = toClient(scene)
    data.permissions = GetScenePermissions(source, scene)
    return data
end

local function groupData(source)
    local group, grade, perms = playerGroup(source)
    if not group then return { available = groupsEnabled() } end

    return {
        available = true,
        group = group,
        grade = grade,
        canCreate = groupAllowed(grade, perms, 'canCreateScenes', 'createGrade') and Bridge.CanCreate(source),
        count = #GetGroupScenes(group.id),
        limit = Config.Groups.scenes,
    }
end

local function playerData(source)
    local identifier = Bridge.GetIdentifier(source)
    local list = {}
    for _, scene in ipairs(GetOwnerScenes(identifier)) do
        list[#list + 1] = withPermissions(source, scene)
    end

    local groups = groupData(source)
    if groups.group then
        for _, scene in ipairs(GetGroupScenes(groups.group.id)) do
            list[#list + 1] = withPermissions(source, scene)
        end
    end

    return {
        groups = groups,
        ok = true,
        scenes = list,
        canCreate = Bridge.CanCreate(source),
        canPublish = canPublish(source),
        sharing = Config.Sharing,
        isAdmin = Bridge.IsAdmin(source),
        limits = {
            scenes = Config.Limits.scenes,
            props = Config.Limits.props,
            radius = Config.Limits.radius,
            labelLength = Config.Limits.labelLength,
        },
        customModels = Config.Catalog.customModels,
    }
end

local function ownsTooMany(source)
    if Bridge.IsAdmin(source) then return false end
    return #GetOwnerScenes(Bridge.GetIdentifier(source)) >= Config.Limits.scenes
end

local function resolveTarget(source, asGroup)
    if not asGroup then
        if ownsTooMany(source) then return nil, 'scene_limit' end
        return false
    end

    local group, grade, perms = playerGroup(source)
    if not group then return nil, 'no_group' end
    if not groupAllowed(grade, perms, 'canCreateScenes', 'createGrade') then return nil, 'no_permission' end
    if not Bridge.IsAdmin(source) and #GetGroupScenes(group.id) >= Config.Groups.scenes then return nil, 'group_scene_limit' end
    return group
end

function SX.Scenes:Initialize()
    RegisterServerCallback('sxScenes:getPublic', function()
        local list = {}
        if Config.Public.enabled then
            for _, scene in pairs(Scenes) do
                if scene.public then list[#list + 1] = toClient(scene) end
            end
        end
        return list
    end)

    RegisterServerCallback('sxScenes:getPlayerData', function(source)
        if not Bridge.GetIdentifier(source) then return respond(false, 'not_loaded') end
        return playerData(source)
    end)

    RegisterServerCallback('sxScenes:getScene', function(source, id)
        local scene = Scenes[id]
        if not scene or not (scene.public or GetScenePermissions(source, scene).view) then return respond(false, 'not_found') end
        local data = toClient(scene)
        data.bypass = Bridge.IsAdmin(source)
        return respond(true, data)
    end)

    playerCallback('sxScenes:create', function(source, label, asGroup)
        if not Bridge.CanCreate(source) then return respond(false, 'no_permission') end
        local group, targetErr = resolveTarget(source, asGroup == true)
        if group == nil then return respond(false, targetErr) end

        local scene, err = CreateScene({
            label = label,
            owner = Bridge.GetIdentifier(source),
            ownerName = Bridge.GetPlayerName(source),
            center = playerCoords(source),
            group = group or nil,
            bucket = playerBucket(source),
        })
        if not scene then return respond(false, err) end

        Activity.Add('scene_created', source, { name = scene.label, id = scene.id, group = scene.groupName })
        return respond(true, withPermissions(source, scene))
    end)

    playerCallback('sxScenes:save', function(source, id, payload)
        local scene = Scenes[id]
        if not scene then return respond(false, 'not_found') end
        if not canManage(source, scene) then return respond(false, 'no_permission') end
        if type(payload) ~= 'table' then return respond(false, 'invalid_data') end
        if not isNear(source, scene) then return respond(false, 'too_far') end
        if not inSameBucket(source, scene) then return respond(false, 'wrong_instance') end

        if scene.public and payload.props ~= nil then
            local props, err, center = SanitizeProps(payload.props)
            if not props then return respond(false, err) end
            if center and not CanPublishInTerritory(source, GetTerritoryAt(center), scene.group) then
                return respond(false, 'territory_owned')
            end
        end

        local updated, err = UpdateScene(id, { label = payload.label, props = payload.props })
        if not updated then return respond(false, err) end

        Activity.Add('scene_updated', source, { name = updated.label, id = updated.id, props = #updated.props })
        return respond(true, withPermissions(source, updated))
    end)

    playerCallback('sxScenes:setPublic', function(source, id, public)
        local scene = Scenes[id]
        if not scene then return respond(false, 'not_found') end
        if not GetScenePermissions(source, scene).publish then return respond(false, 'no_permission') end
        if public == true and not CanPublishInTerritory(source, scene.territory and { id = scene.territory } or nil, scene.group) then
            return respond(false, 'territory_owned')
        end

        local updated = UpdateScene(id, { public = public == true })
        Activity.Add(updated.public and 'scene_published' or 'scene_unpublished', source, { name = updated.label, id = updated.id })
        return respond(true, withPermissions(source, updated))
    end)

    playerCallback('sxScenes:delete', function(source, id)
        local scene = Scenes[id]
        if not scene then return respond(false, 'not_found') end
        if not GetScenePermissions(source, scene).delete then return respond(false, 'no_permission') end

        DeleteScene(id)
        Activity.Add('scene_deleted', source, { name = scene.label, id = scene.id })
        return respond(true)
    end)

    playerCallback('sxScenes:import', function(source, code, asGroup)
        if not Config.Sharing then return respond(false, 'no_permission') end
        if not Bridge.CanCreate(source) then return respond(false, 'no_permission') end
        local group, targetErr = resolveTarget(source, asGroup == true)
        if group == nil then return respond(false, targetErr) end

        code = Utils.Trim(type(code) == 'string' and code or ''):upper()
        local original = Scenes[code] or Scenes['SCN-' .. code]
        if not original then return respond(false, 'not_found') end

        local scene, err = CreateScene({
            label = original.label,
            owner = Bridge.GetIdentifier(source),
            ownerName = Bridge.GetPlayerName(source),
            props = Utils.DeepCopy(original.props),
            center = original.center,
            group = group or nil,
            bucket = playerBucket(source),
        })
        if not scene then return respond(false, err) end

        Activity.Add('scene_imported', source, { name = scene.label, id = scene.id, from = original.id, group = scene.groupName })
        return respond(true, withPermissions(source, scene))
    end)

    AddEventHandler('playerDropped', function()
        cooldowns[source] = nil
    end)

    local function onTerritoryLost(territoryId, previous, nextOwner)
        if not territoriesEnabled() or not previous then return end
        Bridge.ClearTerritoryCache()

        territoryId, previous = tostring(territoryId), tostring(previous)
        local mode = Config.Territories.onLoss
        if mode == 'keep' then return end

        local affected, label = 0, territoryId
        for _, scene in pairs(Scenes) do
            if scene.public and scene.territory == territoryId and scene.group == previous then
                label = scene.territoryLabel or label
                affected = affected + 1
                local newGroup = mode == 'transfer' and nextOwner and Bridge.GetIllegalGroupById(nextOwner)
                if mode == 'delete' then
                    DeleteScene(scene.id)
                elseif newGroup then
                    UpdateScene(scene.id, { group = newGroup })
                else
                    UpdateScene(scene.id, { public = false })
                end
            end
        end

        if affected == 0 then return end
        local applied = (mode == 'transfer' and not nextOwner) and 'hide' or mode
        Bridge.SendGroupAlert(previous, GetPhrase('alert_territory_lost_title'), GetPhrase('alert_territory_lost_' .. applied, affected, label))
        Activity.Add('territory_lost', 0, { territory = label, count = affected, mode = applied })
    end

    AddEventHandler('sxIllegals:territoryCaptured', function(territoryId, attacker, defender)
        onTerritoryLost(territoryId, defender, attacker)
    end)

    AddEventHandler('sxIllegals:territoryLostByDecay', function(territoryId, previousOwner, newOwner)
        onTerritoryLost(territoryId, previousOwner, newOwner)
    end)

    AddEventHandler('sxIllegals:territoryCreated', function()
        Bridge.ClearTerritoryCache()
        RefreshSceneTerritories()
    end)

    AddEventHandler('sxIllegals:territoryUpdated', function()
        Bridge.ClearTerritoryCache()
        RefreshSceneTerritories()
    end)

    AddEventHandler('onResourceStart', function(resource)
        if resource ~= Config.Integrations.sxIllegals then return end
        Bridge.ResetIllegalsProbes()
        Bridge.ClearTerritoryCache()
        CreateThread(function()
            Wait(2000)
            RegisterScenePermissions()
            RefreshSceneTerritories()
        end)
    end)

    AddEventHandler('sxIllegals:territoryDeleted', function(territoryId)
        Bridge.ClearTerritoryCache()
        territoryId = tostring(territoryId)
        for _, scene in pairs(Scenes) do
            if scene.territory == territoryId then
                UpdateScene(scene.id, { territory = false })
            end
        end
    end)

    AddEventHandler('sxIllegals:groupDeleted', function(groupId)
        for _, scene in ipairs(GetGroupScenes(groupId)) do
            if Config.Groups.onGroupDeleted == 'delete' then
                DeleteScene(scene.id)
            else
                UpdateScene(scene.id, { group = false, public = false })
            end
        end
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        Storage.Flush()
    end)
end

function RefreshSceneTerritories()
    if not territoriesEnabled() then return 0 end

    local changed = 0
    for id, scene in pairs(Scenes) do
        local territory = #scene.props > 0 and GetTerritoryAt(scene.center) or nil
        local territoryId = territory and territory.id or nil
        if territoryId ~= scene.territory or (territory and territory.label ~= scene.territoryLabel) then
            UpdateScene(id, { territory = territory or false })
            changed = changed + 1
        end
    end

    if changed > 0 then Logger:info('SCENES', ('Updated the territory of %d scene(s)'):format(changed)) end
    return changed
end

local function syncBuckets()
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local bucket = playerBucket(source)
        local state = Player(source).state
        if state.sxScenesBucket ~= bucket then
            state:set('sxScenesBucket', bucket, true)
        end
    end
end

function SX.Scenes:InitializeAsync()
    if Config.Buckets.enabled then
        CreateThread(function()
            while true do
                syncBuckets()
                Wait(Config.Buckets.interval)
            end
        end)
    end

    Storage.Init()

    local count = 0
    for _, record in ipairs(Storage.LoadAll('scenes')) do
        if record.id and record.owner then
            record.props = record.props or {}
            record.public = record.public == true
            record.center = record.center or (#record.props > 0 and computeCenter(record.props)) or { x = 0.0, y = 0.0, z = 0.0 }
            Scenes[record.id] = record
            count = count + 1
        end
    end

    Logger:info('SCENES', ('Loaded %d scene(s)'):format(count))

    if Bridge.HasIllegals() then
        RegisterScenePermissions()
        RefreshSceneTerritories()
    end
    TriggerClientEvent('sxScenes:refresh', -1)
end
