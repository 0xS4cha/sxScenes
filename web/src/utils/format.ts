type Translate = (key: string, replacements?: Record<string, string | number>) => string

export function formatRelativeTime(timestamp: number, t: Translate): string {
  const diff = Math.max(0, Math.floor(Date.now() / 1000) - timestamp)
  if (diff < 60) return t('time_just_now')
  if (diff < 3600) return t('time_minutes_ago', { n: Math.floor(diff / 60) })
  if (diff < 86400) return t('time_hours_ago', { n: Math.floor(diff / 3600) })
  return t('time_days_ago', { n: Math.floor(diff / 86400) })
}

export function formatWeight(weight: number): string {
  return `${Math.round(weight * 100) / 100}`
}

export function formatCoords(coords: { x: number; y: number; z: number }): string {
  return `${coords.x.toFixed(1)}, ${coords.y.toFixed(1)}, ${coords.z.toFixed(1)}`
}

export function copyToClipboard(text: string): void {
  const area = document.createElement('textarea')
  area.value = text
  area.style.position = 'fixed'
  area.style.opacity = '0'
  document.body.appendChild(area)
  area.select()
  try {
    document.execCommand('copy')
  } finally {
    document.body.removeChild(area)
  }
}
