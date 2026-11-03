import { useEffect, useRef } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import Lenis from 'lenis'

gsap.registerPlugin(ScrollTrigger)

/** Respeita “Reduzir movimento” do sistema. */
export function reduceMotion() {
  if (typeof window === 'undefined') return false
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

let lenisInstance = null

/** Rolagem suave (Lenis) sincronizada com o ScrollTrigger do GSAP. */
export function useSmoothScroll() {
  useEffect(() => {
    if (reduceMotion()) return undefined

    const lenis = new Lenis({
      duration: 1.05,
      smoothWheel: true,
      touchMultiplier: 1.6,
    })
    lenisInstance = lenis

    const onScroll = () => ScrollTrigger.update()
    lenis.on('scroll', onScroll)

    const raf = (time) => lenis.raf(time * 1000)
    gsap.ticker.add(raf)
    gsap.ticker.lagSmoothing(0)

    // As fontes podem mudar a altura da página depois do primeiro layout.
    const refresh = () => ScrollTrigger.refresh()
    window.addEventListener('load', refresh)
    const t = window.setTimeout(refresh, 400)

    return () => {
      window.removeEventListener('load', refresh)
      window.clearTimeout(t)
      gsap.ticker.remove(raf)
      lenis.destroy()
      lenisInstance = null
    }
  }, [])
}

/** Rola até um seletor (#id), usando o Lenis quando ele está ativo. */
export function scrollToId(hash) {
  const el = typeof hash === 'string' ? document.querySelector(hash) : hash
  if (!el) return
  if (lenisInstance) {
    lenisInstance.scrollTo(el, { offset: -72, duration: 1.1 })
  } else {
    el.scrollIntoView({ behavior: reduceMotion() ? 'auto' : 'smooth', block: 'start' })
  }
}

/** Aparece suavemente quando entra na tela. */
export function Reveal({ as: Tag = 'div', className = '', y = 26, delay = 0, children, ...rest }) {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      gsap.from(el, {
        y,
        opacity: 0,
        duration: 0.9,
        delay,
        ease: 'power3.out',
        scrollTrigger: { trigger: el, start: 'top 88%', once: true },
      })
    }, el)
    return () => ctx.revert()
  }, [y, delay])

  return (
    <Tag ref={ref} className={className} {...rest}>
      {children}
    </Tag>
  )
}

/** Igual ao Reveal, mas escalona os filhos diretos. */
export function Stagger({ as: Tag = 'div', className = '', step = 0.08, y = 24, children, ...rest }) {
  const ref = useRef(null)

  useEffect(() => {
    const el = ref.current
    if (!el || reduceMotion()) return undefined
    const ctx = gsap.context(() => {
      gsap.from(Array.from(el.children), {
        y,
        opacity: 0,
        duration: 0.8,
        ease: 'power3.out',
        stagger: step,
        scrollTrigger: { trigger: el, start: 'top 85%', once: true },
      })
    }, el)
    return () => ctx.revert()
  }, [step, y])

  return (
    <Tag ref={ref} className={className} {...rest}>
      {children}
    </Tag>
  )
}

/** Timeline de entrada do herói. */
export function useHeroTimeline(scopeRef) {
  useEffect(() => {
    const el = scopeRef.current
    if (!el) return undefined

    if (reduceMotion()) {
      gsap.set(el.querySelectorAll('[data-hero]'), { opacity: 1, y: 0, scale: 1 })
      return undefined
    }

    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: 'power3.out' } })
      // Só anima o que existe: as páginas internas não têm todos os elementos.
      const add = (selector, vars, position) => {
        const targets = el.querySelectorAll(selector)
        if (!targets.length) return
        tl.from(targets, vars, position)
      }

      add('[data-hero="badge"]', { y: 18, opacity: 0, duration: 0.6 })
      add('[data-hero="title"]', { y: 30, opacity: 0, duration: 0.9 }, '-=0.3')
      add('[data-hero="lead"]', { y: 24, opacity: 0, duration: 0.8 }, '-=0.6')
      add('[data-hero="actions"]', { y: 20, opacity: 0, duration: 0.7 }, '-=0.55')
      add('[data-hero="note"]', { y: 14, opacity: 0, duration: 0.6 }, '-=0.45')
      add('[data-hero="phone"]', { y: 46, opacity: 0, scale: 0.94, duration: 1.1 }, '-=0.85')
      add('[data-hero="chip"]', { y: 18, opacity: 0, duration: 0.6, stagger: 0.12 }, '-=0.6')
    }, el)

    return () => ctx.revert()
  }, [scopeRef])
}
