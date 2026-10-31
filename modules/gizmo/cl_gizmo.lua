SX.Gizmo = {}
SX.Modules:Register("Gizmo", 10)

local MATRIX_SIZE = 64

local state = {
    active = false,
    entity = nil,
    mode = 'translate',
    relative = false,
    result = nil,
}

local function readMatrix(entity)
    local forward, right, up, position = GetEntityMatrix(entity)
    return {
        right.x, right.y, right.z, 0.0,
        forward.x, forward.y, forward.z, 0.0,
        up.x, up.y, up.z, 0.0,
        position.x, position.y, position.z, 1.0,
    }
end

local function packMatrix(values)
    local blob = string.blob(MATRIX_SIZE)
    for i = 1, 16 do
        blob = blob:blob_pack((i - 1) * 4 + 1, '<f', values[i])
    end
    return blob
end

local function unpackMatrix(blob)
    local values = {}
    for i = 1, 16 do
        values[i] = blob:blob_unpack((i - 1) * 4 + 1, '<f')
    end
    return values
end

local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)
    if length == 0 then return 0.0, 0.0, 0.0 end
    return x / length, y / length, z / length
end

local function applyMatrix(entity, m)
    local rx, ry, rz = normalize(m[1], m[2], m[3])
    local fx, fy, fz = normalize(m[5], m[6], m[7])
    local ux, uy, uz = normalize(m[9], m[10], m[11])
    SetEntityMatrix(entity, fx, fy, fz, rx, ry, rz, ux, uy, uz, m[13], m[14], m[15])
end

local function sendOverlay()
    SX.UI:Send('gizmo', {
        active = state.active,
        mode = state.mode,
        relative = state.relative,
    })
end

local pressed = {}

local function pressGizmo(command)
    if not state.active then return end
    pressed[command] = true
    ExecuteCommand('+' .. command)
end

local function releaseGizmo(command)
    if not pressed[command] then return end
    pressed[command] = nil
    ExecuteCommand('-' .. command)
end

local function registerKey(name, key, mapper, onPress, onRelease)
    RegisterCommand('+sxscenes_gizmo_' .. name, function()
        if state.active then onPress() end
    end, false)
    RegisterCommand('-sxscenes_gizmo_' .. name, function()
        if onRelease then onRelease() end
    end, false)
    RegisterKeyMapping('+sxscenes_gizmo_' .. name, GetPhrase('keymap_gizmo_' .. name), mapper or 'keyboard', key)
end

local function disableControls()
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 44, true)
    DisableControlAction(0, 45, true)
    DisableControlAction(0, 20, true)
    DisableControlAction(0, 177, true)
    DisableControlAction(0, 191, true)
    DisableControlAction(0, 19, true)
    DisablePlayerFiring(PlayerId(), true)
end

function SX.Gizmo:IsActive()
    return state.active
end

function SX.Gizmo:Edit(entity)
    if state.active or not entity or not DoesEntityExist(entity) then return false end

    local original = readMatrix(entity)
    local isPed = IsEntityAPed(entity)

    state.active = true
    state.entity = entity
    state.mode = 'translate'
    state.relative = false
    state.result = nil

    if isPed then SetEntityAlpha(entity, 200, false) else SetEntityDrawOutline(entity, true) end
    SetEntityDrawOutlineColor(255, 255, 255, 180)
    sendOverlay()

    local cursor = true
    EnterCursorMode()

    while state.active and DoesEntityExist(entity) do
        Wait(0)
        disableControls()

        if IsDisabledControlPressed(0, 25) then
            if cursor then
                LeaveCursorMode()
                cursor = false
            end
        elseif not cursor then
            EnterCursorMode()
            cursor = true
        end

        local blob = packMatrix(readMatrix(entity))
        if DrawGizmo(blob, 'sxScenes', Citizen.ReturnResultAnyway()) then
            applyMatrix(entity, unpackMatrix(blob))
        end
    end

    if cursor then LeaveCursorMode() end

    local confirmed = state.result == 'confirm'
    if DoesEntityExist(entity) then
        if not confirmed then applyMatrix(entity, original) end
        if isPed then ResetEntityAlpha(entity) else SetEntityDrawOutline(entity, false) end
    end

    state.active = false
    state.entity = nil
    sendOverlay()

    return confirmed
end

function SX.Gizmo:Stop(result)
    if not state.active then return end
    state.result = result
    state.active = false
end

function SX.Gizmo:Initialize()
    registerKey('select', 'MOUSE_LEFT', 'MOUSE_BUTTON', function()
        pressGizmo('gizmoSelect')
    end, function()
        releaseGizmo('gizmoSelect')
    end)

    registerKey('translate', 'Z', nil, function()
        state.mode = 'translate'
        pressGizmo('gizmoTranslation')
        sendOverlay()
    end, function()
        releaseGizmo('gizmoTranslation')
    end)

    registerKey('rotate', 'R', nil, function()
        state.mode = 'rotate'
        pressGizmo('gizmoRotation')
        sendOverlay()
    end, function()
        releaseGizmo('gizmoRotation')
    end)

    registerKey('local', 'Q', nil, function()
        state.relative = not state.relative
        pressGizmo('gizmoLocal')
        sendOverlay()
    end, function()
        releaseGizmo('gizmoLocal')
    end)

    registerKey('ground', 'LMENU', nil, function()
        if state.entity and DoesEntityExist(state.entity) then
            PlaceObjectOnGroundProperly(state.entity)
        end
    end)

    registerKey('confirm', 'RETURN', nil, function()
        SX.Gizmo:Stop('confirm')
    end)

    registerKey('cancel', 'BACK', nil, function()
        SX.Gizmo:Stop('cancel')
    end)
end
