import type { ReactNode } from 'react'
import { X } from 'lucide-react'

interface PanelHeaderProps {
  icon: ReactNode
  title: ReactNode
  subtitle?: ReactNode
  actions?: ReactNode
  onClose: () => void
}

export function PanelHeader({ icon, title, subtitle, actions, onClose }: PanelHeaderProps) {
  return (
    <header className="flex shrink-0 items-center justify-between gap-3 border-b border-zinc-800/80 px-5 py-4">
      <div className="flex min-w-0 items-center gap-3">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-zinc-700/60 bg-zinc-900 text-zinc-200">{icon}</div>
        <div className="min-w-0">
          <div className="truncate text-sm font-bold text-zinc-100">{title}</div>
          {subtitle && <div className="truncate text-[11px] text-zinc-500">{subtitle}</div>}
        </div>
      </div>
      <div className="flex shrink-0 items-center gap-1.5">
        {actions}
        <button type="button" onClick={onClose} className="flex h-7 w-7 items-center justify-center rounded-md text-zinc-400 transition hover:bg-zinc-800/80 hover:text-zinc-100">
          <X className="h-4 w-4" />
        </button>
      </div>
    </header>
  )
}
