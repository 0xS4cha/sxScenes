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
    },
}
