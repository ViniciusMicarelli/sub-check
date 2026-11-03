import { useEffect, useState } from 'react'
import { Icon } from './Icons'

/** Lista de perguntas com uma resposta aberta por vez. */
export function Accordion({ items, className = '', defaultOpen = -1 }) {
  const [open, setOpen] = useState(defaultOpen)

  useEffect(() => {
    setOpen(defaultOpen)
  }, [items, defaultOpen])

  return (
    <div className={`accordion ${className}`}>
      {items.map((item, index) => {
        const isOpen = open === index
        return (
          <div className={`acc-item${isOpen ? ' is-open' : ''}`} key={item.q}>
            <button
              type="button"
              className="acc-head"
              aria-expanded={isOpen}
              onClick={() => setOpen(isOpen ? -1 : index)}
            >
              <span>{item.q}</span>
              <Icon name="chevron" size={18} className="acc-chevron" />
            </button>
            <div className="acc-body">
              <div className="acc-body-inner">
                <p>{item.a}</p>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
