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
    if type(input) ~= 'table' then return nil end
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
    for _, entry in pairs(input) do
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
        created = scene.created,
        updated = scene.updated,
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
    Storage.Save('scenes', scene.id, scene)
end

function GetScene(id)
    return Scenes[id]
end

function GetScenes()
    return Scenes
end

function GetOwnerScenes(identifier)
    local list = {}
    for _, scene in pairs(Scenes) do
        if scene.owner == identifier then
            list[#list + 1] = scene
        end
    end
    table.sort(list, function(a, b) return (a.created or 0) < (b.created or 0) end)
    return list
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
        created = os.time(),
    }

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
    if data.props ~= nil then
        local err, newCenter
        props, err, newCenter = SanitizeProps(data.props)
        if not props then return nil, err end
        center = newCenter or center
    end

    local wasPublic = scene.public
    scene.label = label
    scene.props = props
    scene.center = center
    if data.public ~= nil then
        scene.public = data.public == true and Config.Public.enabled
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

local function canManage(source, scene)
    return scene.owner == Bridge.GetIdentifier(source) or Bridge.IsAdmin(source)
end

local function canPublish(source)
    if not Config.Public.enabled then return false end
    return Config.Public.playersCanPublish or Bridge.IsAdmin(source)
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

local function playerData(source)
    local identifier = Bridge.GetIdentifier(source)
    local list = {}
    for _, scene in ipairs(GetOwnerScenes(identifier)) do
        list[#list + 1] = toClient(scene)
    end

    return {
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
        if not scene or not (scene.public or canManage(source, scene)) then return respond(false, 'not_found') end
        return respond(true, toClient(scene))
    end)

    playerCallback('sxScenes:create', function(source, label)
        if not Bridge.CanCreate(source) then return respond(false, 'no_permission') end
        if ownsTooMany(source) then return respond(false, 'scene_limit') end

        local scene, err = CreateScene({
            label = label,
            owner = Bridge.GetIdentifier(source),
            ownerName = Bridge.GetPlayerName(source),
            center = playerCoords(source),
        })
        if not scene then return respond(false, err) end

        Activity.Add('scene_created', source, { name = scene.label, id = scene.id })
        return respond(true, toClient(scene))
    end)

    playerCallback('sxScenes:save', function(source, id, payload)
        local scene = Scenes[id]
        if not scene then return respond(false, 'not_found') end
        if not canManage(source, scene) then return respond(false, 'no_permission') end
        if type(payload) ~= 'table' then return respond(false, 'invalid_data') end
        if not isNear(source, scene) then return respond(false, 'too_far') end

        local updated, err = UpdateScene(id, { label = payload.label, props = payload.props })
        if not updated then return respond(false, err) end

        Activity.Add('scene_updated', source, { name = updated.label, id = updated.id, props = #updated.props })
        return respond(true, toClient(updated))
    end)

    playerCallback('sxScenes:setPublic', function(source, id, public)
        local scene = Scenes[id]
        if not scene then return respond(false, 'not_found') end
        if not canManage(source, scene) then return respond(false, 'no_permission') end
        if not canPublish(source) then return respond(false, 'no_permission') end

        local updated = UpdateScene(id, { public = public == true })
        Activity.Add(updated.public and 'scene_published' or 'scene_unpublished', source, { name = updated.label, id = updated.id })
        return respond(true, toClient(updated))
    end)

    playerCallback('sxScenes:delete', function(source, id)
        local scene = Scenes[id]
        if not scene then return respond(false, 'not_found') end
        if not canManage(source, scene) then return respond(false, 'no_permission') end

        DeleteScene(id)
        Activity.Add('scene_deleted', source, { name = scene.label, id = scene.id })
        return respond(true)
    end)

    playerCallback('sxScenes:import', function(source, code)
        if not Config.Sharing then return respond(false, 'no_permission') end
        if not Bridge.CanCreate(source) then return respond(false, 'no_permission') end
        if ownsTooMany(source) then return respond(false, 'scene_limit') end

        code = Utils.Trim(type(code) == 'string' and code or ''):upper()
        local original = Scenes[code] or Scenes['SCN-' .. code]
        if not original then return respond(false, 'not_found') end

        local scene, err = CreateScene({
            label = original.label,
            owner = Bridge.GetIdentifier(source),
            ownerName = Bridge.GetPlayerName(source),
            props = Utils.DeepCopy(original.props),
            center = original.center,
        })
        if not scene then return respond(false, err) end

        Activity.Add('scene_imported', source, { name = scene.label, id = scene.id, from = original.id })
        return respond(true, toClient(scene))
    end)

    AddEventHandler('playerDropped', function()
        cooldowns[source] = nil
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        Storage.Flush()
    end)
end

function SX.Scenes:InitializeAsync()
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
    TriggerClientEvent('sxScenes:refresh', -1)
end
