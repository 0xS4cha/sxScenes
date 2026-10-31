import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { Move3d, RotateCw } from 'lucide-react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { useTranslation } from '../hooks/useTranslation'
import type { GizmoState } from '../types/scenes'

const KEYS: { key: string; label: string }[] = [
  { key: 'Z', label: 'gizmo_translate' },
  { key: 'R', label: 'gizmo_rotate' },
  { key: 'Q', label: 'gizmo_local' },
  { key: 'ALT', label: 'gizmo_ground' },
  { key: 'RMB', label: 'gizmo_camera' },
  { key: 'ENTER', label: 'gizmo_confirm' },
  { key: '⌫', label: 'gizmo_cancel' },
]

export function GizmoOverlay() {
  const { t } = useTranslation()
  const [state, setState] = useState<GizmoState | null>(null)

  useNuiEvent<GizmoState>('gizmo', (next) => setState(next?.active ? next : null))

  const ModeIcon = state?.mode === 'rotate' ? RotateCw : Move3d

  return (
    <AnimatePresence>
      {state && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 20 }}
          className="pointer-events-none fixed bottom-8 left-1/2 flex -translate-x-1/2 items-center gap-3 rounded-2xl border border-white/10 bg-zinc-950/90 px-4 py-3 shadow-2xl backdrop-blur-md"
        >
          <div className="flex items-center gap-2 border-r border-zinc-800 pr-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-700 bg-zinc-900 text-zinc-100">
              <ModeIcon className="h-4 w-4" />
            </div>
            <div>
              <p className="text-xs font-bold text-zinc-100">{t(`gizmo_mode_${state.mode}`)}</p>
              <p className="text-[10px] text-zinc-500">{state.relative ? t('gizmo_axes_local') : t('gizmo_axes_world')}</p>
            </div>
          </div>
          {KEYS.map((entry) => (
            <div key={entry.key} className="flex items-center gap-1.5">
              <kbd className="rounded-md border border-zinc-700 bg-zinc-900 px-1.5 py-0.5 font-mono text-[10px] font-bold text-zinc-200">{entry.key}</kbd>
              <span className="text-[11px] text-zinc-400">{t(entry.label)}</span>
            </div>
          ))}
        </motion.div>
      )}
    </AnimatePresence>
  )
}
