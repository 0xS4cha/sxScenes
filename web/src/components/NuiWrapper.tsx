import { motion } from 'motion/react'
import type { ReactNode } from 'react'
import { useEscapeKey } from '../hooks/useEscapeKey'
import { fetchNui } from '../utils/fetchNui'

interface NuiWrapperProps {
  visible: boolean
  side?: boolean
  onEscape?: () => void
  children: ReactNode
}

const close = () => void fetchNui('close')

export function NuiWrapper({ visible, side = false, onEscape, children }: NuiWrapperProps) {
  useEscapeKey(onEscape ?? close, visible)

  if (side) {
    return (
      <motion.div
        className={`fixed inset-y-0 right-0 flex items-stretch p-6 ${visible ? '' : 'pointer-events-none'}`}
        initial={false}
        animate={visible ? { opacity: 1, x: 0 } : { opacity: 0, x: 24 }}
        transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
      >
        <div className="flex w-[420px] flex-col overflow-hidden rounded-2xl border border-white/10 bg-zinc-950/95 shadow-2xl backdrop-blur-md">
          {visible && children}
        </div>
      </motion.div>
    )
  }

  return (
    <motion.div
      className={`fixed inset-0 flex items-center justify-center bg-black/60 p-6 ${visible ? '' : 'pointer-events-none'}`}
      initial={false}
      animate={{ opacity: visible ? 1 : 0 }}
      transition={{ duration: 0.2 }}
    >
      <motion.div
        className="flex h-[min(90vh,780px)] w-[min(94vw,1200px)] flex-col overflow-hidden rounded-2xl border border-white/10 bg-zinc-950/95 shadow-2xl backdrop-blur-md"
        initial={false}
        animate={visible ? { opacity: 1, y: 0, scale: 1 } : { opacity: 0, y: 16, scale: 0.98 }}
        transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
      >
        {visible && children}
      </motion.div>
    </motion.div>
  )
}
