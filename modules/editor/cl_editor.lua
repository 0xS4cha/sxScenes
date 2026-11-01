SX.Editor = {}
SX.Modules:Register("Editor", 30)

local session = nil
local preview = nil
local catalog = nil

local function notifyError(err)
    Bridge.Notify(GetPhrase('error_' .. tostring(err or 'unknown')), 'error')
end

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
end

local function readProp(prop)
    local coords = GetEntityCoords(prop.entity)
    local rotation = GetEntityRotation(prop.entity, 2)
    return {
        model = prop.model,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        rotation = { x = rotation.x, y = rotation.y, z = rotation.z },
        collision = prop.collision,
    }
end

local function serializeProps()
    local list = {}
    for index, prop in ipairs(session.props) do
        local coords = DoesEntityExist(prop.entity) and GetEntityCoords(prop.entity) or vector3(0.0, 0.0, 0.0)
        list[#list + 1] = {
            index = index,
            model = prop.model,
            collision = prop.collision,
            distance = Utils.Round(#(GetEntityCoords(PlayerPedId()) - coords), 1),
        }
    end
    return list
end

local function sceneCenter()
    local x, y, z, count = 0.0, 0.0, 0.0, 0
    for _, prop in ipairs(session.props) do
        if DoesEntityExist(prop.entity) then
            local coords = GetEntityCoords(prop.entity)
            x, y, z, count = x + coords.x, y + coords.y, z + coords.z, count + 1
        end
    end
    if count == 0 then return nil end
    return vector3(x / count, y / count, z / count)
end

local function editorState()
    return {
        id = session.scene.id,
        label = session.label,
        public = session.scene.public,
        dirty = session.dirty,
        props = serializeProps(),
        highlight = session.highlight,
        limits = { props = Config.Limits.props, radius = Config.Limits.radius },
        customModels = Config.Catalog.customModels,
    }
end

local function pushState()
    if session then SX.UI:Send('editor:update', editorState()) end
end

local function clearPreview()
    if not preview then return end
    deleteEntity(preview.entity)
    preview = nil
end

local function frontCoords(distance)
    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, distance, 0.0)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    return vector3(coords.x, coords.y, found and groundZ or coords.z - 0.9)
end

local function setPreview(model)
    clearPreview()
    if not session or not model then return end

    local token = {}
    preview = { model = model, token = token }

    CreateThread(function()
        local hash = LoadModel(model)
        if not hash or not preview or preview.token ~= token then return end

        local coords = frontCoords(Config.Editor.previewDistance)
        local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
        SetEntityCollision(entity, false, false)
        SetEntityAlpha(entity, 190, false)
        FreezeEntityPosition(entity, true)
        SetModelAsNoLongerNeeded(hash)

        if not preview or preview.token ~= token then
            deleteEntity(entity)
            return
        end
        preview.entity = entity

        local heading = GetEntityHeading(PlayerPedId())
        while preview and preview.token == token and DoesEntityExist(entity) do
            heading = (heading + 0.6) % 360.0
            SetEntityHeading(entity, heading)
            Wait(0)
        end
    end)
end

local function withGizmo(entity, onDone)
    SX.UI:Hide()
    CreateThread(function()
        local confirmed = SX.Gizmo:Edit(entity)
        if session then
            onDone(confirmed)
            SX.UI:Show()
            pushState()
        end
    end)
end

local function isTooFar(entity)
    local center = sceneCenter()
    if not center then return false end
    return #(GetEntityCoords(entity) - center) > Config.Limits.radius
end

local function addProp(model)
    if #session.props >= Config.Limits.props then return false, 'too_many_props' end

    model = Catalog.NormalizeModel(model)
    if not model or not Catalog.IsAllowed(model) then return false, 'invalid_model' end

    local hash = LoadModel(model)
    if not hash then return false, 'invalid_model' end

    local coords = preview and preview.entity and DoesEntityExist(preview.entity) and GetEntityCoords(preview.entity) or frontCoords(Config.Editor.spawnDistance)
    clearPreview()

    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, GetEntityHeading(PlayerPedId()))
    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
    SetModelAsNoLongerNeeded(hash)

    withGizmo(entity, function(confirmed)
        if not confirmed then
            deleteEntity(entity)
            return
        end
        if isTooFar(entity) then
            deleteEntity(entity)
            notifyError('too_spread')
            return
        end
        session.props[#session.props + 1] = { model = model, entity = entity, collision = true }
        session.highlight = #session.props
        session.dirty = true
    end)
    return true
end

local function editProp(index)
    local prop = session.props[index]
    if not prop or not DoesEntityExist(prop.entity) then return false, 'not_found' end

    local before = readProp(prop)
    withGizmo(prop.entity, function(confirmed)
        if not confirmed then return end
        if isTooFar(prop.entity) then
            SetEntityCoordsNoOffset(prop.entity, before.coords.x, before.coords.y, before.coords.z, false, false, false)
            SetEntityRotation(prop.entity, before.rotation.x, before.rotation.y, before.rotation.z, 2, false)
            notifyError('too_spread')
            return
        end
        session.dirty = true
    end)
    return true
end

local function duplicateProp(index)
    local prop = session.props[index]
    if not prop then return false, 'not_found' end
    if #session.props >= Config.Limits.props then return false, 'too_many_props' end

    local data = readProp(prop)
    data.coords.x = data.coords.x + 0.5
    local entity = SpawnSceneProp(data)
    if not entity then return false, 'invalid_model' end

    withGizmo(entity, function(confirmed)
        if not confirmed or isTooFar(entity) then
            deleteEntity(entity)
            if confirmed then notifyError('too_spread') end
            return
        end
        session.props[#session.props + 1] = { model = prop.model, entity = entity, collision = prop.collision }
        session.highlight = #session.props
        session.dirty = true
    end)
    return true
end

local function setHighlight(index)
    if session.highlight and session.props[session.highlight] then
        SetEntityDrawOutline(session.props[session.highlight].entity, false)
    end
    session.highlight = session.props[index] and index or nil
    if session.highlight then
        SetEntityDrawOutlineColor(255, 255, 255, 200)
        SetEntityDrawOutline(session.props[index].entity, true)
    end
end

local function endSession()
    if not session then return end

    clearPreview()
    for _, prop in ipairs(session.props) do
        deleteEntity(prop.entity)
    end

    local id = session.scene.id
    session = nil
    SX.Stream:Suppress(id, false)
    SX.UI:Send('editor:update', nil)
end

local function getCatalog()
    if catalog then return catalog end

    catalog = {}
    for _, category in ipairs(Catalog.GetCategories()) do
        local models = {}
        for _, model in ipairs(category.models) do
            if IsModelInCdimage(joaat(model)) then models[#models + 1] = model end
        end
        if #models > 0 then
            catalog[#catalog + 1] = { id = category.id, models = models }
        end
    end
    return catalog
end

function SX.Editor:IsEditing()
    return session ~= nil
end

function SX.Editor:GetSceneId()
    return session and session.scene.id or nil
end

function SX.Editor:Start(scene)
    if session or type(scene) ~= 'table' then return false end

    if Config.Buckets.enabled and not scene.bypass and (scene.bucket or 0) ~= GetCurrentBucket() then
        notifyError('wrong_instance')
        return false
    end

    if scene.props and #scene.props > 0 and scene.center then
        local center = vector3(scene.center.x, scene.center.y, scene.center.z)
        if #(GetEntityCoords(PlayerPedId()) - center) > Config.Limits.editDistance then
            notifyError('too_far')
            return false
        end
    end

    SX.UI:Close()
    SX.Stream:Suppress(scene.id, true)

    session = { scene = scene, label = scene.label, props = {}, dirty = false }
    for _, data in ipairs(scene.props or {}) do
        local entity = SpawnSceneProp(data)
        if entity then
            session.props[#session.props + 1] = { model = data.model, entity = entity, collision = data.collision ~= false }
        end
    end

    SX.UI:Open('editor')
    pushState()
    return true
end

function SX.Editor:Save()
    if not session then return { ok = false, error = 'not_found' } end

    local props = {}
    for _, prop in ipairs(session.props) do
        if DoesEntityExist(prop.entity) then props[#props + 1] = readProp(prop) end
    end

    local result = TriggerServerCallback('sxScenes:save', session.scene.id, { label = session.label, props = props }) or { ok = false, error = 'timeout' }
    if result.ok and session then
        session.scene = result.data
        session.dirty = false
        SX.Stream:Show(result.data)
        Bridge.Notify(GetPhrase('notify_scene_saved', result.data.label), 'success')
        pushState()
    end
    return result
end

function SX.Editor:Stop()
    endSession()
end

local function sessionCallback(name, handler)
    RegisterNUICallback(name, function(data, cb)
        if not session then
            cb({ ok = false, error = 'not_found' })
            return
        end
        local ok, err = handler(type(data) == 'table' and data or {})
        if ok == false then
            cb({ ok = false, error = err })
            return
        end
        cb({ ok = true, data = editorState() })
    end)
end

function SX.Editor:Initialize()
    RegisterNUICallback('getCatalog', function(_, cb)
        cb({ ok = true, data = getCatalog() })
    end)

    sessionCallback('editorPreview', function(data)
        setPreview(Catalog.NormalizeModel(data.model))
    end)

    sessionCallback('editorAdd', function(data)
        return addProp(data.model)
    end)

    sessionCallback('editorEdit', function(data)
        return editProp(tonumber(data.index))
    end)

    sessionCallback('editorDuplicate', function(data)
        return duplicateProp(tonumber(data.index))
    end)

    sessionCallback('editorDelete', function(data)
        local index = tonumber(data.index)
        local prop = session.props[index]
        if not prop then return false, 'not_found' end
        if session.highlight == index then session.highlight = nil end
        deleteEntity(prop.entity)
        table.remove(session.props, index)
        if session.highlight and session.highlight > index then session.highlight = session.highlight - 1 end
        session.dirty = true
    end)

    sessionCallback('editorCollision', function(data)
        local prop = session.props[tonumber(data.index)]
        if not prop then return false, 'not_found' end
        prop.collision = data.value == true
        session.dirty = true
    end)

    sessionCallback('editorHighlight', function(data)
        setHighlight(tonumber(data.index))
    end)

    sessionCallback('editorRename', function(data)
        local label = Utils.Trim(type(data.label) == 'string' and data.label or '')
        if label == '' then return false, 'missing_label' end
        session.label = label:sub(1, Config.Limits.labelLength)
        session.dirty = true
    end)

    RegisterNUICallback('editorSave', function(_, cb)
        local result = SX.Editor:Save()
        cb(result.ok and { ok = true, data = session and editorState() } or result)
    end)

    RegisterNUICallback('editorExit', function(_, cb)
        cb({ ok = true })
        SX.UI:Close()
    end)

    SX.UI:OnClose(function(route)
        if route == 'editor' and not SX.Gizmo:IsActive() then endSession() end
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        endSession()
    end)

    RegisterNetEvent('sxScenes:remove', function(id)
        if session and session.scene.id == id then
            endSession()
            SX.UI:Close()
            Bridge.Notify(GetPhrase('notify_scene_removed'), 'error')
        end
    end)

    CreateThread(function()
        while true do
            if session and session.highlight and SX.UI:IsOpen() then
                local prop = session.props[session.highlight]
                if prop and DoesEntityExist(prop.entity) then
                    local coords = GetEntityCoords(prop.entity)
                    local _, maximum = GetModelDimensions(GetEntityModel(prop.entity))
                    DrawMarker(20, coords.x, coords.y, coords.z + maximum.z + 0.4, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.35, 0.35, 0.35, 255, 255, 255, 180, true, true, 2, false, nil, nil, false)
                end
                Wait(0)
            else
                Wait(250)
            end
        end
    end)
end
