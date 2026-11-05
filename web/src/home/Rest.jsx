import { useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { SplitText } from 'gsap/SplitText'
import { Accordion } from '../components/Accordion'
import { Icon } from '../components/Icons'
import { StoreButton } from '../components/Layout'
import { content } from '../content'
import { reduceMotion } from '../motion'
import { home } from './content'
import { Eyebrow, SplitHeading, spotlight, useMagnetic, useStaggerIn } from './fx'

gsap.registerPlugin(ScrollTrigger, SplitText)

/* --------------------------------- Bento --------------------------------- */

function Art({ id, pay }) {
  switch (id) {
    case 'island':
      return (
        <div className="art art-island">
          <div className="pill">
            <i className="dot" />
            <span>Netflix</span>
            <em>3d</em>
            <div className="more"><b>R$ 55,90</b><u>{pay}</u></div>
          </div>
        </div>
      )
    case 'siri':
      return (
        <div className="art art-siri">
          {Array.from({ length: 15 }, (_, i) => <i key={i} style={{ animationDelay: `${(i % 7) * 0.11}s` }} />)}
        </div>
      )
    case 'import':
      return (
        <div className="art art-import">
          {['Netflix', 'Spotify', 'iCloud+'].map((n, i) => (
            <div key={n} style={{ animationDelay: `${i * 0.5}s` }}>
              <Icon name="check" size={12} strokeWidth={3} />
              <span>{n}</span>
              <em />
            </div>
          ))}
        </div>
      )
    case 'fx':
      return (
        <div className="art art-fx">
          <svg viewBox="0 0 160 60" aria-hidden="true">
            <path d="M4 8 C 40 10, 60 24, 90 30 S 140 48, 156 52" pathLength="1" />
          </svg>
          <b>−20%</b>
        </div>
      )
    case 'alerts':
      return (
        <div className="art art-alerts">
          <span className="ring" />
          <span className="ring r2" />
          <Icon name="bell" size={30} strokeWidth={1.8} />
        </div>
      )
    case 'insights':
      return (
        <div className="art art-insights">
          {[38, 62, 48, 80, 58, 92].map((h, i) => <i key={i} style={{ '--h': `${h}%`, animationDelay: `${i * 0.12}s` }} />)}
        </div>
      )
    case 'sync':
      return (
        <div className="art art-sync">
          <span className="dev a" />
          <Icon name="cloud" size={26} strokeWidth={1.7} />
          <span className="dev b" />
        </div>
      )
    default:
      return (
        <div className="art art-privacy">
          <span className="pulse" />
          <Icon name="lock" size={30} strokeWidth={1.8} />
        </div>
      )
  }
}

export function Bento({ lang }) {
  const c = home[lang].bento
  const ref = useRef(null)
  useStaggerIn(ref, '[data-b=card]', { y: 50, stagger: 0.08, start: 'top 78%' })

  return (
    <section id="features" className="lp-section lp-bento">
      <div className="lp-container">
        <div className="lp-head">
          <Eyebrow>{c.eyebrow}</Eyebrow>
          <SplitHeading className="lp-h2">{c.title}</SplitHeading>
        </div>
        <div className="lp-bento-grid" ref={ref}>
          {c.items.map((item) => (
            <article className={`lp-card b-${item.id}`} data-b="card" key={item.id} onPointerMove={spotlight}>
              <Art id={item.id} pay={home[lang].sim.pay} />
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ------------------------------- Manifesto ------------------------------- */

export function Manifesto({ lang }) {
  const c = home[lang].manifesto
  const ref = useRef(null)

  useLayoutEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      SplitText.create(el.querySelector('p'), {
        type: 'words',
        autoSplit: true,
        onSplit(self) {
          return gsap.fromTo(
            self.words,
            { opacity: 0.14 },
            {
              opacity: 1,
              stagger: 0.12,
              ease: 'none',
              scrollTrigger: { trigger: el, start: 'top 72%', end: 'bottom 55%', scrub: 0.6 },
            },
          )
        },
      })
    }, el)
    return () => ctx.revert()
  }, [])

  return (
    <section className="lp-manifesto" ref={ref}>
      <div className="lp-container">
        <p>{c.text}</p>
      </div>
    </section>
  )
}

/* -------------------------------- Preços -------------------------------- */

export function Pricing({ lang }) {
  const c = home[lang].pricing
  const p = content[lang].pricing
  const ref = useRef(null)
  const btn = useRef(null)
  useMagnetic(btn, 0.2)
  useStaggerIn(ref, '[data-p=in]', { y: 50, stagger: 0.12, start: 'top 78%' })

  return (
    <section id="pro" className="lp-section lp-pricing">
      <div className="lp-container" ref={ref}>
        <div className="lp-head">
          <Eyebrow>{c.eyebrow}</Eyebrow>
          <SplitHeading className="lp-h2">{p.title}</SplitHeading>
          <p className="lp-lead lp-lead-sm" data-p="in">{p.subtitle}</p>
        </div>

        <div className="lp-trial" data-p="in">
          <span className="lp-trial-seal"><b>7</b><small>{home[lang].sim.trialDays}</small></span>
          <div>
            <b>{c.trial}</b>
            <p>{c.trialText}</p>
          </div>
        </div>

        <div className="lp-price-grid">
          <article className="lp-plan" data-p="in" onPointerMove={spotlight}>
            <h3>{c.free.name}</h3>
            <div className="lp-price"><strong>{c.free.price}</strong><span>{c.free.sub}</span></div>
            <ul>
              {c.free.items.map((i) => <li key={i}><Icon name="check" size={16} strokeWidth={2.6} />{i}</li>)}
            </ul>
          </article>

          <article className="lp-plan lp-plan-pro" data-p="in" onPointerMove={spotlight}>
            <span className="lp-plan-tag">{c.proLabel}</span>
            <h3>SubCheck Pro</h3>
            <div className="lp-price"><strong>{p.price}</strong><span>{c.once}</span></div>
            <ul>
              {p.items.map((i) => <li key={i}><Icon name="check" size={16} strokeWidth={2.6} />{i}</li>)}
            </ul>
            <span ref={btn} className="lp-magnet"><StoreButton label={c.cta} /></span>
          </article>
        </div>
      </div>
    </section>
  )
}

/* --------------------------------- Dúvidas --------------------------------- */

export function Faq({ lang }) {
  const c = home[lang]
  const ref = useRef(null)
  useStaggerIn(ref, '[data-f=in]', { y: 30, stagger: 0.1, start: 'top 82%' })
  return (
    <section id="faq" className="lp-section lp-faq">
      <div className="lp-container lp-faq-wrap" ref={ref}>
        <SplitHeading className="lp-h2 lp-h2-sm">{c.faqTitle}</SplitHeading>
        <div data-f="in"><Accordion items={content[lang].faq.items} defaultOpen={0} /></div>
      </div>
    </section>
  )
}

/* ------------------------------- Chamada final ------------------------------- */

export function FinalCta({ lang }) {
  const c = home[lang].cta
  const ref = useRef(null)
  const btn = useRef(null)
  useMagnetic(btn, 0.3)

  useLayoutEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      gsap.from('[data-z=ring]', { scale: 0.6, opacity: 0, duration: 1.6, ease: 'expo.out', scrollTrigger: { trigger: el, start: 'top 75%', once: true } })
      gsap.to('[data-z=ring]', { rotate: 360, duration: 40, ease: 'none', repeat: -1 })
      gsap.from('[data-z=in]', { y: 40, opacity: 0, stagger: 0.12, duration: 0.9, ease: 'power3.out', scrollTrigger: { trigger: el, start: 'top 72%', once: true } })
    }, el)
    return () => ctx.revert()
  }, [])

  return (
    <section className="lp-final" ref={ref}>
      <div className="lp-container">
        <div className="lp-final-card">
          <span className="lp-final-ring" data-z="ring" aria-hidden="true" />
          <SplitHeading className="lp-h2 lp-final-title">{c.title}</SplitHeading>
          <p className="lp-lead lp-lead-sm" data-z="in">{c.text}</p>
          <span ref={btn} className="lp-magnet" data-z="in"><StoreButton label={c.button} /></span>
        </div>
      </div>
    </section>
  )
}
