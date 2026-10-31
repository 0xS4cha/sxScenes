import { useCallback, useEffect, useState } from 'react'
import type { ActionResult } from '../types/scenes'

export interface Feedback {
  tone: 'success' | 'error'
  key: string
  replacements?: Record<string, string | number>
}

export function useFeedback(delay = 3500) {
  const [feedback, setFeedback] = useState<Feedback | null>(null)

  useEffect(() => {
    if (!feedback) return
    const timeout = window.setTimeout(() => setFeedback(null), delay)
    return () => window.clearTimeout(timeout)
  }, [feedback, delay])

  const report = useCallback((result: ActionResult, successKey?: string, replacements?: Record<string, string | number>) => {
    if (!result.ok) setFeedback({ tone: 'error', key: `error_${result.error ?? 'unknown'}` })
    else if (successKey) setFeedback({ tone: 'success', key: successKey, replacements })
    return result.ok
  }, [])

  return { feedback, report, clear: () => setFeedback(null) }
}
