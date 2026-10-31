import type { ActionResult } from '../types/scenes'
import { fetchNui } from './fetchNui'
import { isEnvBrowser } from './nui'

export async function nuiAction<T = unknown>(event: string, data?: unknown): Promise<ActionResult<T>> {
  if (isEnvBrowser()) return { ok: true }
  try {
    const result = await fetchNui<T>(event, data)
    return { ok: true, data: result }
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'unknown' }
  }
}
