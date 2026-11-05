import { useLayoutEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { SplitText } from 'gsap/SplitText'
import { Icon } from '../components/Icons'
import { StoreButton } from '../components/Layout'
import { reduceMotion, scrollToId } from '../motion'
import { home, money } from './content'
import { Eyebrow, SplitHeading, spotlight, useMagnetic } from './fx'
import { Simulator } from './Simulator'

gsap.registerPlugin(ScrollTrigger, SplitText)

/* -------------------------------- Herói -------------------------------- */

export function Hero({ lang }) {
  const c = home[lang].hero
  const ref = useRef(null)
  const ctaRef = useRef(null)
  useMagnetic(ctaRef, 0.25)

  useLayoutEffect(() => {
    const root = ref.current
    if (!root || reduceMotion()) return undefined

    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: 'power3.out' } })
      const split = SplitText.create('[data-h=l1]', { type: 'words,chars' })

      tl.from('[data-h=badge]', { y: -18, opacity: 0, duration: 0.7 })
      tl.from(split.chars, { yPercent: 120, rotate: 8, opacity: 0, duration: 0.9, stagger: 0.028, ease: 'power4.out' }, 0.15)
      tl.from('[data-h=l2]', { yPercent: 120, duration: 1, ease: 'power4.out' }, 0.5)
      tl.from('[data-h=sub]', { y: 24, opacity: 0, duration: 0.8 }, 0.85)
      tl.from('[data-h=actions] > *', { y: 22, opacity: 0, stagger: 0.1, duration: 0.7 }, 1.0)
      tl.from('[data-h=note]', { opacity: 0, duration: 0.8 }, 1.2)
      tl.from('[data-h=phone]', { y: 140, rotate: -5, scale: 0.9, opacity: 0, duration: 1.4, ease: 'expo.out' }, 0.3)
      tl.from('[data-h=halo]', { scale: 0.4, opacity: 0, duration: 1.6, ease: 'expo.out' }, 0.2)
      tl.from('[data-h=chip]', { scale: 0.5, opacity: 0, y: 30, stagger: 0.18, duration: 0.8, ease: 'back.out(2)' }, 1.3)
      tl.from('[data-h=scroll]', { opacity: 0, duration: 0.8 }, 2)

      // Respiração do brilho atrás do celular.
      gsap.to('[data-h=halo]', { scale: 1.06, duration: 4, yoyo: true, repeat: -1, ease: 'sine.inOut' })
      // Chips flutuando.
      gsap.utils.toArray('[data-h=chip]').forEach((chip, i) => {
        gsap.to(chip, { y: i % 2 ? -12 : 12, duration: 2.6 + i * 0.4, yoyo: true, repeat: -1, ease: 'sine.inOut' })
      })

      // O celular sobe e inclina um pouco enquanto a seção sai da tela.
      gsap.to('[data-h=phone-wrap]', {
        yPercent: -9,
        rotate: 3,
        ease: 'none',
        scrollTrigger: { trigger: root, start: 'top top', end: 'bottom top', scrub: 0.6 },
      })
      gsap.to('[data-h=copy]', {
        yPercent: -12,
        opacity: 0.2,
        ease: 'none',
        scrollTrigger: { trigger: root, start: '20% top', end: 'bottom top', scrub: true },
      })

      // Paralaxe com o mouse.
      if (window.matchMedia('(hover: hover)').matches) {
        const depth = gsap.utils.toArray('[data-depth]').map((el) => ({
          el,
          d: parseFloat(el.dataset.depth),
          x: gsap.quickTo(el, 'xPercent', { duration: 0.9, ease: 'power3.out' }),
          y: gsap.quickTo(el, 'yPercent', { duration: 0.9, ease: 'power3.out' }),
        }))
        const move = (e) => {
          const nx = e.clientX / window.innerWidth - 0.5
          const ny = e.clientY / window.innerHeight - 0.5
          depth.forEach(({ x, y, d }) => {
            x(nx * d * 14)
            y(ny * d * 14)
          })
        }
        root.addEventListener('pointermove', move)
        return () => root.removeEventListener('pointermove', move)
      }
      return undefined
    }, root)

    return () => ctx.revert()
  }, [])

  return (
    <section className="lp-hero" ref={ref}>
      <div className="lp-container lp-hero-grid">
        <div className="lp-hero-copy" data-h="copy">
          <span className="lp-badge" data-h="badge">
            <Icon name="sparkle" size={14} />
            {c.badge}
          </span>

          <h1 className="lp-h1">
            <span className="lp-line" aria-hidden="false"><span data-h="l1">{c.title}</span></span>
            <span className="lp-line"><span className="lp-shimmer" data-h="l2">{c.accent}</span></span>
          </h1>

          <p className="lp-lead" data-h="sub">{c.sub}</p>

          <div className="lp-actions" data-h="actions">
            <span ref={ctaRef} className="lp-magnet">
              <StoreButton label={c.primary} />
            </span>
            <button type="button" className="btn ghost" onClick={() => scrollToId('#how')}>
              {c.secondary}
              <Icon name="arrow" size={16} />
            </button>
          </div>

          <p className="lp-note" data-h="note">{c.note}</p>
        </div>

        <div className="lp-hero-visual">
          <span className="lp-halo" data-h="halo" aria-hidden="true" />
          <div className="lp-phone-wrap" data-h="phone-wrap">
            <div data-h="phone" data-depth="0.4">
              <Simulator sceneId="dash" lang={lang} loopDelay={5} className="lp-hero-phone" />
            </div>
          </div>
          {c.chips.map((chip, i) => (
            <div className={`lp-chip lp-chip-${i + 1} tone-${chip.tone}`} data-h="chip" data-depth={i % 2 ? 1.6 : -1.3} key={chip.k}>
              <span>{chip.k}</span>
              <b>{chip.v}</b>
            </div>
          ))}
        </div>
      </div>

      <div className="lp-scroll" data-h="scroll" aria-hidden="true">
        <span>{c.scroll}</span>
        <i />
      </div>
    </section>
  )
}

/* ------------------------------- Marquee ------------------------------- */

function Row({ items, reverse }) {
  const ref = useRef(null)

  useLayoutEffect(() => {
    const track = ref.current
    if (!track || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      const dir = reverse ? -1 : 1
      const tween = gsap.fromTo(track, { xPercent: reverse ? -50 : 0 }, { xPercent: reverse ? 0 : -50, duration: 38, ease: 'none', repeat: -1 })
      // A velocidade acompanha a rolagem da página.
      ScrollTrigger.create({
        onUpdate(self) {
          const boost = 1 + Math.min(Math.abs(self.getVelocity()) / 260, 7)
          gsap.to(tween, { timeScale: boost, duration: 0.25, overwrite: true })
          gsap.to(tween, { timeScale: 1, duration: 1.2, delay: 0.25, ease: 'power2.out' })
        },
      })
      void dir
    }, track)
    return () => ctx.revert()
  }, [reverse])

  const list = [...items, ...items, ...items, ...items]
  return (
    <div className="lp-marquee-row">
      <div className="lp-marquee-track" ref={ref}>
        {list.map((item, i) => (
          <span className="lp-pill" key={`${item}-${i}`}>{item}</span>
        ))}
      </div>
    </div>
  )
}

export function Marquee({ lang }) {
  const c = home[lang]
  return (
    <section className="lp-marquee" aria-label={c.marqueeLabel}>
      <p>{c.marqueeLabel}</p>
      <Row items={c.marquee} />
      <Row items={[...c.marquee].reverse()} reverse />
    </section>
  )
}

/* ----------------------------- Calculadora ----------------------------- */

export function Calculator({ lang }) {
  const c = home[lang].calc
  const [count, setCount] = useState(8)
  const [avg, setAvg] = useState(35)
  const root = useRef(null)
  const yearRef = useRef(null)
  const state = useRef({ year: 0, month: 0, day: 0, cut: 0 })
  const refs = { month: useRef(null), day: useRef(null), cut: useRef(null) }

  const month = count * avg
  const target = { year: month * 12, month, day: month / 30, cut: Math.min(2, count) * avg * 12 }

  // Os números "rolam" até o novo valor em vez de trocar de repente.
  useLayoutEffect(() => {
    const write = () => {
      const st = state.current
      if (yearRef.current) yearRef.current.textContent = money(st.year, lang, 0)
      if (refs.month.current) refs.month.current.textContent = money(st.month, lang, 0)
      if (refs.day.current) refs.day.current.textContent = money(st.day, lang, 2)
      if (refs.cut.current) refs.cut.current.textContent = money(st.cut, lang, 0)
    }
    if (reduceMotion()) {
      state.current = { ...target }
      write()
      return undefined
    }
    const tween = gsap.to(state.current, { ...target, duration: 0.7, ease: 'power3.out', onUpdate: write })
    return () => tween.kill()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [count, avg, lang])

  useLayoutEffect(() => {
    const el = root.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      gsap.from('[data-c=in]', {
        y: 50,
        opacity: 0,
        duration: 0.9,
        ease: 'power3.out',
        stagger: 0.12,
        scrollTrigger: { trigger: el, start: 'top 75%', once: true },
      })
    }, el)
    return () => ctx.revert()
  }, [])

  const tokens = Array.from({ length: count }, (_, i) => i)

  return (
    <section className="lp-section lp-calc" ref={root}>
      <div className="lp-container lp-calc-grid">
        <div>
          <Eyebrow>{c.eyebrow}</Eyebrow>
          <SplitHeading className="lp-h2">{c.title}</SplitHeading>
          <p className="lp-lead lp-lead-sm" data-c="in">{c.text}</p>

          <div className="lp-slider" data-c="in">
            <label>
              <span>{c.count}</span>
              <b>{count}</b>
            </label>
            <input type="range" min="1" max="20" value={count} onChange={(e) => setCount(+e.target.value)} style={{ '--p': `${((count - 1) / 19) * 100}%` }} aria-label={c.count} />
          </div>
          <div className="lp-slider" data-c="in">
            <label>
              <span>{c.avg}</span>
              <b>{money(avg, lang, 0)}</b>
            </label>
            <input type="range" min="10" max="100" step="5" value={avg} onChange={(e) => setAvg(+e.target.value)} style={{ '--p': `${((avg - 10) / 90) * 100}%` }} aria-label={c.avg} />
          </div>
          <p className="lp-fine" data-c="in">{c.note}</p>
        </div>

        <div className="lp-calc-card" data-c="in" onPointerMove={spotlight}>
          <div className="lp-calc-big">
            <small>{c.perYear}</small>
            <strong ref={yearRef}>{money(target.year, lang, 0)}</strong>
          </div>
          <div className="lp-calc-sub">
            <div><small>{c.perMonth}</small><b ref={refs.month}>{money(target.month, lang, 0)}</b></div>
            <div><small>{c.perDay}</small><b ref={refs.day}>{money(target.day, lang, 2)}</b></div>
          </div>
          <div className="lp-tokens" aria-hidden="true">
            {tokens.map((i) => (
              <span key={i} className={i >= count - 2 ? 'cut' : ''} style={{ animationDelay: `${i * 30}ms` }} />
            ))}
          </div>
          <p className="lp-calc-save">
            {c.cut} <b ref={refs.cut}>{money(target.cut, lang, 0)}</b> {c.cutSuffix}.
          </p>
        </div>
      </div>
    </section>
  )
}
