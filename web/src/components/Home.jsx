import { useEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { useI18n } from '../i18n'
import { Reveal, Stagger, scrollToId, useHeroTimeline, reduceMotion } from '../motion'
import { BrandMark, Layout, StoreButton } from './Layout'
import { Icon } from './Icons'
import { Accordion } from './Accordion'

gsap.registerPlugin(ScrollTrigger)

export function Home() {
  const { t } = useI18n()
  const heroRef = useRef(null)
  useHeroTimeline(heroRef)

  return (
    <Layout page="home">
      <Hero heroRef={heroRef} t={t} />
      <Marquee t={t} />
      <Features t={t} />
      <AppStory t={t} />
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

/* ------------------------- Telas do app (mock) ------------------------- */

/** Cores dos cartões de métrica, na ordem do conteúdo. */
const METRIC_TINTS = ['brand', 'success', 'warning', 'info']

/** Moldura do iPhone: barra de status, (Ilha Dinâmica) e a tela ativa. */
function PhoneFrame({ children, island = null, className = '', frameRef, ...rest }) {
  return (
    <div className={`phone ${className}`.trim()} ref={frameRef} aria-hidden="true" {...rest}>
      <div className="phone-screen">
        <div className="phone-status">
          <span>9:41</span>
          <span className="status-icons">
            <i />
            <i />
            <i />
          </span>
        </div>

        {island}

        <div className="phone-body">{children}</div>
      </div>
    </div>
  )
}

/** Atividade ao vivo na Ilha Dinâmica. */
function Island({ m }) {
  return (
    <div className="island">
      <span className="island-dot" />
      <div className="island-text">
        <small>{m.island.label}</small>
        <strong>
          {m.island.service} · {m.island.when}
        </strong>
      </div>
    </div>
  )
}

/** Painel: card do total, métricas e próximas cobranças. */
function DashboardScreen({ m, name }) {
  return (
    <div className="screen">
      <div className="mock-hero-card">
        {name ? (
          <p className="mock-greeting">
            {m.greetingPrefix} <span className="mock-greeting-name">{name}</span>
          </p>
        ) : null}
        <p className="mock-hero-label">{m.totalLabel}</p>
        <strong className="mock-hero-value">{m.total}</strong>
        <p className="mock-hero-meta">
          <span>{m.yearly}</span>
          <i className="mock-hero-sep" />
          <span>{m.active}</span>
        </p>
        <span className="mock-next-pill">{m.nextPill}</span>
      </div>

      <div className="mock-metrics">
        {m.metrics.map((metric, index) => (
          <div className="mock-metric" key={metric.label}>
            <span className={`mock-metric-icon tint-${METRIC_TINTS[index % METRIC_TINTS.length]}`}>
              <Icon name={metric.icon} size={14} strokeWidth={2} />
            </span>
            <strong className="mock-metric-value">{metric.value}</strong>
            <span className="mock-metric-label">{metric.label}</span>
          </div>
        ))}
      </div>

      <div className="mock-block">
        <div className="mock-block-head">
          <h4>{m.upcomingTitle}</h4>
          <span className="mock-period">{m.upcomingPeriod}</span>
        </div>

        <ul className="mock-upcoming">
          {m.upcoming.map((row) => (
            <li className={`mock-svc-row${row.level === 'warn' ? ' is-warn' : ''}`} key={row.name}>
              <span className="mock-svc">
                <Icon name={row.icon} size={15} strokeWidth={1.9} />
              </span>
              <span className="mock-row-main">
                <strong>{row.name}</strong>
                <small>{row.when}</small>
              </span>
              <span className="mock-row-end">
                <strong>{row.price}</strong>
                <small>{row.days}</small>
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}

/** Onboarding, passo 1: boas-vindas com o campo de nome. */
function OnboardingScreen({ m, name }) {
  return (
    <div className="screen screen-onboarding">
      <div className="ob-top">
        <span className="ob-skip">{m.skip}</span>
      </div>

      <span className="ob-progress">
        <i />
      </span>

      <div className="ob-art">
        <span className="ob-art-glow" />
        <BrandMark size={62} />
      </div>

      <div className="ob-copy">
        <h3 className="ob-title">{m.title}</h3>
        <p className="ob-body">{m.body}</p>
      </div>

      <div className={`ob-field${name ? ' is-filled' : ''}`}>
        <span className="ob-field-text">{name || m.namePlaceholder}</span>
        <span className="ob-caret" />
      </div>

      <p className="ob-helper">{m.nameHelper}</p>

      <span className="ob-cta">{m.next}</span>
    </div>
  )
}

/** Nova assinatura: ícone e dados detectados automaticamente. */
function AddScreen({ m }) {
  return (
    <div className="screen screen-add">
      <div className="form-nav">
        <span>{m.cancel}</span>
        <strong>{m.title}</strong>
        <span className="form-nav-save">{m.save}</span>
      </div>

      <div className="form-block">
        <span className="form-label">{m.iconTitle}</span>
        <div className="form-hero">
          <span className="form-hero-tile">
            <Icon name="play" size={20} strokeWidth={1.9} />
          </span>
          <span className="form-hero-note">
            <Icon name="check" size={12} strokeWidth={2.6} />
            {m.detected}
          </span>
        </div>
      </div>

      <div className="form-block">
        <span className="form-label">{m.details}</span>
        <ul className="form-rows">
          <FormRow label={m.nameLabel} value={m.nameValue} />
          <FormRow label={m.valueLabel} value={m.valueValue} />
          <FormRow label={m.frequencyLabel} value={m.frequencyValue} />
        </ul>
      </div>

      <div className="form-block">
        <ul className="form-rows">
          <FormRow label={m.dateLabel} value={m.dateValue} />
          <FormRow label={m.categoryTitle} value={m.categoryValue} />
        </ul>
      </div>

      <span className="form-cta">{m.save}</span>
    </div>
  )
}

function FormRow({ label, value }) {
  return (
    <li className="form-row">
      <span className="form-row-label">{label}</span>
      <span className="form-row-value">{value}</span>
    </li>
  )
}

function PhoneMock({ t }) {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined

    const ctx = gsap.context(() => {
      gsap.from('.mock-hero-card', {
        y: 18,
        opacity: 0,
        duration: 0.8,
        delay: 0.9,
        ease: 'power3.out',
      })
      gsap.from('.mock-metric', {
        y: 14,
        opacity: 0,
        duration: 0.7,
        stagger: 0.09,
        delay: 1.1,
        ease: 'power3.out',
      })
      gsap.from('.mock-svc-row', {
        x: 16,
        opacity: 0,
        duration: 0.7,
        stagger: 0.12,
        delay: 1.3,
        ease: 'power3.out',
      })
    }, el)

    return () => ctx.revert()
  }, [])

  return (
    <PhoneFrame frameRef={ref} island={<Island m={t.mock} />} data-hero="phone">
      <DashboardScreen m={t.mock} />
    </PhoneFrame>
  )
}

/* --------------------- O app se monta na rolagem --------------------- */

function AppStory({ t }) {
  const sectionRef = useRef(null)
  const swapRef = useRef(null)
  const [name, setName] = useState('')
  const [active, setActive] = useState(0)
  const still = useRef(reduceMotion()).current

  // Cada cena troca a tela do app quando entra na faixa de leitura.
  useEffect(() => {
    const el = sectionRef.current
    if (!el || still) return undefined

    const scenes = Array.from(el.querySelectorAll('[data-scene]'))
    const triggers = scenes.map((scene, index) =>
      ScrollTrigger.create({
        trigger: scene,
        start: 'top 62%',
        end: 'bottom 62%',
        onEnter: () => setActive(index),
        onEnterBack: () => setActive(index),
      }),
    )

    return () => triggers.forEach((trigger) => trigger.kill())
  }, [still])

  // Trocar o idioma muda a altura do texto: recalcula as faixas de leitura.
  useEffect(() => {
    if (still) return undefined
    const id = window.setTimeout(() => ScrollTrigger.refresh(), 80)
    return () => window.clearTimeout(id)
  }, [t, still])

  // Entrada da tela nova dentro do aparelho.
  useEffect(() => {
    const el = swapRef.current
    if (!el || still) return undefined
    const tween = gsap.fromTo(
      el,
      { y: 24, opacity: 0, scale: 0.985 },
      { y: 0, opacity: 1, scale: 1, duration: 0.55, ease: 'power3.out' },
    )
    return () => tween.kill()
  }, [active, still])

  const screens = ['onboarding', 'add', 'dashboard']
  const current = still ? 'dashboard' : screens[active]

  return (
    <section className="section story" id="story" ref={sectionRef}>
      <div className="container">
        <Reveal className="section-head">
          <h2>{t.story.title}</h2>
          <p>{t.story.subtitle}</p>
        </Reveal>

        <div className="story-grid">
          <div className="story-copy">
            <Reveal className="story-name">
              <label htmlFor="story-name">{t.story.namePrompt}</label>
              <input
                id="story-name"
                className="story-input"
                type="text"
                value={name}
                maxLength={18}
                autoComplete="off"
                spellCheck="false"
                placeholder={t.story.namePlaceholder}
                onChange={(event) => setName(event.target.value)}
              />
              <p className="story-note">{t.story.nameNote}</p>
            </Reveal>

            <p className="story-hint">
              {t.story.hint}
              <Icon name="chevron" size={14} />
            </p>

            <ol className="story-scenes">
              {t.story.scenes.map((scene, index) => (
                <li
                  className={`story-scene${still || index === active ? ' is-active' : ''}`}
                  data-scene
                  key={scene.title}
                >
                  <span className="story-scene-index">{index + 1}</span>
                  <h3>{scene.title}</h3>
                  <p>{scene.text}</p>
                </li>
              ))}
            </ol>
          </div>

          <div className="story-visual">
            <div className="story-sticky">
              <PhoneFrame className="phone-story">
                <div className="screen-swap" ref={swapRef} data-screen={current}>
                  {current === 'onboarding' && <OnboardingScreen m={t.mock.onboarding} name={name} />}
                  {current === 'add' && <AddScreen m={t.mock.add} />}
                  {current === 'dashboard' && <DashboardScreen m={t.mock} name={name} />}
                </div>
              </PhoneFrame>
              <p className="story-final">{t.story.finalNote}</p>
            </div>
          </div>
        </div>
      </div>
    </section>
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
