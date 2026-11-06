import { createContext, useContext, useLayoutEffect, useRef } from 'react'
import gsap from 'gsap'
import { reduceMotion } from '../../motion'

/** Velocidade e progresso da cena, vindos do `Simulator`. */
export const SimContext = createContext({ speed: 1, onProgress: null })

/**
 * Ferramentas para montar o "tutorial": um dedo que toca nos elementos,
 * digitação, contadores. Tudo é feito sobre uma timeline do GSAP, então cada
 * cena é só uma lista de passos legível.
 */
export function createKit(screen, tl) {
  const cursor = screen.querySelector('.sim-cursor')
  const dot = cursor.querySelector('i')
  const ring = cursor.querySelector('b')

  /** Centro de um elemento, relativo à tela do celular. */
  const center = (sel) => {
    const el = typeof sel === 'string' ? screen.querySelector(sel) : sel
    const r = el.getBoundingClientRect()
    const s = screen.getBoundingClientRect()
    return { x: r.left - s.left + r.width / 2, y: r.top - s.top + r.height / 2 }
  }

  return {
    cursor,
    center,

    /** Move o dedo até `sel` e toca. Devolve o instante logo depois do toque. */
    tap(sel, at, { dx = 0, dy = 0, move = 0.85 } = {}) {
      tl.to(cursor, { opacity: 1, duration: 0.25 }, at)
      tl.to(
        cursor,
        { x: () => center(sel).x + dx, y: () => center(sel).y + dy, duration: move, ease: 'power2.inOut' },
        at,
      )
      const t = at + move
      tl.to(dot, { scale: 0.7, duration: 0.09, ease: 'power1.in' }, t)
      tl.to(dot, { scale: 1, duration: 0.22, ease: 'back.out(3)' }, t + 0.09)
      tl.fromTo(ring, { scale: 0.3, opacity: 0.6 }, { scale: 1.7, opacity: 0, duration: 0.55, ease: 'power2.out' }, t)
      return t + 0.3
    },

    /** Esconde o dedo. */
    hideCursor(at) {
      tl.to(cursor, { opacity: 0, duration: 0.3 }, at)
    },

    /** Digita `text` dentro de `sel`. Devolve o instante em que termina. */
    type(sel, text, at, perChar = 0.075) {
      const el = screen.querySelector(sel)
      const o = { n: 0 }
      const dur = Math.max(0.2, text.length * perChar)
      tl.call(() => el.classList.add('is-typing'), null, at)
      tl.to(
        o,
        {
          n: text.length,
          duration: dur,
          ease: 'none',
          onUpdate() {
            el.textContent = text.slice(0, Math.round(o.n))
          },
        },
        at,
      )
      tl.call(() => el.classList.remove('is-typing'), null, at + dur)
      return at + dur
    },

    /** Contador animado: escreve `fmt(valor)` em `sel`. */
    count(sel, from, to, at, dur, fmt) {
      const el = screen.querySelector(sel)
      const o = { v: from }
      el.textContent = fmt(from)
      tl.to(
        o,
        {
          v: to,
          duration: dur,
          ease: 'power2.out',
          onUpdate() {
            el.textContent = fmt(o.v)
          },
        },
        at,
      )
      return at + dur
    },
  }
}

/**
 * Monta a timeline de uma cena depois do layout (sem piscar o estado final).
 * `build` recebe { q, tl, kit, root, screen }.
 */
export function useScene(build, onDone) {
  const ref = useRef(null)
  const sim = useContext(SimContext)

  useLayoutEffect(() => {
    const root = ref.current
    const screen = root.closest('.sim-screen')
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        defaults: { ease: 'power3.out' },
        onComplete: () => onDone?.(),
      })
      tl.timeScale(sim.speed || 1)
      tl.eventCallback('onUpdate', () => sim.onProgress?.(tl.progress()))
      const kit = createKit(screen, tl)
      const rect = screen.getBoundingClientRect()
      gsap.set(kit.cursor, { x: rect.width * 0.8, y: rect.height * 0.92, opacity: 0 })
      build({ q: gsap.utils.selector(root), tl, kit, root, screen })
      if (reduceMotion()) {
        tl.progress(1)
        kit.hideCursor(0)
      }
    }, root)
    return () => ctx.revert()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return ref
}
