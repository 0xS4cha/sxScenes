import { useCallback, useEffect, useState } from 'react'

export function useConfirm<T>(delay = 4000) {
  const [pending, setPending] = useState<T | null>(null)

  useEffect(() => {
    if (pending === null) return
    const timeout = window.setTimeout(() => setPending(null), delay)
    return () => window.clearTimeout(timeout)
  }, [pending, delay])

  const request = useCallback((value: T, action: () => void) => {
    if (pending === value) {
      setPending(null)
      action()
    } else {
      setPending(value)
    }
  }, [pending])

  return { pending, request }
}
