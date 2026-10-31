exports("OpenScenes", function()
    CreateThread(function()
        SX.Scenes:Open()
    end)
end)

exports("OpenAdminPanel", function()
    CreateThread(function()
        SX.Admin:Open()
    end)
end)

exports("EditScene", function(id)
    CreateThread(function()
        SX.Scenes:Edit(id)
    end)
end)

exports("IsEditing", function()
    return SX.Editor:IsEditing()
end)

exports("StopEditing", function()
    SX.UI:Close()
    SX.Editor:Stop()
end)

exports("ShowScene", function(id)
    local result = TriggerServerCallback('sxScenes:getScene', id)
    if not result or not result.ok then return false end
    SX.Stream:Show(result.data)
    return true
end)

exports("HideScene", function(id)
    SX.Stream:Hide(id)
end)

exports("GetSceneEntities", function(id)
    return SX.Stream:GetEntities(id)
end)

exports("UseGizmo", function(entity)
    local confirmed = SX.Gizmo:Edit(entity)
    if not DoesEntityExist(entity) then return confirmed end

    local coords = GetEntityCoords(entity)
    local rotation = GetEntityRotation(entity, 2)
    return confirmed, coords, rotation
end)
