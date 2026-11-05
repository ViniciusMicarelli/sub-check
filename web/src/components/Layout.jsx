import { useEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { useI18n } from '../i18n'
import { scrollToId, useSmoothScroll, reduceMotion } from '../motion'
import { APP_STORE_URL, CONTACT_EMAIL } from '../content'
import { Icon } from './Icons'

/** Mesma marca do ícone do app, em SVG. */
export function BrandMark({ size = 30 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      className="brandmark"
      aria-hidden="true"
      focusable="false"
    >
      <defs>
        <linearGradient id="brandmark-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#5457DB" />
          <stop offset="1" stopColor="#9B4AF0" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="15" fill="url(#brandmark-g)" />
      <path d="M32 11a21 21 0 1 1-18.2 10.5" fill="none" stroke="#4DE8AA" strokeWidth="7" strokeLinecap="round" />
      <path d="M11 17.5 21.5 15l-2.5 10.5Z" fill="#4DE8AA" stroke="#4DE8AA" strokeWidth="2.4" strokeLinejoin="round" />
      <circle cx="32" cy="32" r="12.5" fill="#fff" />
      <path d="m26 32.5 4.4 4.4 7.6-8.8" fill="none" stroke="#5457DB" strokeWidth="3.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

/** Botão para a App Store; enquanto não houver link, mostra “em breve”. */
export function StoreButton({ className = 'btn primary', label, withIcon = true }) {
  const { t } = useI18n()

  if (APP_STORE_URL) {
    return (
      <a className={className} href={APP_STORE_URL} target="_blank" rel="noreferrer">
        {withIcon && <Icon name="apple" size={18} />}
        <span>{label}</span>
      </a>
    )
  }

  return (
    <span className={`${className} is-soon`} role="note">
      {withIcon && <Icon name="apple" size={18} />}
      <span>{label}</span>
      <span className="soon-pill">{t.soon}</span>
    </span>
  )
}

function Background() {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined

    const ctx = gsap.context(() => {
      gsap.to('.blob-a', {
        xPercent: 14,
        yPercent: -10,
        duration: 18,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
      })
      gsap.to('.blob-b', {
        xPercent: -16,
        yPercent: 12,
        duration: 22,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
      })
      gsap.to('.blob-c', {
        xPercent: 10,
        yPercent: 14,
        duration: 26,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
      })
    }, el)

    return () => ctx.revert()
  }, [])

  return (
    <div className="bg" ref={ref} aria-hidden="true">
      <div className="bg-grid" />
      <div className="blob blob-a" />
      <div className="blob blob-b" />
      <div className="blob blob-c" />
      <div className="bg-fade" />
    </div>
  )
}

function ScrollProgress() {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el) return undefined
    const update = () => {
      const doc = document.documentElement
      const max = doc.scrollHeight - doc.clientHeight
      el.style.transform = `scaleX(${max > 0 ? doc.scrollTop / max : 0})`
    }
    update()
    window.addEventListener('scroll', update, { passive: true })
    window.addEventListener('resize', update)
    return () => {
      window.removeEventListener('scroll', update)
      window.removeEventListener('resize', update)
    }
  }, [])

  return (
    <div className="progress" aria-hidden="true">
      <span ref={ref} />
    </div>
  )
}

function LanguageToggle() {
  const { lang, setLang } = useI18n()
  return (
    <div className="lang-toggle" role="group" aria-label="Idioma / Language">
      <button type="button" className={lang === 'pt' ? 'on' : ''} onClick={() => setLang('pt')}>
        PT
      </button>
      <button type="button" className={lang === 'en' ? 'on' : ''} onClick={() => setLang('en')}>
        EN
      </button>
    </div>
  )
}

function Nav({ page }) {
  const { t } = useI18n()
  const isHome = page === 'home'
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 10)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const sections = [
    ['#features', t.nav.features],
    ['#how', t.nav.how],
    ['#pro', t.nav.pro],
    ['#faq', t.nav.faq],
  ]

  const handleAnchor = (event, hash) => {
    if (!isHome) return
    event.preventDefault()
    scrollToId(hash)
  }

  return (
    <header className={`nav${scrolled ? ' is-scrolled' : ''}`}>
      <div className="container nav-inner">
        <a className="brand" href="index.html" aria-label="SubCheck">
          <BrandMark />
          <span>SubCheck</span>
        </a>

        <nav className="nav-links" aria-label="Principal">
          {sections.map(([hash, label]) => (
            <a key={hash} href={isHome ? hash : `index.html${hash}`} onClick={(e) => handleAnchor(e, hash)}>
              {label}
            </a>
          ))}
          <a href="support.html" className={page === 'support' ? 'is-active' : ''}>
            {t.nav.support}
          </a>
        </nav>

        <div className="nav-actions">
          <LanguageToggle />
          <StoreButton className="btn primary btn-sm" label={t.nav.download} withIcon={false} />
        </div>
      </div>
    </header>
  )
}

function Footer() {
  const { t } = useI18n()

  return (
    <footer className="footer">
      <div className="container footer-top">
        <div className="footer-brand">
          <a className="brand" href="index.html">
            <BrandMark />
            <span>SubCheck</span>
          </a>
          <p>{t.footer.tagline}</p>
        </div>

        <div className="footer-cols">
          <div className="footer-col">
            <h4>{t.footer.productTitle}</h4>
            <a href="index.html#features">{t.nav.features}</a>
            <a href="index.html#how">{t.nav.how}</a>
            <a href="index.html#pro">{t.nav.pro}</a>
          </div>
          <div className="footer-col">
            <h4>{t.footer.legalTitle}</h4>
            <a href="privacy.html">{t.nav.privacy}</a>
            <a href="terms.html">{t.nav.terms}</a>
          </div>
          <div className="footer-col">
            <h4>{t.footer.supportTitle}</h4>
            <a href="support.html">{t.nav.support}</a>
            <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>
          </div>
        </div>
      </div>

      <div className="container footer-bottom">
        <span>{t.footer.rights}</span>
        <LanguageToggle />
      </div>
    </footer>
  )
}

export function Layout({ page, children }) {
  useSmoothScroll()

  return (
    <>
      <Background />
      <ScrollProgress />
      <Nav page={page} />
      <main id="content">{children}</main>
      <Footer />
    </>
  )
}
