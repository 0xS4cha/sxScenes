import { useState } from 'react'
import { Eraser, Layers, ShieldCheck, Users } from 'lucide-react'
import { Badge, EmptyState, IconButton } from '../../../components/ui'
import { useConfirm } from '../../../hooks/useConfirm'
import { useTranslation } from '../../../hooks/useTranslation'
import type { AdminPlayer } from '../../../types/admin'
import { SearchBar } from './SearchBar'

interface PlayersViewProps {
  players: AdminPlayer[]
  maxScenes: number
  onScenes: (player: AdminPlayer) => void
  onClear: (player: AdminPlayer) => void
}

export function PlayersView({ players, maxScenes, onScenes, onClear }: PlayersViewProps) {
  const { t } = useTranslation()
  const [search, setSearch] = useState('')
  const confirm = useConfirm<number>()
  const query = search.trim().toLowerCase()
  const filtered = players.filter((p) => !query || p.name.toLowerCase().includes(query) || String(p.id) === query || (p.identifier ?? '').toLowerCase().includes(query))

  return (
    <div className="flex flex-col gap-5">
      <SearchBar value={search} onChange={setSearch} placeholder={t('players_search')} />
      {filtered.length === 0 ? (
        <EmptyState icon={<Users className="h-8 w-8" />} title={t('players_empty')} description={t('players_empty_desc')} />
      ) : (
        <div className="space-y-2">
          {filtered.map((player) => {
            const ratio = maxScenes > 0 ? Math.min(100, (player.scenes / maxScenes) * 100) : 0
            return (
              <div key={player.id} className="flex items-center gap-4 rounded-xl border border-zinc-800/80 bg-zinc-900/40 px-4 py-3">
                <span className="flex h-8 w-10 shrink-0 items-center justify-center rounded-md bg-zinc-800 font-mono text-xs font-bold text-zinc-300">{player.id}</span>
                <div className="min-w-0 flex-1">
                  <p className="flex items-center gap-2 truncate text-sm font-semibold text-zinc-100">
                    {player.name}
                    {player.admin && <Badge tone="warning" icon={<ShieldCheck className="h-3 w-3" />}>{t('players_admin')}</Badge>}
                  </p>
                  <p className="truncate font-mono text-[10px] text-zinc-500">{player.identifier}</p>
                </div>
                <div className="w-40 shrink-0 space-y-1">
                  <p className="text-right text-[11px] text-zinc-400">{t('players_scenes', { n: player.scenes, max: maxScenes })}</p>
                  <div className="h-1.5 overflow-hidden rounded-full bg-zinc-800">
                    <div className={`h-full rounded-full ${ratio >= 100 ? 'bg-amber-500' : 'bg-emerald-500'}`} style={{ width: `${ratio}%` }} />
                  </div>
                </div>
                <div className="flex shrink-0 items-center gap-0.5">
                  <IconButton onClick={() => onScenes(player)} title={t('players_view_scenes')} disabled={player.scenes === 0}><Layers className="h-3.5 w-3.5" /></IconButton>
                  <button
                    type="button"
                    disabled={player.scenes === 0}
                    onClick={() => confirm.request(player.id, () => onClear(player))}
                    className={`flex h-7 items-center gap-1 rounded-md px-2 text-[11px] font-semibold transition disabled:opacity-40 ${confirm.pending === player.id ? 'bg-rose-500/15 text-rose-300' : 'text-zinc-400 hover:bg-rose-500/10 hover:text-rose-400'}`}
                    title={t('players_clear')}
                  >
                    <Eraser className="h-3.5 w-3.5" />
                    {confirm.pending === player.id && t('btn_confirm_delete')}
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
