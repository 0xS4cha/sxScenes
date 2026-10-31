export type PanelRoute = 'scenes' | 'editor' | 'admin'

export interface SetVisibleData {
  visible: boolean
}

export interface SetRouteData {
  route: PanelRoute
}

export interface SetLocaleData {
  locale: string
}

export type PhraseDictionary = Record<string, string>

export interface SetTranslationsData {
  locale: string
  translations: PhraseDictionary
}

export interface NuiMessage<T = unknown> {
  action: string
  data: T
}

export interface NuiCallbackResponse<T = unknown> {
  ok: boolean
  data?: T
  error?: string
}
