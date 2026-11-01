import { Boxes, Copy, Eye, EyeOff, Flag, Globe, Lock, Pencil, Trash2, Users } from 'lucide-react'
import { Badge, IconButton } from '../../../components/ui'
import { useTranslation } from '../../../hooks/useTranslation'
import type { Scene } from '../../../types/scenes'
import { copyToClipboard, formatRelativeTime } from '../../../utils/format'

interface SceneCardProps {
  scene: Scene
  shown: boolean
  canPublish: boolean
  sharing: boolean
  confirmPending: boolean
  onShow: (value: boolean) => void
  onEdit: () => void
  onPublish: (value: boolean) => void
  onDelete: () => void
  onCopied: () => void
}

export function SceneCard({ scene, shown, canPublish, sharing, confirmPending, onShow, onEdit, onPublish, onDelete, onCopied }: SceneCardProps) {
  const { t } = useTranslation()
  const permissions = scene.permissions ?? { view: true, edit: true, publish: canPublish, delete: true }

  return (
    <div className="rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-3.5 transition hover:border-zinc-700 hover:bg-zinc-900/60">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h4 className="truncate text-sm font-bold text-zinc-100">{scene.label}</h4>
          <div className="mt-0.5 flex items-center gap-1.5 font-mono text-[11px] text-zinc-500">
            <span>{scene.id}</span>
            {sharing && (
              <button
                type="button"
                title={t('scene_copy_code')}
                onClick={() => {
                  copyToClipboard(scene.id)
                  onCopied()
                }}
                className="text-zinc-500 transition hover:text-zinc-200"
              >
                <Copy className="h-3 w-3" />
              </button>
            )}
          </div>
        </div>
        <div className="flex shrink-0 flex-wrap justify-end gap-1">
          {scene.public ? (
            <Badge tone="info" icon={<Globe className="h-3 w-3" />}>{t('scene_public')}</Badge>
          ) : (
            <Badge icon={<Lock className="h-3 w-3" />}>{t('scene_private')}</Badge>
          )}
          {shown && <Badge tone="success" icon={<Eye className="h-3 w-3" />}>{t('scene_shown')}</Badge>}
          {scene.territory && <Badge tone="warning" icon={<Flag className="h-3 w-3" />} title={t('scene_territory_hint')}>{scene.territory.label}</Badge>}
          {Boolean(scene.bucket) && <Badge icon={<Boxes className="h-3 w-3" />} title={t('scene_instance_hint')}>{t('scene_instance', { n: scene.bucket ?? 0 })}</Badge>}
        </div>
      </div>

      <p className="mt-2 text-[11px] text-zinc-400">
        {scene.group && (
          <span className="mr-1.5 inline-flex items-center gap-1 font-semibold" style={{ color: scene.group.color }}>
            <Users className="h-3 w-3" />
            {scene.group.name} ·
          </span>
        )}
        {t('scene_props_count', { n: scene.props.length })}
        {scene.group && ` · ${t('scene_created_by', { name: scene.ownerName })}`}
        {scene.updated ? ` · ${t('scene_updated', { time: formatRelativeTime(scene.updated, t) })}` : ''}
      </p>

      <div className="mt-3 flex items-center justify-between gap-2 border-t border-zinc-800/60 pt-3">
        <button
          type="button"
          onClick={onEdit}
          disabled={!permissions.edit}
          className="inline-flex items-center gap-1.5 rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-1.5 text-xs font-semibold text-zinc-300 transition hover:border-zinc-600 hover:text-white disabled:cursor-not-allowed disabled:opacity-40"
        >
          <Pencil className="h-3.5 w-3.5" />
          {t('btn_edit')}
        </button>
        <div className="flex items-center gap-0.5">
          <IconButton onClick={() => onShow(!shown)} title={shown ? t('scene_hide') : t('scene_show')}>
            {shown ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
          </IconButton>
          {permissions.publish && (
            <IconButton onClick={() => onPublish(!scene.public)} title={scene.public ? t('scene_unpublish') : t('scene_publish')} className={scene.public ? 'text-sky-400' : ''}>
              <Globe className="h-3.5 w-3.5" />
            </IconButton>
          )}
          <button
            type="button"
            onClick={onDelete}
            disabled={!permissions.delete}
            className={`flex h-7 disabled:cursor-not-allowed disabled:opacity-40 items-center justify-center gap-1 rounded-md px-2 text-[11px] font-semibold transition ${confirmPending ? 'bg-rose-500/15 text-rose-300' : 'text-zinc-400 hover:bg-rose-500/10 hover:text-rose-400'}`}
          >
            <Trash2 className="h-3.5 w-3.5" />
            {confirmPending && t('btn_confirm_delete')}
          </button>
        </div>
      </div>
    </div>
  )
}
