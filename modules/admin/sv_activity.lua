Activity = {}

local entries = {}
local counter = 0
local webhookUrl = GetConvar('sx_scenes_webhook', '')

local SEVERITY = {
    scene_created = 'success',
    scene_updated = 'info',
    scene_deleted = 'warning',
    scene_imported = 'success',
    scene_published = 'info',
    scene_unpublished = 'info',
    admin_delete = 'warning',
    admin_publish = 'warning',
    admin_clear = 'warning',
    territory_lost = 'warning',
}

local COLORS = { info = 3447003, success = 5763719, warning = 16705372 }

local function formatData(data)
    local parts = {}
    for key, value in pairs(data or {}) do
        parts[#parts + 1] = ('**%s**: %s'):format(key, tostring(value))
    end
    table.sort(parts)
    return table.concat(parts, '\n')
end

local function sendWebhook(entry)
    if not Config.Webhook.enabled or webhookUrl == '' or not Config.Webhook.events[entry.type] then return end

    local description = formatData(entry.data)
    if entry.player then
        description = ('**player**: %s (%s) `%s`\n'):format(entry.player, entry.playerId, entry.identifier or '-') .. description
    end

    PerformHttpRequest(webhookUrl, function() end, 'POST', json.encode({
        username = Config.Webhook.username,
        embeds = { {
            title = GetPhrase('webhook_' .. entry.type),
            description = description,
            color = COLORS[entry.severity] or COLORS.info,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', entry.time),
            footer = { text = 'sxScenes' },
        } },
    }), { ['Content-Type'] = 'application/json' })
end

function Activity.Add(kind, source, data)
    counter = counter + 1

    local entry = {
        id = counter,
        time = os.time(),
        type = kind,
        severity = SEVERITY[kind] or 'info',
        data = data or {},
    }

    if source and source > 0 then
        entry.player = Bridge.GetPlayerName(source)
        entry.playerId = source
        entry.identifier = Bridge.GetIdentifier(source)
    end

    table.insert(entries, 1, entry)
    while #entries > Config.ActivityLimit do
        table.remove(entries)
    end

    sendWebhook(entry)
    TriggerEvent('sxScenes:activity', entry)
end

function Activity.GetAll()
    return entries
end
