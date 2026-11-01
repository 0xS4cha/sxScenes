import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { RefreshCw } from 'lucide-react'
import { FeedbackBanner } from '../../components/FeedbackBanner'
import { Button } from '../../components/ui'
import { useAdminData } from '../../hooks/useAdminData'
import { useFeedback } from '../../hooks/useFeedback'
import { useTranslation } from '../../hooks/useTranslation'
import type { AdminCategory } from '../../types/admin'
import { ActivityList } from './components/ActivityList'
import { AdminSidebar, NAV_ICONS } from './components/AdminSidebar'
import { OverviewView } from './components/OverviewView'
import { PlayersView } from './components/PlayersView'
import { ScenesView } from './components/ScenesView'

export function AdminPanel({ openCount }: { openCount: number }) {
  const { t } = useTranslation()
  const [category, setCategory] = useState<AdminCategory>(() => {
    const view = new URLSearchParams(window.location.search).get('view') as AdminCategory | null
    return import.meta.env.DEV && view && view in NAV_ICONS ? view : 'overview'
  })
  const [collapsed, setCollapsed] = useState(false)
  const [search, setSearch] = useState('')
  const admin = useAdminData(openCount)
  const { feedback, report } = useFeedback()
  const HeaderIcon = NAV_ICONS[category]

  return (
    <div className="flex h-full w-full overflow-hidden bg-zinc-950 font-sans text-zinc-100 antialiased">
      <AdminSidebar
        active={category}
        onSelect={setCategory}
        counts={{ scenes: admin.scenes.length, players: admin.players.length }}
        framework={admin.framework}
        storage={admin.storage}
        collapsed={collapsed}
        onToggle={() => setCollapsed((prev) => !prev)}
      />

      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex h-16 shrink-0 items-center justify-between gap-4 border-b border-zinc-800/80 bg-zinc-950/60 px-6 backdrop-blur-md">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-900 text-zinc-300">
              <HeaderIcon className="h-4 w-4" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-zinc-100">{t(`admin_nav_${category}`)}</h2>
              <p className="text-[11px] text-zinc-400">{t(`admin_header_${category}_sub`)}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <FeedbackBanner feedback={feedback} />
            <Button onClick={() => void admin.refresh()} disabled={admin.loading} icon={<RefreshCw className={`h-3.5 w-3.5 ${admin.loading ? 'animate-spin' : ''}`} />}>
              {t('btn_refresh')}
            </Button>
          </div>
        </header>

        <main className="flex-1 overflow-auto p-6">
          <AnimatePresence mode="wait">
            <motion.div key={category} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.2 }}>
              {category === 'overview' && (
                <OverviewView
                  counts={{ scenes: admin.scenes.length, players: admin.players.length }}
                  stats={admin.stats}
                  settings={admin.settings}
                  activity={admin.activity}
                  onSelect={setCategory}
                />
              )}
              {category === 'scenes' && (
                <ScenesView
                  scenes={admin.scenes}
                  shown={admin.shown}
                  publicEnabled={admin.settings.publicEnabled}
                  groupsEnabled={admin.settings.groups}
                  search={search}
                  onSearch={setSearch}
                  onShow={async (scene, value) => report(await admin.show(scene.id, value))}
                  onEdit={async (scene) => report(await admin.edit(scene.id))}
                  onPublish={async (scene, value) => report(await admin.publish(scene.id, value), value ? 'notice_scene_published' : 'notice_scene_unpublished')}
                  onTeleport={(scene) => admin.teleport(scene.center)}
                  onDelete={async (scene) => report(await admin.remove(scene.id), 'notice_scene_deleted')}
                />
              )}
              {category === 'players' && (
                <PlayersView
                  players={admin.players}
                  maxScenes={admin.settings.scenes}
                  onScenes={(player) => {
                    setSearch(player.identifier ?? player.name)
                    setCategory('scenes')
                  }}
                  onClear={async (player) => player.identifier && report(await admin.clearOwner(player.identifier), 'notice_owner_cleared', { name: player.name })}
                />
              )}
              {category === 'activity' && <ActivityList entries={admin.activity} />}
            </motion.div>
          </AnimatePresence>
        </main>
      </div>
    </div>
  )
}
