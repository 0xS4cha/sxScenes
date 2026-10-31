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

export interface Scene {
  id: string
  label: string
  ownerName: string
  public: boolean
  center: Vec3
  props: SceneProp[]
  created?: number
  updated?: number
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
