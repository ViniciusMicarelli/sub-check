import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { home } from './content'
import { Phone } from './sim/Phone'
import { SimContext } from './sim/kit'
import { SCENES } from './sim/scenes'

/**
 * Celular simulado. Mostra uma cena do app e, ao terminar, repete depois de
 * `loopDelay` segundos (0 = não repete). Trocar `sceneId` ou `playKey`
 * recomeça a cena do zero.
 */
export function Simulator({ sceneId, lang, loopDelay = 0, playKey = 0, speed = 1, onProgress, onEnd, className = '' }) {
  const [run, setRun] = useState(0)
  const timer = useRef(null)
  const Scene = SCENES[sceneId]
  const s = home[lang].sim

  useEffect(() => () => clearTimeout(timer.current), [])
  useEffect(() => {
    clearTimeout(timer.current)
  }, [sceneId, playKey, lang])

  // Os callbacks mudam a cada render do pai; a cena guarda só a referência.
  const handlers = useRef({ onProgress, onEnd })
  handlers.current = { onProgress, onEnd }
  const ctx = useMemo(
    () => ({ speed, onProgress: (p) => handlers.current.onProgress?.(p) }),
    [speed],
  )

  const done = useCallback(() => {
    handlers.current.onEnd?.()
    if (!loopDelay) return
    timer.current = setTimeout(() => setRun((r) => r + 1), loopDelay * 1000)
  }, [loopDelay])

  return (
    <SimContext.Provider value={ctx}>
      <Phone className={className}>
        <Scene key={`${sceneId}-${playKey}-${lang}-${run}`} s={s} lang={lang} onDone={done} />
      </Phone>
    </SimContext.Provider>
  )
}
