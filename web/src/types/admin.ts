import type { SceneGroup, SceneTerritory, Vec3 } from './scenes'

export type AdminCategory = 'overview' | 'scenes' | 'players' | 'activity'

export interface AdminScene {
  id: string
  label: string
  owner: string
  ownerName: string
  public: boolean
  center: Vec3
  props: number
  group?: SceneGroup | null
  territory?: SceneTerritory | null
  created?: number
  updated?: number
}

export interface AdminPlayer {
  id: number
  name: string
  identifier?: string
  scenes: number
  admin: boolean
}

export interface ActivityEntry {
  id: number
  time: number
  type: string
  severity: 'info' | 'success' | 'warning'
  player?: string
  playerId?: number
  identifier?: string
  data?: Record<string, string | number>
}

export interface AdminSettings {
  scenes: number
  props: number
  radius: number
  streamDistance: number
  publicEnabled: boolean
  playersCanPublish: boolean
  sharing: boolean
  customModels: boolean
  everyoneCanCreate: boolean
  groups: boolean
  territories: boolean
}

export interface AdminStats {
  props: number
  public: number
  catalog: number
}

export interface AdminData {
  ok: boolean
  scenes: AdminScene[]
  players: AdminPlayer[]
  activity: ActivityEntry[]
  shown: string[]
  framework: string
  storage: string
  stats: AdminStats
  settings: AdminSettings
}
