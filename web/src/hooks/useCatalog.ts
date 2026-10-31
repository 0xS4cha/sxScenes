import { useEffect, useState } from 'react'
import { MOCK_CATALOG } from '../data/mockScenes'
import type { CatalogCategory } from '../types/scenes'
import { fetchNui } from '../utils/fetchNui'
import { toArray } from '../utils/list'
import { isEnvBrowser } from '../utils/nui'

let cache: CatalogCategory[] | null = isEnvBrowser() ? MOCK_CATALOG : null

export function useCatalog() {
  const [catalog, setCatalog] = useState<CatalogCategory[]>(cache ?? [])
  const [loading, setLoading] = useState(cache === null)

  useEffect(() => {
    if (cache) return
    let cancelled = false
    fetchNui<CatalogCategory[]>('getCatalog')
      .then((result) => {
        cache = toArray(result).map((category) => ({ ...category, models: toArray(category.models) }))
        if (!cancelled) setCatalog(cache)
      })
      .catch((err) => console.error('Failed to fetch the catalog:', err))
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  return { catalog, loading }
}
