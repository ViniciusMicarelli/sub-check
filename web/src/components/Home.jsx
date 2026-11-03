import { useEffect, useRef } from 'react'
import gsap from 'gsap'
import { useI18n } from '../i18n'
import { Reveal, Stagger, scrollToId, useHeroTimeline, reduceMotion } from '../motion'
import { Layout, StoreButton } from './Layout'
import { Icon } from './Icons'
import { Accordion } from './Accordion'

export function Home() {
  const { t } = useI18n()
  const heroRef = useRef(null)
  useHeroTimeline(heroRef)

  return (
    <Layout page="home">
      <Hero heroRef={heroRef} t={t} />
      <Marquee t={t} />
      <Features t={t} />
      <Showcase t={t} />
      <Steps t={t} />
      <Pricing t={t} />
      <Faq t={t} />
      <FinalCta t={t} />
    </Layout>
  )
}

/* ------------------------------ Herói ------------------------------ */

function Hero({ heroRef, t }) {
  return (
    <section className="hero" ref={heroRef}>
      <div className="container hero-grid">
        <div className="hero-copy">
          <span className="badge" data-hero="badge">
            <Icon name="sparkle" size={14} />
            {t.hero.badge}
          </span>

          <h1 data-hero="title">
            {t.hero.title} <span className="grad">{t.hero.titleAccent}</span>
          </h1>

          <p className="lead" data-hero="lead">
            {t.hero.subtitle}
          </p>

          <div className="hero-actions" data-hero="actions">
            <StoreButton label={t.hero.ctaPrimary} />
            <button type="button" className="btn ghost" onClick={() => scrollToId('#features')}>
              {t.hero.ctaSecondary}
              <Icon name="arrow" size={16} />
            </button>
          </div>

          <p className="hero-note" data-hero="note">
            {t.hero.note}
          </p>
        </div>

        <div className="hero-visual">
          <PhoneMock t={t} />
          {t.mock.chips.map((chip, index) => (
            <div className={`chip chip-${index + 1}`} data-hero="chip" key={chip.label}>
              <span className="chip-label">{chip.label}</span>
              <strong className="chip-value">{chip.value}</strong>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

function PhoneMock({ t }) {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined

    const ctx = gsap.context(() => {
      gsap.from('.mock-row', {
        x: 16,
        opacity: 0,
        duration: 0.7,
        stagger: 0.12,
        delay: 1,
        ease: 'power3.out',
      })
      gsap.from('.mock-bar', {
        scaleY: 0,
        opacity: 0,
        transformOrigin: 'bottom center',
        duration: 0.8,
        stagger: 0.07,
        delay: 1.3,
        ease: 'power2.out',
      })
    }, el)

    return () => ctx.revert()
  }, [])

  const bars = [38, 54, 30, 66, 46, 78, 58]

  return (
    <div className="phone" data-hero="phone" ref={ref} aria-hidden="true">
      <div className="phone-screen">
        <div className="phone-status">
          <span>9:41</span>
          <span className="status-icons">
            <i />
            <i />
            <i />
          </span>
        </div>

        <div className="island">
          <span className="island-dot" />
          <div className="island-text">
            <small>{t.mock.island.label}</small>
            <strong>
              {t.mock.island.service} · {t.mock.island.when}
            </strong>
          </div>
        </div>

        <div className="phone-body">
          <div className="mock-total">
            <span className="mock-total-label">{t.mock.totalLabel}</span>
            <strong className="mock-total-value">{t.mock.total}</strong>
            <span className="mock-total-sub">{t.mock.sub}</span>
          </div>

          <ul className="mock-list">
            {t.mock.items.map((item) => (
              <li className="mock-row" key={item.name}>
                <span className="mock-dot" />
                <span className="mock-name">{item.name}</span>
                <span className="mock-price">{item.price}</span>
              </li>
            ))}
          </ul>

          <div className="mock-chart">
            <span className="mock-chart-label">{t.mock.chartLabel}</span>
            <div className="bars">
              {bars.map((height, index) => (
                <span className="mock-bar" key={index} style={{ height: `${height}%` }} />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

/* ---------------------------- Marquee ------------------------------ */

function Marquee({ t }) {
  const track = [...t.marquee, ...t.marquee]

  return (
    <section className="marquee-section">
      <div className="container">
        <p className="marquee-title">{t.marqueeTitle}</p>
      </div>
      <div className="marquee">
        <div className="marquee-track">
          {track.map((label, index) => (
            <span className="marquee-item" key={`${label}-${index}`}>
              {label}
            </span>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ---------------------------- Recursos ----------------------------- */

function Features({ t }) {
  return (
    <section className="section" id="features">
      <div className="container">
        <Reveal className="section-head">
          <h2>{t.features.title}</h2>
          <p>{t.features.subtitle}</p>
        </Reveal>

        <Stagger className="feature-grid">
          {t.features.items.map((item) => (
            <article className="feature-card" key={item.title}>
              <span className="feature-icon">
                <Icon name={item.icon} size={22} />
              </span>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </Stagger>

        <Reveal className="chips-row">
          {t.features.extras.map((label) => (
            <span className="pill" key={label}>
              {label}
            </span>
          ))}
        </Reveal>
      </div>
    </section>
  )
}

/* ---------------------------- Gráficos ----------------------------- */

function Bars({ values, className = '' }) {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined

    const ctx = gsap.context(() => {
      gsap.from('.bar', {
        scaleY: 0,
        opacity: 0,
        transformOrigin: 'bottom center',
        duration: 0.8,
        stagger: 0.06,
        ease: 'power2.out',
        scrollTrigger: { trigger: el, start: 'top 88%', once: true },
      })
    }, el)

    return () => ctx.revert()
  }, [])

  return (
    <div className={`bars ${className}`} ref={ref} aria-hidden="true">
      {values.map((value, index) => (
        <span className="bar" key={index} style={{ height: `${value}%` }} />
      ))}
    </div>
  )
}

function Showcase({ t }) {
  return (
    <section className="section" id="insights">
      <div className="container">
        <Reveal className="section-head">
          <h2>{t.showcase.title}</h2>
          <p>{t.showcase.subtitle}</p>
        </Reveal>

        <Stagger className="showcase-grid">
          <article className="showcase-card">
            <h3>{t.showcase.cards[0].title}</h3>
            <p>{t.showcase.cards[0].text}</p>
            <Bars values={[34, 46, 40, 58, 52, 68, 62, 78]} />
          </article>

          <article className="showcase-card">
            <h3>{t.showcase.cards[1].title}</h3>
            <p>{t.showcase.cards[1].text}</p>
            <div className="big-number">{t.mock.chips[0].value}</div>
            <Bars values={[20, 30, 26, 38, 34, 44]} className="bars-sm" />
          </article>

          <article className="showcase-card">
            <h3>{t.showcase.cards[2].title}</h3>
            <p>{t.showcase.cards[2].text}</p>
            <Bars values={[30, 34, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74]} className="bars-sm" />
          </article>
        </Stagger>
      </div>
    </section>
  )
}

/* -------------------------- Como funciona -------------------------- */

function Steps({ t }) {
  return (
    <section className="section" id="how">
      <div className="container">
        <Reveal className="section-head">
          <h2>{t.steps.title}</h2>
          <p>{t.steps.subtitle}</p>
        </Reveal>

        <Stagger className="steps">
          {t.steps.items.map((item, index) => (
            <article className="step" key={item.title}>
              <span className="step-number">{index + 1}</span>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </Stagger>
      </div>
    </section>
  )
}

/* ------------------------------- Pro ------------------------------- */

function Pricing({ t }) {
  return (
    <section className="section" id="pro">
      <div className="container">
        <Reveal className="section-head">
          <h2>{t.pricing.title}</h2>
          <p>{t.pricing.subtitle}</p>
        </Reveal>

        <Reveal className="price-wrap">
          <article className="price-card">
            <span className="price-badge">{t.pricing.badge}</span>

            <div className="price-value">
              <strong>{t.pricing.price}</strong>
              <span>{t.pricing.period}</span>
            </div>

            <ul className="price-list">
              {t.pricing.items.map((item) => (
                <li key={item}>
                  <span className="tick">
                    <Icon name="check" size={13} strokeWidth={2.6} />
                  </span>
                  {item}
                </li>
              ))}
            </ul>

            <StoreButton className="btn primary btn-block" label={t.pricing.cta} />
            <p className="price-note">{t.pricing.note}</p>
          </article>
        </Reveal>
      </div>
    </section>
  )
}

/* ------------------------------- FAQ ------------------------------- */

function Faq({ t }) {
  return (
    <section className="section" id="faq">
      <div className="container narrow">
        <Reveal className="section-head">
          <h2>{t.faq.title}</h2>
          <p>{t.faq.subtitle}</p>
        </Reveal>

        <Reveal>
          <Accordion items={t.faq.items} defaultOpen={0} />
        </Reveal>
      </div>
    </section>
  )
}

/* ------------------------------- CTA ------------------------------- */

function FinalCta({ t }) {
  return (
    <section className="section">
      <div className="container">
        <Reveal className="cta-band">
          <div className="cta-glow" aria-hidden="true" />
          <h2>{t.cta.title}</h2>
          <p>{t.cta.text}</p>
          <StoreButton className="btn light" label={t.cta.button} />
        </Reveal>
      </div>
    </section>
  )
}
