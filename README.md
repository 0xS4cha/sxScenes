# sxScenes

A prop scene builder for **ESX or standalone** FiveM servers. Players build scenes out of props with an in game gizmo, keep them private, show them around themselves, share them with a code or publish them for everyone nearby. Admins manage every scene from a React admin panel.

## Features

- **Scenes**: named groups of props owned by a player, with a limit of scenes per player, props per scene and distance between the props.
- **Editor**: a panel docked on the side of the screen so the world stays visible. Highlight a prop by hovering it, move or rotate it with the gizmo, duplicate it, turn its collisions off or delete it.
- **Gizmo**: move and rotation modes, world or local axes, ground snapping, hold the right mouse button to look around, confirm or cancel to restore the previous position.
- **Catalog**: more than 2500 props sorted in categories by keyword, a search field and a live preview spinning in front of the player before placing it. Custom model names can be allowed or not, and models can be blacklisted.
- **Visibility**: a private scene is only shown to its owner when they choose to show it. A public scene is streamed to every player within `Config.Stream.distance`, props are spawned locally so the network is never touched.
- **Sharing codes**: every scene has a code like `SCN-K2P9QA`. Importing a code copies the scene into your own scenes.
- **Admin panel**: overview, every scene of the server with search and filters, show, edit, publish, teleport to or delete any scene, online players with their scenes, delete all the scenes of a player, activity feed.
- **Server checks**: models, limits, distance between the props and distance between the player and the scene are checked by the server before saving.
- **Discord logs**: optional webhook for created, imported, published and deleted scenes and admin actions.
- **Storage**: oxmysql when available, otherwise JSON files, so the resource also runs without a database.
- **Translations**: English and French, shared between Lua and the interface.
- **Exports**: a server and client API, including the gizmo for your other resources.

## Dependencies

None are required.

| Resource | Purpose |
| --- | --- |
| [es_extended](https://github.com/esx-framework/esx_core) | Optional. Identifiers, names and admin groups |
| [oxmysql](https://github.com/overextended/oxmysql) | Optional. Database storage, otherwise data is saved in `data/scenes.json` |

The server should run with OneSync so it can check the distance between the players and their scenes.

## Installation

1. Clone the repository into your `resources` folder.

   ```bash
   git clone https://github.com/0xS4cha/sxScenes.git
   ```

2. Build the interface, or download a release where `web/dist` is already built.

   ```bash
   cd sxScenes/web
   npm install
   npm run build
   ```

3. Add the resource to your `server.cfg` after its optional dependencies.

   ```cfg
   ensure oxmysql
   ensure es_extended
   ensure sxScenes
   ```

4. Give yourself access to the admin panel. ESX `admin` and `superadmin` groups are allowed by default. In standalone, use the ACE permission:

   ```cfg
   add_ace group.admin sxscenes.admin allow
   ```

The table is created automatically on the first start. `db.sql` is only needed if your database user cannot create tables.

## Usage

| Key / command | Description |
| --- | --- |
| `F7` / `/scenes` | Opens your scenes, or the editor when a scene is being edited |
| `/scenesadmin` | Opens the admin panel |

In the editor, pick a prop in the **Catalog** tab to preview it in front of you, then place it with the gizmo:

| Key | Description |
| --- | --- |
| `Left click` | Drags an axis of the gizmo |
| `Z` | Move mode |
| `R` | Rotation mode |
| `Q` | Switches between world and local axes |
| `Left Alt` | Places the prop on the ground |
| `Right click` (hold) | Looks around |
| `Enter` | Confirms the position |
| `Backspace` | Cancels and restores the previous position |

Every key can be changed in *Settings > Key Bindings > FiveM*. Changes are only kept once the scene is saved, leaving the editor without saving asks for a confirmation.

## Configuration

Everything lives in `shared/config.lua`.

| Key | Default | Description |
| --- | --- | --- |
| `Config.Framework` | `'auto'` | `'auto'`, `'esx'` or `'standalone'` |
| `Config.Storage` | `'auto'` | `'auto'`, `'mysql'` or `'json'` |
| `Config.Admin` | | ESX groups and ACE permission allowed to use the admin panel |
| `Config.Creator.everyone` | `true` | Every player can create scenes. Set it to `false` to only allow the `Config.Creator.ace` permission and admins |
| `Config.Keys.scenes` | `'F7'` | Default key of the scenes panel |
| `Config.Limits.scenes` | `5` | Scenes per player, admins have no limit |
| `Config.Limits.props` | `50` | Props per scene |
| `Config.Limits.radius` | `40.0` | Maximum distance between a prop and the center of its scene |
| `Config.Limits.editDistance` | `100.0` | Maximum distance between a player and the scene they edit or save |
| `Config.Limits.labelLength` | `40` | Maximum length of a scene name |
| `Config.Public.enabled` | `true` | Allows public scenes |
| `Config.Public.playersCanPublish` | `true` | Players can publish their scenes, otherwise only admins can |
| `Config.Sharing` | `true` | Allows importing a scene from its code |
| `Config.Stream.distance` | `150.0` | Distance at which the scenes are spawned |
| `Config.Stream.interval` | `1000` | Milliseconds between two streaming checks |
| `Config.Editor` | | Distance of the preview and of a placed prop in front of the player |
| `Config.Catalog.customModels` | `true` | Allows placing a model that is not in the catalog |
| `Config.Catalog.categories` | | Categories of the catalog and the keywords matched in the model names |
| `Config.Catalog.blacklist` | | Models that can never be placed |
| `Config.Webhook` | | Discord username and the events sent |

The props of the catalog are listed in `shared/props.lua`. A model goes into the first category with a keyword found in its name, or into `other`. A new category only needs an `id`, its keywords and a `catalog_<id>` phrase in the translations.

### Convars

| Convar | Default | Description |
| --- | --- | --- |
| `sx_scenes_webhook` | | Discord webhook URL, kept out of the shared config so clients never see it |
| `sx_locale` | | Forces the language, `setr sx_locale fr` |
| `sx_scenes_debug` | `0` | `1` prints trace logs |
| `sx_scenes_log_level` | `2` | `0` errors, `1` warnings, `2` info, `3` trace |

## How it works

```
core/           Module loader, class helper, callbacks, logger, translations, utilities
bridge/         ESX / standalone bridge and oxmysql / JSON storage
modules/
  catalog/      Catalog categories, blacklist and model checks, shared by both sides
  scenes/       Scenes registry, validation and player actions, player panel
  stream/       Spawns the public and shown scenes around the player
  editor/       Editing session, preview, placement and saving
  gizmo/        Gizmo built on the DrawGizmo native
  admin/        Admin panel, activity feed and Discord logs
  ui/           NUI bridge
  exports/      Public server and client API
shared/         Configuration and the props of the catalog
translations/   Language files, used by Lua and by the interface
web/            React, TypeScript and Tailwind interface
```

The server owns every scene. While editing, the props only exist on the editing client; saving sends the models, positions, rotations and collisions to the server, which checks the models, the limits, the spread of the props and the distance of the player before storing the scene. Public scenes are then sent to every client, which spawns them locally, frozen and invincible, when the player gets close and deletes them when they leave. A scene is stored under its code in the `sx_scenes` table or in `data/scenes.json`.

## Exports

### Server

| Export | Returns | Description |
| --- | --- | --- |
| `GetScene(id)` | `table` | Id, label, owner, visibility, center and props of a scene |
| `GetScenes()` | `table[]` | Every scene |
| `GetPlayerScenes(target)` | `table[]` | Scenes of a player server id or an identifier |
| `CreateScene(owner, label, props?, public?)` | `string, error?` | Creates a scene for a player server id or an identifier and returns its id |
| `UpdateScene(id, data)` | `boolean, error?` | Changes the `label`, `props` or `public` field of a scene |
| `SetScenePublic(id, public)` | `boolean, error?` | |
| `DeleteScene(id)` | `boolean` | |
| `IsModelAllowed(model)` | `boolean` | Checks the blacklist and the catalog rules |
| `IsAdmin(source)` | `boolean` | |

A prop is `{ model = 'prop_chair_01a', coords = { x, y, z }, rotation = { x, y, z }, collision = true }`.

```lua
local id = exports.sxScenes:CreateScene(source, "Checkpoint", {
    { model = "prop_mp_barrier_02b", coords = vector3(312.6, 167.4, 103.8), rotation = vector3(0.0, 0.0, 70.0) },
    { model = "prop_roadcone02a", coords = vector3(314.1, 165.2, 103.8), rotation = vector3(0.0, 0.0, 0.0) },
}, true)
```

### Client

| Export | Description |
| --- | --- |
| `OpenScenes()` | Opens the scenes panel |
| `OpenAdminPanel()` | |
| `EditScene(id)` | Opens the editor on a scene |
| `IsEditing()` | |
| `StopEditing()` | Leaves the editor without saving |
| `ShowScene(id)` / `HideScene(id)` | Shows or hides a scene around the player |
| `GetSceneEntities(id)` | Entities of a spawned scene |
| `UseGizmo(entity)` | Edits any entity with the gizmo, returns `confirmed, coords, rotation` |

```lua
local object = CreateObject(`prop_chair_01a`, GetEntityCoords(PlayerPedId()), false, false, false)
local confirmed, coords, rotation = exports.sxScenes:UseGizmo(object)
```

### Events

| Event | Side | Arguments |
| --- | --- | --- |
| `sxScenes:sceneCreated` | Server | scene |
| `sxScenes:sceneUpdated` | Server | scene |
| `sxScenes:sceneDeleted` | Server | scene |
| `sxScenes:activity` | Server | activity entry |

## Translations

Translations are registered in `translations/*.lua` with `AddLanguage`. Lua phrases use `%s` / `%d`, interface phrases use `{name}` placeholders.

## Development

The interface can be developed in a browser with mock data and the real translations.

```bash
cd web
npm install
npm run dev
```

| Query parameter | Effect |
| --- | --- |
| `?lang=fr` | Language of the preview |
| `?route=editor` | Shows the editor |
| `?route=admin` | Shows the admin panel |
| `?view=scenes` | Opens a view of the admin panel |
| `?gizmo` | Shows the gizmo overlay |
| `?static` | Disables animations |

## License

Released under the [MIT License](LICENSE).
