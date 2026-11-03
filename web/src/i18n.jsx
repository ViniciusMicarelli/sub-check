import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { content } from './content'

const STORAGE_KEY = 'subcheck-lang'

const LanguageContext = createContext(null)

function detect() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'pt' || saved === 'en') return saved
  } catch {
    /* localStorage pode estar indisponível */
  }
  const nav = (navigator.language || 'en').toLowerCase()
  return nav.startsWith('pt') ? 'pt' : 'en'
}

export function LanguageProvider({ children }) {
  const [lang, setLang] = useState(detect)

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, lang)
    } catch {
      /* ignora */
    }
    document.documentElement.lang = content[lang].code
  }, [lang])

  const value = useMemo(
    () => ({
      lang,
      t: content[lang],
      setLang,
      toggle: () => setLang((current) => (current === 'pt' ? 'en' : 'pt')),
    }),
    [lang],
  )

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>
}

export function useI18n() {
  const ctx = useContext(LanguageContext)
  if (!ctx) throw new Error('useI18n precisa estar dentro de <LanguageProvider>')
  return ctx
}
