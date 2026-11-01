local function serialize(scene)
    return scene and SerializeScene(scene, true) or nil
end

exports("GetScene", function(id)
    return serialize(GetScene(id))
end)

exports("GetScenes", function()
    local list = {}
    for _, scene in pairs(GetScenes()) do
        list[#list + 1] = serialize(scene)
    end
    return list
end)

exports("GetPlayerScenes", function(target)
    local identifier = type(target) == 'number' and Bridge.GetIdentifier(target) or target
    local list = {}
    for _, scene in ipairs(identifier and GetOwnerScenes(identifier) or {}) do
        list[#list + 1] = serialize(scene)
    end
    return list
end)

exports("GetGroupScenes", function(groupId)
    local list = {}
    for _, scene in ipairs(GetGroupScenes(groupId)) do
        list[#list + 1] = serialize(scene)
    end
    return list
end)

exports("CreateScene", function(owner, label, props, public, options)
    options = type(options) == 'table' and options or {}
    local identifier, name = owner, owner
    local bucket = options.bucket
    if type(owner) == 'number' then
        identifier = Bridge.GetIdentifier(owner)
        name = Bridge.GetPlayerName(owner)
        bucket = bucket or GetPlayerRoutingBucket(owner)
    end
    if type(identifier) ~= 'string' then return nil, 'invalid_owner' end

    local group = nil
    if options.group then
        group = Bridge.GetIllegalGroupById(options.group)
        if not group then return nil, 'no_group' end
    end

    local scene, err = CreateScene({ label = label, owner = identifier, ownerName = name, props = props, public = public, group = group, bucket = bucket })
    return scene and scene.id or nil, err
end)

exports("SetSceneGroup", function(id, groupId)
    local group = false
    if groupId then
        group = Bridge.GetIllegalGroupById(groupId)
        if not group then return false, 'no_group' end
    end
    local scene, err = UpdateScene(id, { group = group })
    return scene ~= nil, err
end)

exports("SetSceneBucket", function(id, bucket)
    local scene, err = UpdateScene(id, { bucket = tonumber(bucket) or 0 })
    return scene ~= nil, err
end)

exports("GetSceneTerritory", function(id)
    local scene = GetScene(id)
    return scene and scene.territory and { id = scene.territory, label = scene.territoryLabel } or nil
end)

exports("GetScenePermissions", function(source, id)
    local scene = GetScene(id)
    return scene and GetScenePermissions(source, scene) or nil
end)

exports("UpdateScene", function(id, data)
    if type(data) ~= 'table' then return false, 'invalid_data' end
    local scene, err = UpdateScene(id, { label = data.label, props = data.props, public = data.public })
    return scene ~= nil, err
end)

exports("SetScenePublic", function(id, public)
    local scene, err = UpdateScene(id, { public = public == true })
    return scene ~= nil, err
end)

exports("DeleteScene", function(id)
    return (DeleteScene(id))
end)

exports("IsModelAllowed", function(model)
    return Catalog.IsAllowed(model)
end)

exports("IsAdmin", function(source)
    return Bridge.IsAdmin(source)
end)
