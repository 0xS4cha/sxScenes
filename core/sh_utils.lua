Utils = {}

function Utils.Round(value, decimals)
    local mult = 10 ^ (decimals or 2)
    return math.floor((tonumber(value) or 0) * mult + 0.5) / mult
end

function Utils.Trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Utils.ToVector(coords)
    if not coords then return nil end
    return vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

function Utils.ToCoords(coords)
    if type(coords) ~= "table" and type(coords) ~= "vector3" and type(coords) ~= "vector4" then return nil end
    if not coords.x or not coords.y or not coords.z then return nil end
    return {
        x = Utils.Round(coords.x),
        y = Utils.Round(coords.y),
        z = Utils.Round(coords.z),
    }
end

function Utils.StringList(list, max)
    local result = {}
    local seen = {}
    if type(list) ~= "table" then return result end

    for _, value in pairs(list) do
        value = Utils.Trim(tostring(value))
        if value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
            if max and #result >= max then break end
        end
    end

    return result
end

function Utils.DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = Utils.DeepCopy(v)
    end
    return copy
end

function Utils.IsEmpty(value)
    return type(value) ~= "table" or next(value) == nil
end

function Utils.DeepEqual(a, b)
    if a == b then return true end
    if Utils.IsEmpty(a) and Utils.IsEmpty(b) then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end

    for k, v in pairs(a) do
        if not Utils.DeepEqual(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

function Utils.Clamp(value, min, max)
    value = tonumber(value) or min
    if value < min then return min end
    if value > max then return max end
    return value
end
