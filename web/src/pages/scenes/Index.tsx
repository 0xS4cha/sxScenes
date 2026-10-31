import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { Download, Layers, Plus, RefreshCw, Sparkles } from 'lucide-react'
import { FeedbackBanner } from '../../components/FeedbackBanner'
import { PanelHeader } from '../../components/PanelHeader'
import { Button, EmptyState, IconButton } from '../../components/ui'
import { useConfirm } from '../../hooks/useConfirm'
import { useFeedback } from '../../hooks/useFeedback'
import { useScenesData } from '../../hooks/useScenesData'
import { useTranslation } from '../../hooks/useTranslation'
import { fetchNui } from '../../utils/fetchNui'
import { InlineForm } from './components/InlineForm'
import { SceneCard } from './components/SceneCard'

type FormMode = 'create' | 'import' | null

export function ScenesPage({ openCount }: { openCount: number }) {
  const { t } = useTranslation()
  const data = useScenesData(openCount)
  const confirm = useConfirm<string>()
  const { feedback, report } = useFeedback()
  const [form, setForm] = useState<FormMode>(null)

  const atLimit = !data.isAdmin && data.scenes.length >= data.limits.scenes
  const canAdd = data.canCreate && !atLimit

  return (
    <>
      <PanelHeader
        icon={<Layers className="h-4 w-4" />}
        title={t('scenes_title')}
        subtitle={data.isAdmin ? t('scenes_count_unlimited', { n: data.scenes.length }) : t('scenes_count', { n: data.scenes.length, max: data.limits.scenes })}
        actions={
          <IconButton onClick={() => void data.refresh()} title={t('btn_refresh')}>
            <RefreshCw className={`h-3.5 w-3.5 ${data.loading ? 'animate-spin' : ''}`} />
          </IconButton>
        }
        onClose={() => void fetchNui('close')}
      />

      <div className="flex shrink-0 flex-col gap-3 border-b border-zinc-800/80 px-5 py-4">
        <AnimatePresence mode="wait" initial={false}>
          {form === null ? (
            <motion.div key="actions" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="grid grid-cols-2 gap-2">
              <Button variant="primary" icon={<Plus className="h-3.5 w-3.5" />} disabled={!canAdd} onClick={() => setForm('create')} className="py-2">
                {t('scenes_create')}
              </Button>
              <Button icon={<Download className="h-3.5 w-3.5" />} disabled={!canAdd || !data.sharing} onClick={() => setForm('import')} className="py-2">
                {t('scenes_import')}
              </Button>
            </motion.div>
          ) : (
            <motion.div key={form} initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
              {form === 'create' ? (
                <InlineForm
                  icon={<Sparkles className="h-4 w-4" />}
                  placeholder={t('scenes_create_placeholder')}
                  submitLabel={t('btn_create')}
                  maxLength={data.limits.labelLength}
                  onCancel={() => setForm(null)}
                  onSubmit={async (label) => {
                    const ok = report(await data.create(label), 'notice_scene_created', { name: label })
                    if (ok) setForm(null)
                    return ok
                  }}
                />
              ) : (
                <InlineForm
                  icon={<Download className="h-4 w-4" />}
                  placeholder={t('scenes_import_placeholder')}
                  submitLabel={t('btn_import')}
                  maxLength={12}
                  mono
                  onCancel={() => setForm(null)}
                  onSubmit={async (code) => {
                    const ok = report(await data.importScene(code), 'notice_scene_imported')
                    if (ok) setForm(null)
                    return ok
                  }}
                />
              )}
            </motion.div>
          )}
        </AnimatePresence>
        {!data.canCreate && <p className="text-[11px] text-zinc-500">{t('scenes_no_create')}</p>}
        {data.canCreate && atLimit && <p className="text-[11px] text-amber-400/90">{t('scenes_limit_reached', { max: data.limits.scenes })}</p>}
        <FeedbackBanner feedback={feedback} />
      </div>

      <div className="flex-1 space-y-2.5 overflow-auto px-5 py-4">
        {data.scenes.length === 0 ? (
          <EmptyState icon={<Layers className="h-8 w-8" />} title={t('scenes_empty')} description={t('scenes_empty_desc')} />
        ) : (
          data.scenes.map((scene, idx) => (
            <motion.div key={scene.id} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: idx * 0.03 }}>
              <SceneCard
                scene={scene}
                shown={data.shown.includes(scene.id)}
                canPublish={data.canPublish}
                sharing={data.sharing}
                confirmPending={confirm.pending === scene.id}
                onShow={async (value) => report(await data.show(scene.id, value))}
                onEdit={async () => report(await data.edit(scene.id))}
                onPublish={async (value) => report(await data.publish(scene.id, value), value ? 'notice_scene_published' : 'notice_scene_unpublished')}
                onDelete={() => confirm.request(scene.id, async () => void report(await data.remove(scene.id), 'notice_scene_deleted'))}
                onCopied={() => report({ ok: true }, 'notice_code_copied', { code: scene.id })}
              />
            </motion.div>
          ))
        )}
      </div>

      <footer className="shrink-0 border-t border-zinc-800/80 px-5 py-3 text-[11px] text-zinc-500">
        {t('scenes_footer', { props: data.limits.props, radius: data.limits.radius })}
      </footer>
    </>
  )
}
