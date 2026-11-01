import { useState } from 'react'
import { Box, Eye, EyeOff, Flag, Globe, Layers, Lock, MapPin, Pencil, Trash2, User, Users } from 'lucide-react'
import { Badge, EmptyState, IconButton } from '../../../components/ui'
import { useConfirm } from '../../../hooks/useConfirm'
import { useTranslation } from '../../../hooks/useTranslation'
import type { AdminScene } from '../../../types/admin'
import { formatCoords, formatRelativeTime } from '../../../utils/format'
import { SearchBar } from './SearchBar'

type Filter = 'all' | 'public' | 'private' | 'group'

interface ScenesViewProps {
  scenes: AdminScene[]
  shown: string[]
  publicEnabled: boolean
  groupsEnabled: boolean
  search: string
  onSearch: (value: string) => void
  onShow: (scene: AdminScene, value: boolean) => void
  onEdit: (scene: AdminScene) => void
  onPublish: (scene: AdminScene, value: boolean) => void
  onTeleport: (scene: AdminScene) => void
  onDelete: (scene: AdminScene) => void
}

export function ScenesView({ scenes, shown, publicEnabled, groupsEnabled, search, onSearch, onShow, onEdit, onPublish, onTeleport, onDelete }: ScenesViewProps) {
  const { t } = useTranslation()
  const confirm = useConfirm<string>()
  const [filter, setFilter] = useState<Filter>('all')
  const query = search.trim().toLowerCase()

  const filtered = scenes.filter((scene) => {
    if (filter === 'public' && !scene.public) return false
    if (filter === 'private' && scene.public) return false
    if (filter === 'group' && !scene.group) return false
    if (!query) return true
    return [scene.label, scene.id, scene.ownerName, scene.owner, scene.group?.name, scene.territory?.label].some((value) => value?.toLowerCase().includes(query))
  })

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="flex-1">
          <SearchBar value={search} onChange={onSearch} placeholder={t('scenes_search')} />
        </div>
        <div className="flex gap-1 rounded-lg border border-zinc-800 bg-zinc-900/60 p-1">
          {(['all', 'public', 'private', ...(groupsEnabled ? ['group' as const] : [])] as Filter[]).map((id) => (
            <button
              key={id}
              type="button"
              onClick={() => setFilter(id)}
              className={`rounded-md px-3 py-1.5 text-xs font-semibold transition ${filter === id ? 'bg-zinc-100 text-zinc-900' : 'text-zinc-400 hover:text-zinc-200'}`}
            >
              {t(`scenes_filter_${id}`)}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <EmptyState icon={<Layers className="h-8 w-8" />} title={t('admin_scenes_empty')} description={t('admin_scenes_empty_desc')} />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {filtered.map((scene) => {
            const isShown = shown.includes(scene.id)
            return (
              <div key={scene.id} className="rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-4 transition hover:border-zinc-700 hover:bg-zinc-900/60">
                <div className="flex items-start gap-3">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-950 text-zinc-300"><Layers className="h-4 w-4" /></div>
                  <div className="min-w-0 flex-1">
                    <h4 className="truncate text-sm font-bold text-zinc-100">{scene.label}</h4>
                    <p className="mt-0.5 truncate font-mono text-[11px] text-zinc-500">#{scene.id} · {formatCoords(scene.center)}</p>
                  </div>
                </div>
                <div className="mt-3 flex min-h-[22px] flex-wrap gap-1.5">
                  {scene.public ? <Badge tone="info" icon={<Globe className="h-3 w-3" />}>{t('scene_public')}</Badge> : <Badge icon={<Lock className="h-3 w-3" />}>{t('scene_private')}</Badge>}
                  {scene.group && (
                    <span className="inline-flex items-center gap-1 rounded-md border border-zinc-700 bg-zinc-800/80 px-1.5 py-0.5 text-[10px] font-semibold" style={{ color: scene.group.color }}>
                      <Users className="h-3 w-3" />
                      {scene.group.name}
                    </span>
                  )}
                  <Badge tone="violet" icon={<User className="h-3 w-3" />} title={scene.owner}>{scene.ownerName}</Badge>
                  {scene.territory && <Badge tone="warning" icon={<Flag className="h-3 w-3" />}>{scene.territory.label}</Badge>}
                  <Badge icon={<Box className="h-3 w-3" />}>{t('scene_props_count', { n: scene.props })}</Badge>
                  {isShown && <Badge tone="success" icon={<Eye className="h-3 w-3" />}>{t('scene_shown')}</Badge>}
                </div>
                {scene.updated && <p className="mt-3 text-[11px] text-zinc-400">{t('scene_updated', { time: formatRelativeTime(scene.updated, t) })}</p>}
                <div className="mt-3 flex items-center justify-between gap-2 border-t border-zinc-800/60 pt-3">
                  <button type="button" onClick={() => onEdit(scene)} className="inline-flex items-center gap-1.5 rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-1.5 text-xs font-semibold text-zinc-300 transition hover:border-zinc-600 hover:text-white">
                    <Pencil className="h-3.5 w-3.5" />
                    {t('btn_edit')}
                  </button>
                  <div className="flex items-center gap-0.5">
                    <IconButton onClick={() => onShow(scene, !isShown)} title={isShown ? t('scene_hide') : t('scene_show')}>
                      {isShown ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
                    </IconButton>
                    {publicEnabled && (
                      <IconButton onClick={() => onPublish(scene, !scene.public)} title={scene.public ? t('scene_unpublish') : t('scene_publish')} className={scene.public ? 'text-sky-400' : ''}>
                        <Globe className="h-3.5 w-3.5" />
                      </IconButton>
                    )}
                    <IconButton onClick={() => onTeleport(scene)} title={t('btn_teleport')}><MapPin className="h-3.5 w-3.5" /></IconButton>
                    <button
                      type="button"
                      onClick={() => confirm.request(scene.id, () => onDelete(scene))}
                      className={`flex h-7 items-center justify-center gap-1 rounded-md px-2 text-[11px] font-semibold transition ${confirm.pending === scene.id ? 'bg-rose-500/15 text-rose-300' : 'text-zinc-400 hover:bg-rose-500/10 hover:text-rose-400'}`}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                      {confirm.pending === scene.id && t('btn_confirm_delete')}
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
