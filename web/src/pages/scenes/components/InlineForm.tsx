import { useState } from 'react'
import type { ReactNode } from 'react'
import { Button, TextInput } from '../../../components/ui'
import { useTranslation } from '../../../hooks/useTranslation'

interface InlineFormProps {
  icon: ReactNode
  placeholder: string
  submitLabel: string
  maxLength?: number
  mono?: boolean
  onSubmit: (value: string) => Promise<boolean>
  onCancel: () => void
}

export function InlineForm({ icon, placeholder, submitLabel, maxLength, mono = false, onSubmit, onCancel }: InlineFormProps) {
  const { t } = useTranslation()
  const [value, setValue] = useState('')
  const [busy, setBusy] = useState(false)

  const submit = async () => {
    const trimmed = value.trim()
    if (!trimmed || busy) return
    setBusy(true)
    const ok = await onSubmit(trimmed)
    setBusy(false)
    if (ok) setValue('')
  }

  return (
    <form
      className="flex items-center gap-2 rounded-xl border border-zinc-800 bg-zinc-900/60 p-2"
      onSubmit={(e) => {
        e.preventDefault()
        void submit()
      }}
    >
      <span className="pl-1 text-zinc-500">{icon}</span>
      <TextInput
        autoFocus
        value={value}
        maxLength={maxLength}
        placeholder={placeholder}
        onChange={(e) => setValue(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Escape') {
            e.stopPropagation()
            onCancel()
          }
        }}
        className={`border-transparent bg-transparent px-1 ${mono ? 'font-mono uppercase' : ''}`}
      />
      <Button variant="ghost" onClick={onCancel}>{t('btn_cancel')}</Button>
      <Button variant="primary" type="submit" disabled={!value.trim() || busy}>{submitLabel}</Button>
    </form>
  )
}
