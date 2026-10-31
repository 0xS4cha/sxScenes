SX.Stream = {}
SX.Modules:Register("Stream", 20)

local publicScenes = {}
local localScenes = {}
local suppressed = {}
local spawned = {}

function LoadModel(model, timeout)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    if HasModelLoaded(hash) then return hash end

    RequestModel(hash)
    local limit = GetGameTimer() + (timeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() > limit then return nil end
        Wait(0)
    end
    return hash
end

function SpawnSceneProp(prop)
    local hash = LoadModel(prop.model)
    if not hash then return nil end

    local entity = CreateObjectNoOffset(hash, prop.coords.x + 0.0, prop.coords.y + 0.0, prop.coords.z + 0.0, false, false, false)
    SetEntityRotation(entity, prop.rotation.x + 0.0, prop.rotation.y + 0.0, prop.rotation.z + 0.0, 2, false)
    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
    SetEntityCollision(entity, prop.collision ~= false, prop.collision ~= false)
    SetModelAsNoLongerNeeded(hash)
    return entity
end

local function despawn(id)
    local entry = spawned[id]
    if not entry then return end

    spawned[id] = nil
    for _, entity in ipairs(entry.entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end

local function spawn(id, scene)
    local entry = { entities = {}, version = scene.updated }
    spawned[id] = entry

    CreateThread(function()
        for _, prop in ipairs(scene.props or {}) do
            if spawned[id] ~= entry then return end
            local entity = SpawnSceneProp(prop)
            if entity then entry.entities[#entry.entities + 1] = entity end
        end

        if spawned[id] ~= entry then
            for _, entity in ipairs(entry.entities) do
                if DoesEntityExist(entity) then DeleteEntity(entity) end
            end
        end
    end)
end

local function getScene(id)
    return localScenes[id] or publicScenes[id]
end

local function update()
    local coords = GetEntityCoords(PlayerPedId())
    local seen = {}

    for _, list in ipairs({ localScenes, publicScenes }) do
        for id, scene in pairs(list) do
            if not seen[id] then
                seen[id] = true
                local center = scene.center
                local near = center and #(coords - vector3(center.x, center.y, center.z)) <= Config.Stream.distance

                if suppressed[id] or not near then
                    despawn(id)
                elseif not spawned[id] then
                    spawn(id, scene)
                elseif spawned[id].version ~= scene.updated then
                    despawn(id)
                    spawn(id, scene)
                end
            end
        end
    end

    for id in pairs(spawned) do
        if not seen[id] then despawn(id) end
    end
end

function SX.Stream:SetPublic(scene)
    if type(scene) ~= 'table' or not scene.id then return end
    publicScenes[scene.id] = scene
    if localScenes[scene.id] then localScenes[scene.id] = scene end
    update()
end

function SX.Stream:Remove(id)
    publicScenes[id] = nil
    localScenes[id] = nil
    despawn(id)
end

function SX.Stream:Show(scene)
    if type(scene) ~= 'table' or not scene.id then return end
    localScenes[scene.id] = scene
    update()
end

function SX.Stream:Hide(id)
    localScenes[id] = nil
    if not publicScenes[id] then despawn(id) end
    update()
end

function SX.Stream:IsShown(id)
    return localScenes[id] ~= nil
end

function SX.Stream:IsVisible(id)
    return getScene(id) ~= nil
end

function SX.Stream:Suppress(id, value)
    suppressed[id] = value or nil
    update()
end

function SX.Stream:GetShown()
    local list = {}
    for id in pairs(localScenes) do list[#list + 1] = id end
    return list
end

function SX.Stream:GetEntities(id)
    return spawned[id] and spawned[id].entities or {}
end

function SX.Stream:Refresh()
    publicScenes = {}
    for _, scene in ipairs(TriggerServerCallback('sxScenes:getPublic') or {}) do
        publicScenes[scene.id] = scene
    end
    update()
end

function SX.Stream:Initialize()
    RegisterNetEvent('sxScenes:sync', function(scene)
        SX.Stream:SetPublic(scene)
    end)

    RegisterNetEvent('sxScenes:remove', function(id)
        SX.Stream:Remove(id)
    end)

    RegisterNetEvent('sxScenes:unpublish', function(id)
        publicScenes[id] = nil
        update()
    end)

    RegisterNetEvent('sxScenes:refresh', function()
        SX.Stream:Refresh()
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        for id in pairs(spawned) do despawn(id) end
    end)
end

function SX.Stream:InitializeAsync()
    while not NetworkIsSessionStarted() do Wait(500) end
    self:Refresh()

    while true do
        Wait(Config.Stream.interval)
        update()
    end
end
