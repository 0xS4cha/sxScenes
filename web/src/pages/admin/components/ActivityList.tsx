import { Download, Eraser, Flag, Globe, History, Layers, Pencil, Trash2 } from 'lucide-react'
import { useTranslation } from '../../../hooks/useTranslation'
import type { ActivityEntry } from '../../../types/admin'
import { formatRelativeTime } from '../../../utils/format'

const ICONS: Record<string, typeof Layers> = {
  scene_created: Layers,
  scene_updated: Pencil,
  scene_deleted: Trash2,
  scene_imported: Download,
  scene_published: Globe,
  scene_unpublished: Globe,
  admin_delete: Trash2,
  admin_publish: Globe,
  admin_clear: Eraser,
  territory_lost: Flag,
}

const SEVERITY: Record<ActivityEntry['severity'], string> = {
  info: 'border-zinc-700 bg-zinc-900 text-zinc-300',
  success: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400',
  warning: 'border-amber-500/30 bg-amber-500/10 text-amber-400',
}

export function ActivityList({ entries, compact = false }: { entries: ActivityEntry[]; compact?: boolean }) {
  const { t } = useTranslation()
  if (entries.length === 0) return <p className="py-6 text-center text-xs text-zinc-500">{t('activity_empty')}</p>

  return (
    <div className={compact ? 'space-y-3.5' : 'space-y-2'}>
      {entries.map((entry) => {
        const Icon = ICONS[entry.type] ?? History
        const replacements: Record<string, string | number> = { player: entry.player ?? t('activity_server') }
        Object.entries(entry.data ?? {}).forEach(([key, value]) => { replacements[key] = value })
        return (
          <div key={entry.id} className={`flex items-start gap-3 ${compact ? '' : 'rounded-lg border border-zinc-800/50 bg-zinc-950/60 px-4 py-3'}`}>
            <div className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-md border ${SEVERITY[entry.severity] ?? SEVERITY.info}`}>
              <Icon className="h-3.5 w-3.5" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-start justify-between gap-2">
                <p className="text-xs leading-relaxed text-zinc-200">{t(`activity_${entry.type}`, replacements)}</p>
                <span className="shrink-0 text-[10px] text-zinc-500">{formatRelativeTime(entry.time, t)}</span>
              </div>
              {!compact && entry.identifier && <p className="mt-0.5 truncate font-mono text-[10px] text-zinc-500">{entry.identifier} · ID {entry.playerId}</p>}
            </div>
          </div>
        )
      })}
    </div>
  )
}
