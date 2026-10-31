SX.UI = {}
SX.Modules:Register("UI", 5)

local isOpen = false
local currentRoute = nil
local closeHandlers = {}

function SX.UI:Send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function sendTranslations()
    local locale = GetPreferredLanguageId()
    SX.UI:Send('setTranslations', {
        locale = locale,
        translations = GetLanguageTable(locale)
    })
end

function SX.UI:Open(route)
    currentRoute = route
    isOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    self:Send('setRoute', { route = route })
    self:Send('setVisible', { visible = true })
end

function SX.UI:Close()
    if not isOpen then return end

    local route = currentRoute
    isOpen = false
    currentRoute = nil
    SetNuiFocus(false, false)
    self:Send('setVisible', { visible = false })

    for _, handler in ipairs(closeHandlers) do
        handler(route)
    end
end

function SX.UI:Hide()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    self:Send('setVisible', { visible = false })
end

function SX.UI:Show()
    if isOpen or not currentRoute then return end
    isOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    self:Send('setVisible', { visible = true })
end

function SX.UI:OnClose(handler)
    closeHandlers[#closeHandlers + 1] = handler
end

function SX.UI:IsOpen()
    return isOpen
end

function SX.UI:GetRoute()
    return currentRoute
end

function SX.UI:Initialize()
    RegisterNUICallback('nuiReady', function(_, cb)
        sendTranslations()
        cb({ ok = true })
    end)

    RegisterNUICallback('close', function(_, cb)
        SX.UI:Close()
        cb({ ok = true })
    end)

    CreateThread(function()
        Wait(1000)
        sendTranslations()
    end)

    CreateThread(function()
        while true do
            if isOpen then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 18, true)
                DisableControlAction(0, 322, true)
                DisableControlAction(0, 106, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end
