SX.Scenes = {}
SX.Modules:Register("Scenes", 40)

local function serverCall(name, ...)
    return TriggerServerCallback(name, ...) or { ok = false, error = 'timeout' }
end

local function fetchScene(id)
    local result = serverCall('sxScenes:getScene', id)
    return result.ok and result.data or nil, result.error
end

local function playerData()
    local data = serverCall('sxScenes:getPlayerData')
    if not data.ok then return data end

    data.shown = SX.Stream:GetShown()
    data.editing = SX.Editor:GetSceneId()
    return data
end

function SX.Scenes:Open()
    if SX.Editor:IsEditing() then
        SX.UI:Open('editor')
        return
    end

    local data = playerData()
    if not data.ok then
        Bridge.Notify(GetPhrase('error_' .. tostring(data.error)), 'error')
        return
    end

    SX.UI:Open('scenes')
end

function SX.Scenes:Edit(id)
    local scene, err = fetchScene(id)
    local started = false
    if scene then started, err = SX.Editor:Start(scene) end
    if not started then
        Bridge.Notify(GetPhrase('error_' .. tostring(err or 'unknown')), 'error')
        return { ok = false, error = err }
    end
    return { ok = true }
end

function SX.Scenes:Initialize()
    RegisterCommand('scenes', function()
        CreateThread(function() self:Open() end)
    end, false)
    RegisterKeyMapping('scenes', GetPhrase('keymap_scenes'), 'keyboard', Config.Keys.scenes)

    RegisterNUICallback('getScenesData', function(_, cb)
        cb(playerData())
    end)

    RegisterNUICallback('sceneCreate', function(data, cb)
        cb(serverCall('sxScenes:create', data and data.label, data and data.group == true))
    end)

    RegisterNUICallback('sceneImport', function(data, cb)
        cb(serverCall('sxScenes:import', data and data.code, data and data.group == true))
    end)

    RegisterNUICallback('sceneDelete', function(data, cb)
        local id = data and data.id
        local result = serverCall('sxScenes:delete', id)
        if result.ok then SX.Stream:Hide(id) end
        cb(result)
    end)

    RegisterNUICallback('scenePublish', function(data, cb)
        cb(serverCall('sxScenes:setPublic', data and data.id, data and data.public == true))
    end)

    RegisterNUICallback('sceneShow', function(data, cb)
        local id = data and data.id
        if data and data.shown then
            local scene, err = fetchScene(id)
            if not scene then
                cb({ ok = false, error = err })
                return
            end
            SX.Stream:Show(scene)
        else
            SX.Stream:Hide(id)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('sceneEdit', function(data, cb)
        local id = data and data.id
        cb({ ok = true })
        CreateThread(function()
            SX.Scenes:Edit(id)
        end)
    end)
end
