import { Plus, Search } from 'lucide-react'
import { Button } from '../../../components/ui'

export function SearchBar({ value, onChange, placeholder, actionLabel, onAction }: { value: string; onChange: (value: string) => void; placeholder: string; actionLabel?: string; onAction?: () => void }) {
  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
      <div className="relative flex-1">
        <Search className="absolute top-1/2 left-3.5 h-4 w-4 -translate-y-1/2 text-zinc-500" />
        <input
          type="text"
          value={value}
          placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          className="w-full rounded-lg border border-zinc-800 bg-zinc-900/60 py-2.5 pr-4 pl-10 text-xs text-zinc-200 placeholder-zinc-500 transition focus:border-zinc-700 focus:outline-none"
        />
      </div>
      {actionLabel && onAction && (
        <Button variant="primary" icon={<Plus className="h-4 w-4" />} onClick={onAction} className="py-2.5">{actionLabel}</Button>
      )}
    </div>
  )
}
