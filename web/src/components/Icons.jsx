// Conjunto de ícones em SVG inline (sem dependências). Traço herdado de `currentColor`.

const stroked = {
  bolt: <path d="M13 2 4 14h6l-1 8 9-12h-6l1-8Z" />,
  calendar: (
    <>
      <rect x="3" y="5" width="18" height="16" rx="3" />
      <path d="M8 3v4M16 3v4M3 10h18" />
    </>
  ),
  bell: (
    <>
      <path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.7 21a2 2 0 0 1-3.4 0" />
    </>
  ),
  chart: (
    <>
      <path d="M4 20V4M4 20h16" />
      <path d="M8 20v-6M13 20v-10M18 20v-4" />
    </>
  ),
  target: (
    <>
      <circle cx="12" cy="12" r="8" />
      <circle cx="12" cy="12" r="3.2" />
    </>
  ),
  scissors: (
    <>
      <circle cx="6" cy="6" r="2.6" />
      <circle cx="6" cy="18" r="2.6" />
      <path d="M8.2 7.8 20 18M8.2 16.2 20 6" />
    </>
  ),
  check: <path d="M20 6 9 17l-5-5" />,
  arrow: <path d="M5 12h14M13 6l6 6-6 6" />,
  lock: (
    <>
      <rect x="4" y="10" width="16" height="10" rx="3" />
      <path d="M8 10V7a4 4 0 0 1 8 0v3" />
    </>
  ),
  cloud: <path d="M7 18h10a4 4 0 0 0 .6-7.96A6 6 0 0 0 6 11.5 3.5 3.5 0 0 0 7 18Z" />,
  sparkle: <path d="M12 3.2l1.9 5.4 5.4 1.9-5.4 1.9L12 17.8l-1.9-5.4L4.7 10.5l5.4-1.9L12 3.2Z" />,
  globe: (
    <>
      <circle cx="12" cy="12" r="8.5" />
      <path d="M3.5 12h17M12 3.5a14 14 0 0 1 0 17 14 14 0 0 1 0-17Z" />
    </>
  ),
  shield: (
    <>
      <path d="M12 3.5 5 6.2v5.3c0 4.3 3 7.6 7 9 4-1.4 7-4.7 7-9V6.2L12 3.5Z" />
      <path d="M9.4 12.2 11.4 14l3.3-3.5" />
    </>
  ),
  file: (
    <>
      <path d="M14 3.5H7a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8.5l-5-5Z" />
      <path d="M14 3.5v5h5" />
    </>
  ),
  grid: (
    <>
      <rect x="4" y="4" width="7" height="7" rx="2" />
      <rect x="13" y="4" width="7" height="7" rx="2" />
      <rect x="4" y="13" width="7" height="7" rx="2" />
      <rect x="13" y="13" width="7" height="7" rx="2" />
    </>
  ),
  mail: (
    <>
      <rect x="3" y="5" width="18" height="14" rx="3" />
      <path d="m4 8 8 5 8-5" />
    </>
  ),
  code: <path d="m9 8-4 4 4 4M15 8l4 4-4 4" />,
  plus: <path d="M12 5v14M5 12h14" />,
  chevron: <path d="m6 9 6 6 6-6" />,
  play: (
    <>
      <rect x="3" y="4.5" width="18" height="15" rx="3.5" />
      <path d="M10.5 9.2v5.6l4.8-2.8-4.8-2.8Z" />
    </>
  ),
  music: (
    <>
      <path d="M9 18V5.5l10-2V16" />
      <circle cx="6.6" cy="18" r="2.4" />
      <circle cx="16.6" cy="16" r="2.4" />
    </>
  ),
}

const applePath =
  'M16.4 12.7c0-2.2 1.8-3.3 1.9-3.4-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.7.8-3.4.8-.7 0-1.8-.8-3-.8-1.5 0-2.9.9-3.7 2.3-1.6 2.7-.4 6.8 1.1 9 .7 1.1 1.6 2.3 2.8 2.2 1.1 0 1.6-.7 2.9-.7 1.3 0 1.7.7 2.9.7 1.2 0 2-1.1 2.7-2.2.5-.8.8-1.6.8-1.7-.1 0-2.7-1-2.7-4.2Zm-2.3-6.6c.6-.8 1-1.8.9-2.9-.9 0-2 .6-2.6 1.4-.6.7-1.1 1.8-.9 2.8 1 .1 2-.5 2.6-1.3Z'

export function Icon({ name, size = 22, className = '', strokeWidth = 1.7 }) {
  if (name === 'apple') {
    return (
      <svg
        viewBox="0 0 24 24"
        width={size}
        height={size}
        className={className}
        fill="currentColor"
        aria-hidden="true"
      >
        <path d={applePath} />
      </svg>
    )
  }

  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {stroked[name] ?? null}
    </svg>
  )
}
