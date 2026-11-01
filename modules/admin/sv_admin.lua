SX.Admin = {}
SX.Modules:Register("Admin", 40)

local function adminCallback(name, handler)
    RegisterServerCallback(name, function(source, ...)
        if not Bridge.IsAdmin(source) then
            return { ok = false, error = 'no_permission' }
        end
        return handler(source, ...)
    end)
end

local function listScenes()
    local list = {}
    for _, scene in pairs(GetScenes()) do
        list[#list + 1] = {
            id = scene.id,
            label = scene.label,
            owner = scene.owner,
            ownerName = scene.ownerName,
            public = scene.public,
            center = scene.center,
            props = #scene.props,
            group = scene.group and { id = scene.group, name = scene.groupName or scene.group, color = scene.groupColor } or nil,
            territory = scene.territory and { id = scene.territory, label = scene.territoryLabel or scene.territory } or nil,
            created = scene.created,
            updated = scene.updated,
        }
    end
    table.sort(list, function(a, b) return (a.updated or 0) > (b.updated or 0) end)
    return list
end

local function listPlayers()
    local list = {}
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local identifier = Bridge.GetIdentifier(source)
        list[#list + 1] = {
            id = source,
            name = Bridge.GetPlayerName(source),
            identifier = identifier,
            scenes = identifier and #GetOwnerScenes(identifier) or 0,
            admin = Bridge.IsAdmin(source),
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function countProps()
    local total = 0
    for _, scene in pairs(GetScenes()) do
        total = total + #scene.props
    end
    return total
end

local function catalogSize()
    local total = 0
    for _, category in ipairs(Catalog.GetCategories()) do
        total = total + #category.models
    end
    return total
end

function SX.Admin:Initialize()
    RegisterServerCallback('sxScenes:isAdmin', function(source)
        return Bridge.IsAdmin(source)
    end)

    adminCallback('sxScenes:admin:getData', function()
        return {
            ok = true,
            scenes = listScenes(),
            players = listPlayers(),
            activity = Activity.GetAll(),
            framework = Bridge.Name,
            storage = Storage.Name,
            stats = {
                props = countProps(),
                public = CountPublicScenes(),
                catalog = catalogSize(),
            },
            settings = {
                scenes = Config.Limits.scenes,
                props = Config.Limits.props,
                radius = Config.Limits.radius,
                streamDistance = Config.Stream.distance,
                publicEnabled = Config.Public.enabled,
                playersCanPublish = Config.Public.playersCanPublish,
                sharing = Config.Sharing,
                customModels = Config.Catalog.customModels,
                everyoneCanCreate = Config.Creator.everyone,
                groups = Config.Groups.enabled and Bridge.HasIllegals(),
                territories = Config.Territories.enabled and Bridge.HasIllegals(),
            },
        }
    end)

    adminCallback('sxScenes:admin:setPublic', function(source, id, public)
        if not GetScene(id) then return { ok = false, error = 'not_found' } end
        if not Config.Public.enabled then return { ok = false, error = 'public_disabled' } end

        local scene = UpdateScene(id, { public = public == true })
        Activity.Add('admin_publish', source, { name = scene.label, id = scene.id, public = tostring(scene.public) })
        return { ok = true }
    end)

    adminCallback('sxScenes:admin:delete', function(source, id)
        local ok, scene = DeleteScene(id)
        if not ok then return { ok = false, error = 'not_found' } end

        Activity.Add('admin_delete', source, { name = scene.label, id = scene.id, owner = scene.ownerName })
        Bridge.Notify(source, GetPhrase('notify_scene_deleted'), 'info')
        return { ok = true }
    end)

    adminCallback('sxScenes:admin:clearOwner', function(source, identifier)
        if type(identifier) ~= 'string' or identifier == '' then return { ok = false, error = 'invalid_data' } end

        local scenes = GetOwnerScenes(identifier)
        if #scenes == 0 then return { ok = false, error = 'not_found' } end

        local name = scenes[1].ownerName
        for _, scene in ipairs(scenes) do
            DeleteScene(scene.id)
        end

        Activity.Add('admin_clear', source, { owner = name, count = #scenes })
        return { ok = true }
    end)
end
