import type { CatalogCategory, EditorState, ScenesData } from '../types/scenes'

const now = Math.floor(Date.now() / 1000)

export const MOCK_SCENES: ScenesData = {
  ok: true,
  canCreate: true,
  canPublish: true,
  sharing: true,
  isAdmin: true,
  customModels: true,
  limits: { scenes: 5, props: 50, radius: 40, labelLength: 40 },
  shown: ['SCN-K2P9QA'],
  editing: null,
  groups: {
    available: true,
    group: { id: '3', name: 'Ballas', color: 'rgb(147, 51, 234)' },
    grade: 1,
    canCreate: true,
    count: 1,
    limit: 5,
  },
  scenes: [
    {
      id: 'SCN-K2P9QA',
      label: 'Beach party',
      ownerName: 'Sacha',
      public: true,
      center: { x: -1385.4, y: -1388.2, z: 3.9 },
      props: [
        { model: 'prop_dj_deck_02', coords: { x: -1385.4, y: -1388.2, z: 3.9 }, rotation: { x: 0, y: 0, z: 90 } },
        { model: 'prop_patio_lounger1', coords: { x: -1382.1, y: -1390.6, z: 3.6 }, rotation: { x: 0, y: 0, z: 12 } },
        { model: 'prop_patio_heater_01', coords: { x: -1387.8, y: -1385.3, z: 3.6 }, rotation: { x: 0, y: 0, z: 0 } },
      ],
      created: now - 86400 * 3,
      updated: now - 3600,
    },
    {
      id: 'SCN-7HD3LM',
      label: 'Roadblock Vinewood',
      ownerName: 'Sacha',
      public: false,
      center: { x: 312.6, y: 167.4, z: 103.8 },
      props: [
        { model: 'prop_mp_barrier_02b', coords: { x: 312.6, y: 167.4, z: 103.8 }, rotation: { x: 0, y: 0, z: 70 } },
        { model: 'prop_roadcone02a', coords: { x: 314.1, y: 165.2, z: 103.8 }, rotation: { x: 0, y: 0, z: 0 } },
      ],
      created: now - 86400,
      updated: now - 600,
    },
    {
      id: 'SCN-B4LL4S',
      label: 'Grove Street tags',
      ownerName: 'Nova',
      public: true,
      center: { x: 85.2, y: -1959.4, z: 21.1 },
      group: { id: '3', name: 'Ballas', color: 'rgb(147, 51, 234)' },
      territory: { id: '1', label: 'Grove Street' },
      permissions: { view: true, edit: true, publish: true, delete: false },
      props: [
        { model: 'prop_rub_couch01', coords: { x: 85.2, y: -1959.4, z: 21.1 }, rotation: { x: 0, y: 0, z: 0 } },
      ],
      created: now - 86400 * 2,
      updated: now - 7200,
    },
  ],
}

export const MOCK_CATALOG: CatalogCategory[] = [
  { id: 'furniture', models: ['prop_chair_01a', 'prop_couch_01', 'prop_bar_stool_01', 'prop_patio_lounger1', 'prop_skid_chair_01'] },
  { id: 'lights', models: ['prop_patio_heater_01'] },
  { id: 'road', models: ['prop_mp_barrier_02b', 'prop_roadcone02a', 'prop_mp_cone_01', 'prop_mb_sandblock_01'] },
  { id: 'nature', models: ['prop_plant_01a', 'prop_bush_lrg_01', 'prop_rock_4_c'] },
  { id: 'electronics', models: ['prop_dj_deck_02'] },
  { id: 'other', models: ['prop_ld_toilet_01', 'prop_byard_ladder01'] },
]

export const MOCK_EDITOR: EditorState = {
  id: 'SCN-K2P9QA',
  label: 'Beach party',
  public: true,
  dirty: true,
  highlight: 1,
  customModels: true,
  limits: { props: 50, radius: 40 },
  props: [
    { index: 1, model: 'prop_dj_deck_02', collision: true, distance: 2.4 },
    { index: 2, model: 'prop_patio_lounger1', collision: true, distance: 4.8 },
    { index: 3, model: 'prop_patio_heater_01', collision: false, distance: 6.1 },
  ],
}
