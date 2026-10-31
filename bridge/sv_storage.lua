Storage = {}
Storage.Name = 'json'
Storage.Ready = false

local resourceName = GetCurrentResourceName()

local TABLES = {
    scenes = 'sx_scenes',
}

if Config.Storage == 'mysql' or (Config.Storage ~= 'json' and GetResourceState('oxmysql') ~= 'missing') then
    Storage.Name = 'mysql'
end

local function query(sql, params)
    local p = promise.new()
    exports.oxmysql:query(sql, params or {}, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

local function execute(sql, params)
    exports.oxmysql:query(sql, params or {})
end

local jsonCollections = {}
local jsonDirty = {}

local function jsonFile(collection)
    return ('data/%s.json'):format(collection)
end

local function readJson(collection)
    local content = LoadResourceFile(resourceName, jsonFile(collection))
    if not content or content == '' then return {} end

    local ok, decoded = pcall(json.decode, content)
    if not ok or type(decoded) ~= 'table' then
        Logger:error('STORAGE', jsonFile(collection), "is not valid JSON, starting with an empty collection")
        return {}
    end

    local records = {}
    for _, record in pairs(decoded) do
        if type(record) == 'table' and record.id then
            records[record.id] = record
        end
    end
    return records
end

local function writeJson(collection)
    jsonDirty[collection] = nil

    local list = {}
    for _, record in pairs(jsonCollections[collection] or {}) do
        list[#list + 1] = record
    end
    table.sort(list, function(a, b) return tostring(a.id) < tostring(b.id) end)

    if not SaveResourceFile(resourceName, jsonFile(collection), json.encode(list, { indent = true }), -1) then
        Logger:error('STORAGE', "Unable to write", jsonFile(collection))
    end
end

local function scheduleJsonWrite(collection)
    if jsonDirty[collection] then return end
    jsonDirty[collection] = true
    SetTimeout(500, function()
        writeJson(collection)
    end)
end

function Storage.Init()
    if Storage.Name == 'mysql' then
        local timeout = GetGameTimer() + 30000
        while GetResourceState('oxmysql') ~= 'started' and GetGameTimer() < timeout do Wait(100) end

        query([[
            CREATE TABLE IF NOT EXISTS `sx_scenes` (
                `id` varchar(20) NOT NULL,
                `data` longtext NOT NULL,
                `created_at` datetime NOT NULL DEFAULT current_timestamp(),
                `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ]])
    else
        for collection in pairs(TABLES) do
            jsonCollections[collection] = readJson(collection)
        end
    end

    Storage.Ready = true
    Logger:info('STORAGE', "Storage:", Storage.Name)
end

function Storage.Await()
    while not Storage.Ready do Wait(50) end
end

local function decode(value)
    if type(value) ~= 'string' then return {} end
    local ok, decoded = pcall(json.decode, value)
    return ok and type(decoded) == 'table' and decoded or {}
end

function Storage.LoadAll(collection)
    Storage.Await()
    local records = {}

    if Storage.Name == 'mysql' then
        for _, row in ipairs(query(('SELECT `id`, `data` FROM `%s`'):format(TABLES[collection])) or {}) do
            local data = decode(row.data)
            data.id = row.id
            records[#records + 1] = data
        end
    else
        for _, record in pairs(jsonCollections[collection] or {}) do
            records[#records + 1] = Utils.DeepCopy(record)
        end
    end

    return records
end

function Storage.Save(collection, id, data)
    Storage.Await()
    if Storage.Name == 'mysql' then
        execute(([[
            INSERT INTO `%s` (`id`, `data`) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)
        ]]):format(TABLES[collection]), { id, json.encode(data) })
        return
    end

    local record = Utils.DeepCopy(data)
    record.id = id
    jsonCollections[collection][id] = record
    scheduleJsonWrite(collection)
end

function Storage.Delete(collection, id)
    Storage.Await()
    if Storage.Name == 'mysql' then
        execute(('DELETE FROM `%s` WHERE `id` = ?'):format(TABLES[collection]), { id })
        return
    end

    jsonCollections[collection][id] = nil
    scheduleJsonWrite(collection)
end

function Storage.Flush()
    if Storage.Name ~= 'json' then return end
    for collection in pairs(jsonDirty) do
        writeJson(collection)
    end
end
