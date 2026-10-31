import { useEffect, useMemo, useRef, useState } from 'react'
import { Loader2, PackagePlus, Search, Wand2 } from 'lucide-react'
import { Button, TextInput } from '../../../components/ui'
import { useCatalog } from '../../../hooks/useCatalog'
import { useTranslation } from '../../../hooks/useTranslation'

const MAX_RESULTS = 150
const PREVIEW_DELAY = 250

interface CatalogTabProps {
  customModels: boolean
  disabled: boolean
  onPreview: (model: string | null) => void
  onPlace: (model: string) => void
}

export function CatalogTab({ customModels, disabled, onPreview, onPlace }: CatalogTabProps) {
  const { t } = useTranslation()
  const { catalog, loading } = useCatalog()
  const [category, setCategory] = useState<string>('all')
  const [search, setSearch] = useState('')
  const [selected, setSelected] = useState<string | null>(null)
  const [custom, setCustom] = useState('')
  const previewTimer = useRef<number | undefined>(undefined)

  const models = useMemo(() => {
    const query = search.trim().toLowerCase()
    const source = category === 'all' ? catalog.flatMap((c) => c.models) : catalog.find((c) => c.id === category)?.models ?? []
    return query ? source.filter((model) => model.includes(query)) : source
  }, [catalog, category, search])

  useEffect(() => () => {
    window.clearTimeout(previewTimer.current)
    onPreview(null)
  }, [onPreview])

  const select = (model: string) => {
    setSelected(model)
    window.clearTimeout(previewTimer.current)
    previewTimer.current = window.setTimeout(() => onPreview(model), PREVIEW_DELAY)
  }

  const label = (id: string) => {
    const key = `catalog_${id}`
    const text = t(key)
    return text === key ? id : text
  }

  const total = catalog.reduce((sum, c) => sum + c.models.length, 0)

  return (
    <div className="flex h-full flex-col gap-3">
      <div className="relative">
        <Search className="absolute top-1/2 left-3 h-3.5 w-3.5 -translate-y-1/2 text-zinc-500" />
        <TextInput value={search} onChange={(e) => setSearch(e.target.value)} placeholder={t('catalog_search', { n: total })} className="pl-9" />
      </div>

      <div className="flex flex-wrap gap-1.5">
        {[{ id: 'all', count: total }, ...catalog.map((c) => ({ id: c.id, count: c.models.length }))].map((entry) => (
          <button
            key={entry.id}
            type="button"
            onClick={() => setCategory(entry.id)}
            className={`rounded-md border px-2 py-1 text-[11px] font-semibold transition ${category === entry.id ? 'border-zinc-600 bg-zinc-100 text-zinc-900' : 'border-zinc-800 bg-zinc-900/60 text-zinc-400 hover:text-zinc-200'}`}
          >
            {label(entry.id)} <span className="opacity-60">{entry.count}</span>
          </button>
        ))}
      </div>

      <div className="min-h-0 flex-1 overflow-auto rounded-lg border border-zinc-800/80 bg-zinc-950/60">
        {loading ? (
          <div className="flex h-full items-center justify-center text-zinc-500"><Loader2 className="h-5 w-5 animate-spin" /></div>
        ) : models.length === 0 ? (
          <p className="py-8 text-center text-xs text-zinc-500">{t('catalog_empty')}</p>
        ) : (
          <>
            {models.slice(0, MAX_RESULTS).map((model) => (
              <button
                key={model}
                type="button"
                onClick={() => select(model)}
                onDoubleClick={() => !disabled && onPlace(model)}
                className={`flex w-full items-center justify-between gap-2 border-b border-zinc-900 px-3 py-1.5 text-left font-mono text-[11px] transition last:border-b-0 ${selected === model ? 'bg-zinc-800 text-zinc-100' : 'text-zinc-400 hover:bg-zinc-900 hover:text-zinc-200'}`}
              >
                <span className="truncate">{model}</span>
                {selected === model && <PackagePlus className="h-3.5 w-3.5 shrink-0 text-emerald-400" />}
              </button>
            ))}
            {models.length > MAX_RESULTS && <p className="px-3 py-2 text-center text-[10px] text-zinc-500">{t('catalog_more', { n: models.length - MAX_RESULTS })}</p>}
          </>
        )}
      </div>

      <Button variant="primary" icon={<PackagePlus className="h-3.5 w-3.5" />} disabled={!selected || disabled} onClick={() => selected && onPlace(selected)} className="py-2">
        {selected ? t('catalog_place', { model: selected }) : t('catalog_select')}
      </Button>

      {customModels && (
        <form
          className="flex items-center gap-2"
          onSubmit={(e) => {
            e.preventDefault()
            const model = custom.trim().toLowerCase()
            if (model && !disabled) onPlace(model)
          }}
        >
          <TextInput value={custom} onChange={(e) => setCustom(e.target.value)} placeholder={t('catalog_custom_placeholder')} className="font-mono" />
          <Button type="submit" icon={<Wand2 className="h-3.5 w-3.5" />} disabled={!custom.trim() || disabled} className="shrink-0 py-2">
            {t('catalog_custom_place')}
          </Button>
        </form>
      )}
    </div>
  )
}
