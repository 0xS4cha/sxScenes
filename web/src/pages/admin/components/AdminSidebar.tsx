import { motion } from 'motion/react'
import { ChevronLeft, ChevronRight, History, Layers, LayoutDashboard, Users, X } from 'lucide-react'
import { useTranslation } from '../../../hooks/useTranslation'
import type { AdminCategory } from '../../../types/admin'
import { fetchNui } from '../../../utils/fetchNui'

interface AdminSidebarProps {
  active: AdminCategory
  onSelect: (category: AdminCategory) => void
  counts: Partial<Record<AdminCategory, number>>
  framework: string
  storage: string
  collapsed: boolean
  onToggle: () => void
}

export const NAV_ICONS: Record<AdminCategory, typeof Layers> = {
  overview: LayoutDashboard,
  scenes: Layers,
  players: Users,
  activity: History,
}

export function AdminSidebar({ active, onSelect, counts, framework, storage, collapsed, onToggle }: AdminSidebarProps) {
  const { t } = useTranslation()
  const categories = Object.keys(NAV_ICONS) as AdminCategory[]

  return (
    <aside className={`relative flex shrink-0 flex-col border-r border-zinc-800/80 bg-zinc-950/80 transition-all duration-300 ${collapsed ? 'w-20' : 'w-60'}`}>
      <div className="flex h-16 items-center justify-between border-b border-zinc-800/80 px-4">
        <div className="flex items-center gap-3 overflow-hidden">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-zinc-700/60 bg-zinc-900 shadow-sm">
            <Layers className="h-5 w-5 text-zinc-200" />
          </div>
          {!collapsed && (
            <motion.div initial={{ opacity: 0, x: -6 }} animate={{ opacity: 1, x: 0 }} className="flex flex-col overflow-hidden">
              <span className="truncate text-xs font-semibold uppercase tracking-wider text-zinc-400">sxScenes</span>
              <span className="truncate text-sm font-bold text-zinc-100">{t('admin_title')}</span>
            </motion.div>
          )}
        </div>
        <button type="button" onClick={onToggle} className="flex h-7 w-7 items-center justify-center rounded-md text-zinc-400 transition hover:bg-zinc-800/60 hover:text-zinc-200">
          {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </button>
      </div>

      <nav className="flex-1 space-y-1.5 p-3">
        {!collapsed && <p className="mb-2 px-2 text-[10px] font-medium uppercase tracking-widest text-zinc-500">{t('admin_nav_section')}</p>}
        {categories.map((id) => {
          const Icon = NAV_ICONS[id]
          const isActive = active === id
          return (
            <button
              key={id}
              type="button"
              onClick={() => onSelect(id)}
              title={collapsed ? t(`admin_nav_${id}`) : undefined}
              className={`relative flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all ${isActive ? 'font-semibold text-zinc-100' : 'text-zinc-400 hover:bg-zinc-900/60 hover:text-zinc-200'}`}
            >
              {isActive && <motion.div layoutId="activeSidebarIndicator" className="absolute inset-0 rounded-lg border border-zinc-700/80 bg-zinc-900 shadow-inner" transition={{ type: 'spring', stiffness: 350, damping: 30 }} />}
              <Icon className={`relative z-10 h-4 w-4 ${isActive ? 'text-zinc-100' : 'text-zinc-400'}`} />
              {!collapsed && <span className="relative z-10 flex-1 truncate text-left">{t(`admin_nav_${id}`)}</span>}
              {!collapsed && counts[id] !== undefined && (
                <span className="relative z-10 rounded-full border border-zinc-700 bg-zinc-800 px-2 py-0.5 text-[11px] font-semibold text-zinc-300">{counts[id]}</span>
              )}
            </button>
          )
        })}
      </nav>

      <div className="space-y-2 border-t border-zinc-800/80 p-3">
        {!collapsed && (
          <div className="space-y-1.5 rounded-lg border border-zinc-800/60 bg-zinc-900/40 p-2.5 text-[11px]">
            <div className="flex items-center justify-between text-zinc-400">
              <span className="flex items-center gap-1.5"><span className="h-2 w-2 animate-pulse rounded-full bg-emerald-500" />{t('admin_framework')}</span>
              <span className="font-mono uppercase text-zinc-300">{framework}</span>
            </div>
            <div className="flex items-center justify-between text-zinc-400">
              <span className="pl-3.5">{t('admin_storage')}</span>
              <span className="font-mono uppercase text-zinc-300">{storage}</span>
            </div>
          </div>
        )}
        <button type="button" onClick={() => void fetchNui('close')} className={`flex w-full items-center justify-center gap-2 rounded-lg border border-zinc-800 bg-zinc-900/80 py-2 text-xs font-medium text-zinc-300 transition hover:border-zinc-700 hover:bg-zinc-800 hover:text-white ${collapsed ? 'px-2' : 'px-3'}`}>
          <X className="h-4 w-4 text-zinc-400" />
          {!collapsed && <span>{t('btn_close')} (ESC)</span>}
        </button>
      </div>
    </aside>
  )
}
