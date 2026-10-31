import { useCallback, useEffect, useState } from 'react'
import { NuiWrapper } from './components/NuiWrapper'
import { MOCK_EDITOR } from './data/mockScenes'
import { useNuiEvent } from './hooks/useNuiEvent'
import { GizmoOverlay } from './overlays/GizmoOverlay'
import { AdminPanel } from './pages/admin/Index'
import { EditorPage } from './pages/editor/Index'
import { ScenesPage } from './pages/scenes/Index'
import type { PanelRoute, SetRouteData, SetVisibleData } from './types/nui'
import type { EditorState } from './types/scenes'
import { debugData } from './utils/debugData'
import { fetchNui } from './utils/fetchNui'
import { normalizeEditor } from './utils/list'
import { isEnvBrowser } from './utils/nui'

const ROUTES: PanelRoute[] = ['scenes', 'editor', 'admin']

const ignoreEscape = () => {}

function getInitialRoute(): PanelRoute {
  const route = new URLSearchParams(window.location.search).get('route') as PanelRoute | null
  if (isEnvBrowser() && route && ROUTES.includes(route)) return route
  return 'scenes'
}

export default function App() {
  const [visible, setVisible] = useState(isEnvBrowser())
  const [route, setRoute] = useState<PanelRoute>(getInitialRoute)
  const [openCount, setOpenCount] = useState(0)
  const [editor, setEditor] = useState<EditorState | null>(isEnvBrowser() ? MOCK_EDITOR : null)

  const handleSetVisible = useCallback(({ visible: nextVisible }: SetVisibleData) => {
    setVisible(nextVisible)
    if (nextVisible) setOpenCount((count) => count + 1)
  }, [])

  useNuiEvent<SetVisibleData>('setVisible', handleSetVisible)

  useNuiEvent<SetRouteData>('setRoute', ({ route: nextRoute }) => {
    if (ROUTES.includes(nextRoute)) setRoute(nextRoute)
  })

  useNuiEvent<EditorState | null>('editor:update', (state) => {
    setEditor(state && typeof state === 'object' && 'id' in state ? normalizeEditor(state) : null)
  })

  useEffect(() => {
    void fetchNui('nuiReady', { ok: true })

    if (import.meta.env.DEV && isEnvBrowser()) {
      const locale = new URLSearchParams(window.location.search).get('lang') ?? 'en'
      void import('virtual:dev-translations').then(({ default: languages }) => {
        debugData([{ action: 'setTranslations', data: { locale, translations: { ...languages.en, ...languages[locale] } } }])
      })
      if (new URLSearchParams(window.location.search).has('gizmo')) {
        debugData([{ action: 'gizmo', data: { active: true, mode: 'translate', relative: false } }])
      }
    }
  }, [])

  return (
    <>
      <NuiWrapper visible={visible} side={route !== 'admin'} onEscape={route === 'editor' ? ignoreEscape : undefined}>
        {route === 'scenes' && <ScenesPage openCount={openCount} />}
        {route === 'editor' && editor && <EditorPage state={editor} onState={setEditor} />}
        {route === 'admin' && <AdminPanel openCount={openCount} />}
      </NuiWrapper>
      <GizmoOverlay />
    </>
  )
}
