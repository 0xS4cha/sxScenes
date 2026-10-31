Catalog = {}

local blacklist = {}
local known = {}
local categories = nil

for _, model in ipairs(Config.Catalog.blacklist or {}) do
    blacklist[model:lower()] = true
end

for _, model in ipairs(Props or {}) do
    known[model:lower()] = true
end

local function categoryOf(model)
    for _, category in ipairs(Config.Catalog.categories or {}) do
        for _, keyword in ipairs(category.keywords or {}) do
            if model:find(keyword, 1, true) then
                return category.id
            end
        end
    end
    return 'other'
end

function Catalog.NormalizeModel(model)
    if type(model) ~= 'string' then return nil end
    model = Utils.Trim(model):lower()
    if model == '' or #model > 64 or not model:match('^[%w_%-]+$') then return nil end
    return model
end

function Catalog.IsKnown(model)
    return known[model] == true
end

function Catalog.IsBlacklisted(model)
    return blacklist[model] == true
end

function Catalog.IsAllowed(model)
    model = Catalog.NormalizeModel(model)
    if not model or Catalog.IsBlacklisted(model) then return false end
    return Config.Catalog.customModels or Catalog.IsKnown(model)
end

function Catalog.GetCategories()
    if categories then return categories end

    local byId = {}
    categories = {}

    for _, category in ipairs(Config.Catalog.categories or {}) do
        byId[category.id] = { id = category.id, models = {} }
        categories[#categories + 1] = byId[category.id]
    end
    byId.other = { id = 'other', models = {} }
    categories[#categories + 1] = byId.other

    for _, model in ipairs(Props or {}) do
        local name = model:lower()
        if not blacklist[name] then
            local list = byId[categoryOf(name)].models
            list[#list + 1] = name
        end
    end

    return categories
end
