export interface Vec3 {
  x: number
  y: number
  z: number
}

export interface SceneProp {
  model: string
  coords: Vec3
  rotation: Vec3
  collision?: boolean
}

export interface SceneGroup {
  id: string
  name: string
  color?: string
}

export interface SceneTerritory {
  id: string
  label: string
}

export interface ScenePermissions {
  view: boolean
  edit: boolean
  publish: boolean
  delete: boolean
}

export interface Scene {
  id: string
  label: string
  ownerName: string
  public: boolean
  center: Vec3
  props: SceneProp[]
  group?: SceneGroup | null
  territory?: SceneTerritory | null
  permissions?: ScenePermissions
  created?: number
  updated?: number
}

export interface GroupsData {
  available: boolean
  group?: SceneGroup
  grade?: number
  canCreate?: boolean
  count?: number
  limit?: number
}

export interface SceneLimits {
  scenes: number
  props: number
  radius: number
  labelLength: number
}

export interface ScenesData {
  ok: boolean
  scenes: Scene[]
  canCreate: boolean
  canPublish: boolean
  sharing: boolean
  isAdmin: boolean
  limits: SceneLimits
  customModels: boolean
  shown: string[]
  editing?: string | null
  groups: GroupsData
}

export interface EditorProp {
  index: number
  model: string
  collision: boolean
  distance: number
}

export interface EditorState {
  id: string
  label: string
  public: boolean
  dirty: boolean
  props: EditorProp[]
  highlight?: number | null
  limits: { props: number; radius: number }
  customModels: boolean
}

export interface CatalogCategory {
  id: string
  models: string[]
}

export interface GizmoState {
  active: boolean
  mode: 'translate' | 'rotate'
  relative: boolean
}

export interface ActionResult<T = unknown> {
  ok: boolean
  data?: T
  error?: string
}
