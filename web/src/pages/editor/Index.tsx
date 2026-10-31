import { useCallback, useState } from 'react'
import { AnimatePresence } from 'motion/react'
import { Box, Globe, Lock, LogOut, PencilRuler, Save } from 'lucide-react'
import { ConfirmModal } from '../../components/ConfirmModal'
import { FeedbackBanner } from '../../components/FeedbackBanner'
import { PanelHeader } from '../../components/PanelHeader'
import { Badge, Button } from '../../components/ui'
import { useEscapeKey } from '../../hooks/useEscapeKey'
import { useFeedback } from '../../hooks/useFeedback'
import { useTranslation } from '../../hooks/useTranslation'
import type { ActionResult, EditorState } from '../../types/scenes'
import { nuiAction } from '../../utils/call'
import { normalizeEditor } from '../../utils/list'
import { isEnvBrowser } from '../../utils/nui'
import { CatalogTab } from './components/CatalogTab'
import { PropsTab } from './components/PropsTab'

type Tab = 'props' | 'catalog'

interface EditorPageProps {
  state: EditorState
  onState: (state: EditorState) => void
}

export function EditorPage({ state, onState }: EditorPageProps) {
  const { t } = useTranslation()
  const { feedback, report } = useFeedback()
  const [tab, setTab] = useState<Tab>(state.props.length === 0 ? 'catalog' : 'props')
  const [draft, setDraft] = useState<string | null>(null)
  const [confirmExit, setConfirmExit] = useState(false)
  const [saving, setSaving] = useState(false)

  const apply = useCallback((result: ActionResult<EditorState>, successKey?: string) => {
    if (result.ok && result.data) onState(normalizeEditor(result.data))
    return report(result, successKey)
  }, [onState, report])

  const action = useCallback(async (event: string, data?: Record<string, unknown>) => apply(await nuiAction<EditorState>(event, data)), [apply])

  const exit = useCallback(() => void nuiAction('editorExit'), [])

  const requestExit = useCallback(() => {
    if (state.dirty) setConfirmExit(true)
    else exit()
  }, [state.dirty, exit])

  useEscapeKey(requestExit, !confirmExit)

  const preview = useCallback((model: string | null) => void nuiAction('editorPreview', { model }), [])

  const rename = () => {
    const value = (draft ?? '').trim()
    setDraft(null)
    if (!value || value === state.label) return
    if (isEnvBrowser()) onState({ ...state, label: value, dirty: true })
    else void action('editorRename', { label: value })
  }

  const save = async () => {
    setSaving(true)
    const result = await nuiAction<EditorState>('editorSave')
    if (isEnvBrowser() && result.ok) onState({ ...state, dirty: false })
    apply(result, 'notice_scene_saved')
    setSaving(false)
  }

  const full = state.props.length >= state.limits.props

  return (
    <>
      <PanelHeader
        icon={<PencilRuler className="h-4 w-4" />}
        title={
          <input
            value={draft ?? state.label}
            onChange={(e) => setDraft(e.target.value)}
            onBlur={rename}
            onKeyDown={(e) => e.key === 'Enter' && (e.target as HTMLInputElement).blur()}
            className="w-full rounded-md border border-transparent bg-transparent px-1 -ml-1 text-sm font-bold text-zinc-100 transition hover:border-zinc-800 focus:border-zinc-700 focus:outline-none"
          />
        }
        subtitle={
          <span className="flex items-center gap-1.5">
            <span className="font-mono">{state.id}</span>
            {state.public ? <Badge tone="info" icon={<Globe className="h-3 w-3" />}>{t('scene_public')}</Badge> : <Badge icon={<Lock className="h-3 w-3" />}>{t('scene_private')}</Badge>}
            {state.dirty && <Badge tone="warning">{t('editor_unsaved')}</Badge>}
          </span>
        }
        actions={
          <Button variant="primary" icon={<Save className="h-3.5 w-3.5" />} disabled={!state.dirty || saving} onClick={() => void save()}>
            {t('btn_save')}
          </Button>
        }
        onClose={requestExit}
      />

      <div className="flex shrink-0 gap-1 border-b border-zinc-800 px-5 pt-3">
        {([
          { id: 'props' as const, label: t('editor_tab_props', { n: state.props.length, max: state.limits.props }) },
          { id: 'catalog' as const, label: t('editor_tab_catalog') },
        ]).map((entry) => (
          <button
            key={entry.id}
            type="button"
            onClick={() => setTab(entry.id)}
            className={`flex items-center gap-1.5 border-b-2 px-3 pb-2.5 text-xs font-semibold transition ${tab === entry.id ? 'border-zinc-100 text-zinc-100' : 'border-transparent text-zinc-500 hover:text-zinc-300'}`}
          >
            {entry.id === 'props' && <Box className="h-3.5 w-3.5" />}
            {entry.label}
          </button>
        ))}
      </div>

      {feedback && <div className="shrink-0 px-5 pt-3"><FeedbackBanner feedback={feedback} /></div>}

      <div className="min-h-0 flex-1 overflow-auto px-5 py-4">
        {tab === 'props' ? (
          <PropsTab
            props={state.props}
            highlight={state.highlight}
            onHighlight={(index) => void action('editorHighlight', { index })}
            onMove={(index) => void action('editorEdit', { index })}
            onDuplicate={(index) => void action('editorDuplicate', { index })}
            onCollision={(index, value) => void action('editorCollision', { index, value })}
            onDelete={(index) => void action('editorDelete', { index })}
            onBrowse={() => setTab('catalog')}
          />
        ) : (
          <CatalogTab
            customModels={state.customModels}
            disabled={full}
            onPreview={preview}
            onPlace={(model) => void action('editorAdd', { model })}
          />
        )}
      </div>

      <footer className="flex shrink-0 items-center justify-between gap-3 border-t border-zinc-800/80 px-5 py-3">
        <p className="text-[11px] text-zinc-500">{full ? t('editor_full', { max: state.limits.props }) : t('editor_footer', { radius: state.limits.radius })}</p>
        <Button variant="ghost" icon={<LogOut className="h-3.5 w-3.5" />} onClick={requestExit}>{t('editor_exit')}</Button>
      </footer>

      <AnimatePresence>
        {confirmExit && (
          <ConfirmModal
            title={t('editor_exit_title')}
            description={t('editor_exit_desc')}
            confirmLabel={t('editor_exit_confirm')}
            onCancel={() => setConfirmExit(false)}
            onConfirm={() => {
              setConfirmExit(false)
              exit()
            }}
          />
        )}
      </AnimatePresence>
    </>
  )
}
