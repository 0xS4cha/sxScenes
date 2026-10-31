import type { AdminData } from '../types/admin'

const now = Math.floor(Date.now() / 1000)

export const MOCK_ADMIN: AdminData = {
  ok: true,
  framework: 'esx',
  storage: 'mysql',
  shown: ['SCN-K2P9QA'],
  stats: { props: 27, public: 2, catalog: 2577 },
  settings: {
    scenes: 5,
    props: 50,
    radius: 40,
    streamDistance: 150,
    publicEnabled: true,
    playersCanPublish: true,
    sharing: true,
    customModels: true,
    everyoneCanCreate: true,
  },
  scenes: [
    { id: 'SCN-K2P9QA', label: 'Beach party', owner: 'license:2f4c9a', ownerName: 'Sacha', public: true, center: { x: -1385.4, y: -1388.2, z: 3.9 }, props: 12, created: now - 86400 * 3, updated: now - 3600 },
    { id: 'SCN-7HD3LM', label: 'Roadblock Vinewood', owner: 'license:2f4c9a', ownerName: 'Sacha', public: false, center: { x: 312.6, y: 167.4, z: 103.8 }, props: 6, created: now - 86400, updated: now - 600 },
    { id: 'SCN-P0QW8E', label: 'Car meet LS Docks', owner: 'license:8b1e77', ownerName: 'Nova', public: true, center: { x: 1003.2, y: -2931.8, z: 5.9 }, props: 9, created: now - 7200, updated: now - 7200 },
  ],
  players: [
    { id: 1, name: 'Sacha', identifier: 'license:2f4c9a', scenes: 2, admin: true },
    { id: 4, name: 'Nova', identifier: 'license:8b1e77', scenes: 1, admin: false },
    { id: 7, name: 'Kenzo', identifier: 'license:41aa02', scenes: 0, admin: false },
  ],
  activity: [
    { id: 4, time: now - 120, type: 'scene_published', severity: 'info', player: 'Nova', playerId: 4, identifier: 'license:8b1e77', data: { name: 'Car meet LS Docks', id: 'SCN-P0QW8E' } },
    { id: 3, time: now - 600, type: 'scene_updated', severity: 'info', player: 'Sacha', playerId: 1, identifier: 'license:2f4c9a', data: { name: 'Roadblock Vinewood', id: 'SCN-7HD3LM', props: 6 } },
    { id: 2, time: now - 3600, type: 'scene_imported', severity: 'success', player: 'Kenzo', playerId: 7, identifier: 'license:41aa02', data: { name: 'Beach party', id: 'SCN-XX12AB', from: 'SCN-K2P9QA' } },
    { id: 1, time: now - 7200, type: 'admin_delete', severity: 'warning', player: 'Sacha', playerId: 1, identifier: 'license:2f4c9a', data: { name: 'Spam', id: 'SCN-AAAAAA', owner: 'Kenzo' } },
  ],
}
