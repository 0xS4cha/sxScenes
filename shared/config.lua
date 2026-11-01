Config = {}

Config.Framework = 'auto'

Config.Storage = 'auto'

Config.Admin = {
    groups = { 'admin', 'superadmin' },
    ace = 'sxscenes.admin',
}

Config.Creator = {
    everyone = true,
    ace = 'sxscenes.create',
}

Config.Keys = {
    scenes = 'F7',
}

Config.Limits = {
    scenes = 5,
    props = 50,
    radius = 40.0,
    editDistance = 100.0,
    labelLength = 40,
}

Config.Public = {
    enabled = true,
    playersCanPublish = true,
}

Config.Sharing = true

Config.Buckets = {
    enabled = true,
    interval = 1000,
}

Config.Stream = {
    distance = 150.0,
    interval = 1000,
}

Config.Editor = {
    spawnDistance = 3.0,
    previewDistance = 4.0,
}

Config.Catalog = {
    customModels = true,
    categories = {
        { id = 'furniture', keywords = { 'chair', 'couch', 'sofa', 'table', 'bench', 'stool', 'bed', 'lounger', 'seat', 'desk', 'shelf' } },
        { id = 'lights', keywords = { 'light', 'lamp', 'lantern', 'candle', 'torch' } },
        { id = 'road', keywords = { 'barrier', 'cone', 'fence', 'sign', 'barrel', 'bollard', 'roadblock', 'sandblock' } },
        { id = 'nature', keywords = { 'plant', 'bush', 'tree', 'rock', 'flower', 'grass', 'log', 'palm', 'weed' } },
        { id = 'containers', keywords = { 'box', 'crate', 'pallet', 'bin', 'skip', 'container', 'case', 'bag', 'dumpster', 'trolley' } },
        { id = 'food', keywords = { 'food', 'beer', 'bottle', 'cup', 'drink', 'burger', 'pizza', 'cake', 'wine', 'cash' } },
        { id = 'electronics', keywords = { 'tv', 'speaker', 'dj_', 'monitor', 'laptop', 'phone', 'radio', 'console', 'keyboard' } },
        { id = 'tools', keywords = { 'tool', 'ladder', 'generator', 'drill', 'hammer', 'spanner', 'wrench', 'jack' } },
    },
    blacklist = {
        'prop_fnclink_02gate1',
        'stt_prop_stunt_track_start',
        'p_spinning_anus_s',
        'prop_beach_fire',
        'prop_gas_tank_01a',
        'prop_gascyl_01a',
        'prop_jetski_ramp_01',
        'prop_mp_ramp_03',
    },
}

Config.Integrations = {
    sxIllegals = 'sxIllegals',
}

Config.Groups = {
    enabled = true,
    scenes = 5,
    createGrade = 1,
    editGrade = 2,
    publishGrade = 1,
    deleteGrade = 0,
    onGroupDeleted = 'owner',
}

Config.Territories = {
    enabled = true,
    requireOwner = true,
    onLoss = 'hide',
}

Config.ActivityLimit = 100

Config.Webhook = {
    enabled = true,
    username = 'sxScenes',
    events = {
        scene_created = true,
        scene_updated = false,
        scene_deleted = true,
        scene_imported = true,
        scene_published = true,
        scene_unpublished = false,
        admin_delete = true,
        admin_publish = true,
        admin_clear = true,
        territory_lost = true,
        admin_bucket = false,
    },
}
