SX.Admin = {}
SX.Modules:Register("Admin", 50)

local function adminCall(name, ...)
    return TriggerServerCallback(name, ...) or { ok = false, error = 'timeout' }
end

local function teleport(coords)
    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end
    SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, false, false, false, false)
    Wait(400)
    DoScreenFadeIn(400)
end

function SX.Admin:Open()
    if SX.Editor:IsEditing() then
        SX.UI:Open('editor')
        return
    end

    if TriggerServerCallback('sxScenes:isAdmin') then
        SX.UI:Open('admin')
    else
        Bridge.Notify(GetPhrase('error_no_permission'), 'error')
    end
end

function SX.Admin:Initialize()
    RegisterCommand('scenesadmin', function()
        CreateThread(function() self:Open() end)
    end, false)
    RegisterKeyMapping('scenesadmin', GetPhrase('keymap_admin_panel'), 'keyboard', '')

    RegisterNUICallback('getAdminData', function(_, cb)
        local data = adminCall('sxScenes:admin:getData')
        if data.ok then data.shown = SX.Stream:GetShown() end
        cb(data)
    end)

    RegisterNUICallback('adminPublish', function(data, cb)
        cb(adminCall('sxScenes:admin:setPublic', data and data.id, data and data.public == true))
    end)

    RegisterNUICallback('adminDelete', function(data, cb)
        local result = adminCall('sxScenes:admin:delete', data and data.id)
        if result.ok then SX.Stream:Hide(data.id) end
        cb(result)
    end)

    RegisterNUICallback('adminClearOwner', function(data, cb)
        cb(adminCall('sxScenes:admin:clearOwner', data and data.identifier))
    end)

    RegisterNUICallback('teleport', function(data, cb)
        cb({ ok = true })
        if data and data.x then
            SX.UI:Close()
            CreateThread(function() teleport(data) end)
        end
    end)
end
