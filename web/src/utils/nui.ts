export function isEnvBrowser(): boolean {
  return !(window as Window & { invokeNative?: unknown }).invokeNative
}

export function getResourceName(): string {
  if (isEnvBrowser()) {
    return 'sxScenes'
  }

  return (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName?.() ?? 'sxScenes'
}
