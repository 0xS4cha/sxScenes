import { Box, Copy, Move3d, Shield, ShieldOff, Trash2 } from 'lucide-react'
import { EmptyState, IconButton } from '../../../components/ui'
import { useConfirm } from '../../../hooks/useConfirm'
import { useTranslation } from '../../../hooks/useTranslation'
import type { EditorProp } from '../../../types/scenes'

interface PropsTabProps {
  props: EditorProp[]
  highlight?: number | null
  onHighlight: (index: number | null) => void
  onMove: (index: number) => void
  onDuplicate: (index: number) => void
  onCollision: (index: number, value: boolean) => void
  onDelete: (index: number) => void
  onBrowse: () => void
}

export function PropsTab({ props, highlight, onHighlight, onMove, onDuplicate, onCollision, onDelete, onBrowse }: PropsTabProps) {
  const { t } = useTranslation()
  const confirm = useConfirm<number>()

  if (props.length === 0) {
    return (
      <EmptyState
        icon={<Box className="h-8 w-8" />}
        title={t('editor_props_empty')}
        description={t('editor_props_empty_desc')}
        action={
          <button type="button" onClick={onBrowse} className="rounded-lg border border-zinc-700 bg-zinc-100 px-3 py-1.5 text-xs font-semibold text-zinc-900 transition hover:bg-white">
            {t('editor_browse_catalog')}
          </button>
        }
      />
    )
  }

  return (
    <div className="space-y-1.5" onMouseLeave={() => onHighlight(null)}>
      {props.map((prop) => {
        const active = highlight === prop.index
        return (
          <div
            key={`${prop.index}-${prop.model}`}
            onMouseEnter={() => onHighlight(prop.index)}
            className={`flex items-center gap-3 rounded-lg border px-3 py-2 transition ${active ? 'border-zinc-600 bg-zinc-900' : 'border-zinc-800/70 bg-zinc-900/40'}`}
          >
            <span className="flex h-7 w-8 shrink-0 items-center justify-center rounded-md bg-zinc-800 font-mono text-[11px] font-bold text-zinc-300">{prop.index}</span>
            <div className="min-w-0 flex-1">
              <p className="truncate font-mono text-xs text-zinc-100">{prop.model}</p>
              <p className="text-[10px] text-zinc-500">
                {t('editor_prop_distance', { n: prop.distance })}
                {!prop.collision && ` · ${t('editor_prop_no_collision')}`}
              </p>
            </div>
            <div className="flex shrink-0 items-center gap-0.5">
              <IconButton onClick={() => onMove(prop.index)} title={t('editor_move')}><Move3d className="h-3.5 w-3.5" /></IconButton>
              <IconButton onClick={() => onDuplicate(prop.index)} title={t('editor_duplicate')}><Copy className="h-3.5 w-3.5" /></IconButton>
              <IconButton onClick={() => onCollision(prop.index, !prop.collision)} title={prop.collision ? t('editor_collision_off') : t('editor_collision_on')} className={prop.collision ? '' : 'text-amber-400'}>
                {prop.collision ? <Shield className="h-3.5 w-3.5" /> : <ShieldOff className="h-3.5 w-3.5" />}
              </IconButton>
              <button
                type="button"
                onClick={() => confirm.request(prop.index, () => onDelete(prop.index))}
                className={`flex h-7 items-center gap-1 rounded-md px-2 text-[11px] font-semibold transition ${confirm.pending === prop.index ? 'bg-rose-500/15 text-rose-300' : 'text-zinc-400 hover:bg-rose-500/10 hover:text-rose-400'}`}
                title={t('btn_delete')}
              >
                <Trash2 className="h-3.5 w-3.5" />
                {confirm.pending === prop.index && t('btn_confirm_delete')}
              </button>
            </div>
          </div>
        )
      })}
    </div>
  )
}
