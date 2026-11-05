import { Icon } from '../../components/Icons'

/** iPhone desenhado em HTML/CSS. Tudo dentro usa `cqw` (1% da largura da tela). */
export function Phone({ children, dark = false, island = null, className = '' }) {
  return (
    <div className={`sim-phone ${className}`.trim()}>
      <span className="sim-btn sim-btn-a" aria-hidden="true" />
      <span className="sim-btn sim-btn-b" aria-hidden="true" />
      <span className="sim-btn sim-btn-c" aria-hidden="true" />
      <span className="sim-btn sim-btn-p" aria-hidden="true" />
      <div className="sim-bezel">
        <div className={`sim-screen${dark ? ' is-dark' : ''}`}>
          <div className="sim-statusbar" aria-hidden="true">
            <span>9:41</span>
            <span className="sim-sb-icons">
              <i className="sim-sig" />
              <i className="sim-wifi" />
              <i className="sim-bat" />
            </span>
          </div>
          {island || <span className="sim-island" aria-hidden="true" />}
          {children}
          <span className="sim-home" aria-hidden="true" />
          <div className="sim-cursor" aria-hidden="true">
            <b />
            <i />
          </div>
        </div>
      </div>
    </div>
  )
}

/** Marca do app (mesmo desenho do ícone novo). */
export function AppIcon({ size = '10cqw', radius = '28%' }) {
  return (
    <svg
      viewBox="0 0 64 64"
      style={{ width: size, height: size, borderRadius: radius, display: 'block', flex: 'none' }}
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="sim-ai-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#5457DB" />
          <stop offset="1" stopColor="#9B4AF0" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" fill="url(#sim-ai-g)" />
      <path d="M32 11a21 21 0 1 1-18.2 10.5" fill="none" stroke="#4DE8AA" strokeWidth="7" strokeLinecap="round" />
      <path d="M11 17.5 21.5 15l-2.5 10.5Z" fill="#4DE8AA" stroke="#4DE8AA" strokeWidth="2.4" strokeLinejoin="round" />
      <circle cx="32" cy="32" r="12.5" fill="#fff" />
      <path d="m26 32.5 4.4 4.4 7.6-8.8" fill="none" stroke="#5457DB" strokeWidth="3.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

/** Quadradinho colorido de um serviço. */
export function Badge({ icon, tint, size = '9.5cqw' }) {
  return (
    <span className="sim-badge" style={{ width: size, height: size, background: tint }}>
      <Icon name={icon} size={16} strokeWidth={2.2} />
    </span>
  )
}

/** Barra de abas flutuante, como a do app. */
export function TabBar({ labels, active = 0 }) {
  const icons = ['chart', 'list', 'grid', 'clock', 'target']
  return (
    <div className="sim-tabbar" data-a="tabbar" aria-hidden="true">
      {icons.map((name, i) => (
        <span key={name} className={i === active ? 'on' : ''}>
          <Icon name={name} size={15} strokeWidth={2} />
          <em>{labels[i]}</em>
        </span>
      ))}
    </div>
  )
}
