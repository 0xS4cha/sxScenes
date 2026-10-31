import { AnimatePresence, motion } from 'motion/react'
import { AlertTriangle, CheckCircle2 } from 'lucide-react'
import type { Feedback } from '../hooks/useFeedback'
import { useTranslation } from '../hooks/useTranslation'

export function FeedbackBanner({ feedback }: { feedback: Feedback | null }) {
  const { t } = useTranslation()

  return (
    <AnimatePresence>
      {feedback && (
        <motion.div
          initial={{ opacity: 0, y: -6 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -6 }}
          className={`flex items-center gap-2 rounded-lg border px-3 py-2 text-xs font-medium ${feedback.tone === 'error' ? 'border-rose-500/30 bg-rose-500/10 text-rose-300' : 'border-emerald-500/30 bg-emerald-500/10 text-emerald-300'}`}
        >
          {feedback.tone === 'error' ? <AlertTriangle className="h-3.5 w-3.5 shrink-0" /> : <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />}
          {t(feedback.key, feedback.replacements)}
        </motion.div>
      )}
    </AnimatePresence>
  )
}
