import { useCallback, useEffect, useState } from 'react'
import { MOCK_SCENES } from '../data/mockScenes'
import type { Scene, ScenesData } from '../types/scenes'
import { nuiAction } from '../utils/call'
import { fetchNui } from '../utils/fetchNui'
import { toArray } from '../utils/list'
import { isEnvBrowser } from '../utils/nui'

const EMPTY: ScenesData = {
  ok: true,
  scenes: [],
  canCreate: false,
  canPublish: false,
  sharing: false,
  isAdmin: false,
  customModels: false,
  limits: { scenes: 0, props: 0, radius: 0, labelLength: 40 },
  shown: [],
  editing: null,
}

function normalize(data: ScenesData): ScenesData {
  return {
    ...EMPTY,
    ...data,
    scenes: toArray(data.scenes).map((scene) => ({ ...scene, props: toArray(scene.props) })),
    shown: toArray(data.shown),
    limits: { ...EMPTY.limits, ...data.limits },
  }
}

export function useScenesData(openCount: number) {
  const [data, setData] = useState<ScenesData>(isEnvBrowser() ? MOCK_SCENES : EMPTY)
  const [loading, setLoading] = useState(false)

  const refresh = useCallback(async () => {
    if (isEnvBrowser()) return
    setLoading(true)
    try {
      const result = await fetchNui<ScenesData>('getScenesData')
      if (result?.ok) setData(normalize(result))
    } catch (err) {
      console.error('Failed to fetch scenes:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [openCount, refresh])

  const mutate = useCallback((update: (prev: ScenesData) => ScenesData) => setData((prev) => update(prev)), [])

  const create = useCallback(async (label: string) => {
    const result = await nuiAction<Scene>('sceneCreate', { label })
    if (result.ok) {
      if (isEnvBrowser()) {
        const scene: Scene = { id: `SCN-${Date.now().toString(36).toUpperCase().slice(-6)}`, label, ownerName: 'Sacha', public: false, center: { x: 0, y: 0, z: 0 }, props: [] }
        mutate((prev) => ({ ...prev, scenes: [...prev.scenes, scene] }))
      } else void refresh()
    }
    return result
  }, [mutate, refresh])

  const importScene = useCallback(async (code: string) => {
    const result = await nuiAction<Scene>('sceneImport', { code })
    if (result.ok) void refresh()
    return result
  }, [refresh])

  const remove = useCallback(async (id: string) => {
    const result = await nuiAction('sceneDelete', { id })
    if (result.ok) mutate((prev) => ({ ...prev, scenes: prev.scenes.filter((scene) => scene.id !== id), shown: prev.shown.filter((s) => s !== id) }))
    return result
  }, [mutate])

  const publish = useCallback(async (id: string, value: boolean) => {
    const result = await nuiAction('scenePublish', { id, public: value })
    if (result.ok) mutate((prev) => ({ ...prev, scenes: prev.scenes.map((scene) => (scene.id === id ? { ...scene, public: value } : scene)) }))
    return result
  }, [mutate])

  const show = useCallback(async (id: string, value: boolean) => {
    const result = await nuiAction('sceneShow', { id, shown: value })
    if (result.ok) mutate((prev) => ({ ...prev, shown: value ? [...prev.shown, id] : prev.shown.filter((s) => s !== id) }))
    return result
  }, [mutate])

  const edit = useCallback((id: string) => nuiAction('sceneEdit', { id }), [])

  return { ...data, loading, refresh, create, importScene, remove, publish, show, edit }
}
