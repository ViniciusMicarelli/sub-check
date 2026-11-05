import { useLayoutEffect, useRef, useState } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { Icon } from '../components/Icons'
import { reduceMotion, scrollToY } from '../motion'
import { home } from './content'
import { Eyebrow, SplitHeading } from './fx'
import { Simulator } from './Simulator'

gsap.registerPlugin(ScrollTrigger)

/** Pixels de rolagem para cada passo do tutorial. */
const PER_STEP = 560

/**
 * O tutorial: a seção fica fixa na tela e cada trecho de rolagem avança um
 * passo. O celular mostra a cena correspondente; os passos também podem ser
 * tocados diretamente.
 */
export function Tutorial({ lang }) {
  const c = home[lang].tutorial
  const steps = c.steps
  const [active, setActive] = useState(0)
  const [playKey, setPlayKey] = useState(0)
  const root = useRef(null)
  const trigger = useRef(null)
  const current = useRef(0)

  useLayoutEffect(() => {
    const el = root.current
    if (!el || reduceMotion()) return undefined

    const ctx = gsap.context(() => {
      trigger.current = ScrollTrigger.create({
        trigger: el.querySelector('[data-t=stage]'),
        start: 'top top+=68',
        end: () => `+=${steps.length * PER_STEP}`,
        pin: true,
        anticipatePin: 1,
        onUpdate(self) {
          const i = Math.min(steps.length - 1, Math.floor(self.progress * steps.length))
          if (i !== current.current) {
            current.current = i
            setActive(i)
          }
        },
      })

      gsap.from('[data-t=phone]', {
        y: 90,
        opacity: 0,
        scale: 0.94,
        duration: 1.1,
        ease: 'power3.out',
        scrollTrigger: { trigger: el, start: 'top 70%', once: true },
      })
    }, el)

    return () => {
      trigger.current = null
      ctx.revert()
    }
  }, [steps.length])

  const goTo = (i) => {
    const t = trigger.current
    if (i === active) {
      setPlayKey((k) => k + 1)
      return
    }
    if (!t) {
      current.current = i
      setActive(i)
      return
    }
    scrollToY(t.start + ((i + 0.5) / steps.length) * (t.end - t.start))
  }

  const progress = ((active + 1) / steps.length) * 100

  return (
    <section id="how" className="lp-tut" ref={root}>
      <div className="lp-tut-stage" data-t="stage">
        <div className="lp-container lp-tut-grid">
          <div className="lp-tut-left">
            <Eyebrow>{c.eyebrow}</Eyebrow>
            <SplitHeading className="lp-h2 lp-h2-sm">{c.title}</SplitHeading>
            <p className="lp-lead lp-lead-sm lp-tut-text">{c.text}</p>

            <ol className="lp-steps">
              <span className="lp-rail" aria-hidden="true"><i style={{ height: `${progress}%` }} /></span>
              {steps.map((step, i) => (
                <li className={`lp-step${i === active ? ' on' : ''}${i < active ? ' past' : ''}`} key={step.id}>
                  <button type="button" onClick={() => goTo(i)} aria-current={i === active ? 'step' : undefined}>
                    <span className="n">{i < active ? <Icon name="check" size={12} strokeWidth={3} /> : i + 1}</span>
                    <span className="lab">{step.label}</span>
                    {step.pro && <span className="lp-protag lp-protag-sm">Pro</span>}
                  </button>
                  <div className="body">
                    <div>
                      <h3>{step.title}</h3>
                      <p>{step.text}</p>
                    </div>
                  </div>
                </li>
              ))}
            </ol>
          </div>

          <div className="lp-tut-right">
            <div className="lp-tut-phone" data-t="phone">
              <span className="lp-halo lp-halo-sm" aria-hidden="true" />
              <Simulator sceneId={steps[active].id} lang={lang} playKey={playKey} loopDelay={4} className="lp-tut-sim" />
            </div>

            <div className="lp-caption" aria-live="polite">
              <b>{steps[active].title}{steps[active].pro && <span className="lp-protag lp-protag-sm">Pro</span>}</b>
              <p>{steps[active].text}</p>
            </div>

            <div className="lp-tut-controls">
              <div className="lp-dots" role="tablist" aria-label={c.title}>
                {steps.map((step, i) => (
                  <button type="button" key={step.id} className={i === active ? 'on' : ''} aria-label={step.label} aria-selected={i === active} role="tab" onClick={() => goTo(i)} />
                ))}
              </div>
              <button type="button" className="lp-replay" onClick={() => setPlayKey((k) => k + 1)}>
                <Icon name="arrow" size={14} strokeWidth={2.2} /> {c.replay}
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
