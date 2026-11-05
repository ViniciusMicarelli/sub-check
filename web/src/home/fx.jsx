import { useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { SplitText } from 'gsap/SplitText'
import { reduceMotion } from '../motion'

gsap.registerPlugin(ScrollTrigger, SplitText)

/** Título que sobe linha por linha, com máscara, quando entra na tela. */
export function SplitHeading({ as: Tag = 'h2', className = '', delay = 0, children }) {
  const ref = useRef(null)

  useLayoutEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      SplitText.create(el, {
        type: 'lines',
        mask: 'lines',
        autoSplit: true,
        onSplit(self) {
          return gsap.from(self.lines, {
            yPercent: 110,
            duration: 1.05,
            ease: 'power4.out',
            stagger: 0.1,
            delay,
            scrollTrigger: { trigger: el, start: 'top 88%', once: true },
          })
        },
      })
    }, el)
    return () => ctx.revert()
  }, [delay])

  return (
    <Tag ref={ref} className={className}>
      {children}
    </Tag>
  )
}

/** Entra de baixo para cima, em sequência, quando a seção aparece. */
export function useStaggerIn(ref, selector, { y = 40, stagger = 0.09, start = 'top 82%' } = {}) {
  useLayoutEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      gsap.from(el.querySelectorAll(selector), {
        y,
        opacity: 0,
        duration: 0.9,
        ease: 'power3.out',
        stagger,
        scrollTrigger: { trigger: el, start, once: true },
      })
    }, el)
    return () => ctx.revert()
  }, [ref, selector, y, stagger, start])
}

/** O elemento é puxado levemente em direção ao cursor. */
export function useMagnetic(ref, strength = 0.35) {
  useLayoutEffect(() => {
    const el = ref.current
    if (!el || reduceMotion() || !window.matchMedia('(hover: hover)').matches) return undefined
    const x = gsap.quickTo(el, 'x', { duration: 0.5, ease: 'power3.out' })
    const y = gsap.quickTo(el, 'y', { duration: 0.5, ease: 'power3.out' })
    const move = (e) => {
      const r = el.getBoundingClientRect()
      x((e.clientX - (r.left + r.width / 2)) * strength)
      y((e.clientY - (r.top + r.height / 2)) * strength)
    }
    const leave = () => {
      x(0)
      y(0)
    }
    el.addEventListener('pointermove', move)
    el.addEventListener('pointerleave', leave)
    return () => {
      el.removeEventListener('pointermove', move)
      el.removeEventListener('pointerleave', leave)
    }
  }, [ref, strength])
}

/** Luz que segue o cursor dentro de um cartão (usa --mx/--my no CSS). */
export function spotlight(e) {
  const r = e.currentTarget.getBoundingClientRect()
  e.currentTarget.style.setProperty('--mx', `${e.clientX - r.left}px`)
  e.currentTarget.style.setProperty('--my', `${e.clientY - r.top}px`)
}

export function Eyebrow({ children }) {
  return <span className="lp-eyebrow">{children}</span>
}
