import { useCallback, useEffect, useState } from 'react'
import { MOCK_ADMIN } from '../data/mockAdmin'
import type { AdminData } from '../types/admin'
import type { Vec3 } from '../types/scenes'
import { nuiAction } from '../utils/call'
import { fetchNui } from '../utils/fetchNui'
import { toArray } from '../utils/list'
import { isEnvBrowser } from '../utils/nui'

const EMPTY: AdminData = {
  ok: true,
  scenes: [],
  players: [],
  activity: [],
  shown: [],
  framework: 'standalone',
  storage: 'json',
  stats: { props: 0, public: 0, catalog: 0 },
  settings: {
    scenes: 0,
    props: 0,
    radius: 0,
    streamDistance: 0,
    publicEnabled: false,
    playersCanPublish: false,
    sharing: false,
    customModels: false,
    everyoneCanCreate: false,
    groups: false,
    territories: false,
  },
}

function normalize(data: AdminData): AdminData {
  return {
    ...EMPTY,
    ...data,
    scenes: toArray(data.scenes),
    players: toArray(data.players),
    activity: toArray(data.activity),
    shown: toArray(data.shown),
    stats: { ...EMPTY.stats, ...data.stats },
    settings: { ...EMPTY.settings, ...data.settings },
  }
}

export function useAdminData(openCount: number) {
  const [data, setData] = useState<AdminData>(isEnvBrowser() ? MOCK_ADMIN : EMPTY)
  const [loading, setLoading] = useState(false)

  const refresh = useCallback(async () => {
    if (isEnvBrowser()) return
    setLoading(true)
    try {
      const result = await fetchNui<AdminData>('getAdminData')
      if (result?.ok) setData(normalize(result))
    } catch (err) {
      console.error('Failed to fetch admin data:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [openCount, refresh])

  const publish = useCallback(async (id: string, value: boolean) => {
    const result = await nuiAction('adminPublish', { id, public: value })
    if (result.ok) {
      setData((prev) => ({
        ...prev,
        scenes: prev.scenes.map((scene) => (scene.id === id ? { ...scene, public: value } : scene)),
        stats: { ...prev.stats, public: prev.stats.public + (value ? 1 : -1) },
      }))
    }
    return result
  }, [])

  const remove = useCallback(async (id: string) => {
    const result = await nuiAction('adminDelete', { id })
    if (result.ok) {
      setData((prev) => {
        const scene = prev.scenes.find((s) => s.id === id)
        return {
          ...prev,
          scenes: prev.scenes.filter((s) => s.id !== id),
          shown: prev.shown.filter((s) => s !== id),
          players: prev.players.map((p) => (scene && p.identifier === scene.owner ? { ...p, scenes: Math.max(0, p.scenes - 1) } : p)),
          stats: { ...prev.stats, props: prev.stats.props - (scene?.props ?? 0), public: prev.stats.public - (scene?.public ? 1 : 0) },
        }
      })
    }
    return result
  }, [])

  const clearOwner = useCallback(async (identifier: string) => {
    const result = await nuiAction('adminClearOwner', { identifier })
    if (result.ok) {
      if (isEnvBrowser()) {
        setData((prev) => ({
          ...prev,
          scenes: prev.scenes.filter((s) => s.owner !== identifier),
          players: prev.players.map((p) => (p.identifier === identifier ? { ...p, scenes: 0 } : p)),
        }))
      } else void refresh()
    }
    return result
  }, [refresh])

  const show = useCallback(async (id: string, value: boolean) => {
    const result = await nuiAction('sceneShow', { id, shown: value })
    if (result.ok) setData((prev) => ({ ...prev, shown: value ? [...prev.shown, id] : prev.shown.filter((s) => s !== id) }))
    return result
  }, [])

  const edit = useCallback((id: string) => nuiAction('sceneEdit', { id }), [])
  const teleport = useCallback((coords: Vec3) => void fetchNui('teleport', coords), [])

  return { ...data, loading, refresh, publish, remove, clearOwner, show, edit, teleport }
}
