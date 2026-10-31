import { useState, useEffect, useCallback } from 'react'
import type { NuiMessage, PhraseDictionary, SetLocaleData, SetTranslationsData } from '../types/nui'

export type Locale = string

interface TranslationSnapshot {
  locale: Locale
  translations: PhraseDictionary
}

let currentLocale: Locale = 'en'
let currentTranslations: PhraseDictionary = {}
const listeners = new Set<(snapshot: TranslationSnapshot) => void>()

function normalizeLocale(locale: string): Locale {
  const normalized = (locale || '').toLowerCase().trim()
  if (normalized == '') {
    return 'en'
  }

  return normalized
}

function notifyListeners() {
  const snapshot: TranslationSnapshot = {
    locale: currentLocale,
    translations: currentTranslations,
  }
  listeners.forEach((listener) => listener(snapshot))
}

export function setGlobalLocale(locale: Locale) {
  currentLocale = normalizeLocale(locale)
  notifyListeners()
}

function setGlobalTranslations(locale: Locale, translations: PhraseDictionary) {
  currentLocale = normalizeLocale(locale)
  currentTranslations = translations || {}
  notifyListeners()
}

window.addEventListener('message', (event: MessageEvent<NuiMessage<SetTranslationsData | SetLocaleData>>) => {
  const { action, data } = event.data ?? {}

  if (action === 'setTranslations') {
    const payload = data as SetTranslationsData
    if (payload && payload.locale && payload.translations) {
      setGlobalTranslations(payload.locale, payload.translations)
    }
  } else if (action === 'setLocale') {
    const payload = data as SetLocaleData
    if (payload && payload.locale) {
      setGlobalLocale(payload.locale)
    }
  }
})

export function useTranslation() {
  const [locale, setLocale] = useState<Locale>(currentLocale)
  const [translations, setTranslations] = useState<PhraseDictionary>(currentTranslations)

  useEffect(() => {
    const handler = (snapshot: TranslationSnapshot) => {
      setLocale(snapshot.locale)
      setTranslations(snapshot.translations)
    }

    listeners.add(handler)

    return () => {
      listeners.delete(handler)
    }
  }, [])

  const t = useCallback((key: string, replacements?: Record<string, string | number>): string => {
    let text = translations[key] || key
    if (replacements) {
      Object.entries(replacements).forEach(([k, v]) => {
        text = text.replace(new RegExp(`{${k}}`, 'g'), String(v))
      })
    }
    return text
  }, [translations])

  return { t, locale, setLocale: setGlobalLocale }
}
