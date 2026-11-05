import { Icon } from '../../components/Icons'
import { money } from '../content'
import { AppIcon, Badge, TabBar } from './Phone'
import { useScene } from './kit'

const COLORS = {
  red: 'linear-gradient(135deg,#ff5a5f,#e8424a)',
  green: 'linear-gradient(135deg,#34d399,#16a34a)',
  blue: 'linear-gradient(135deg,#4aa8ff,#298cf5)',
  orange: 'linear-gradient(135deg,#ffbe55,#f5a621)',
  violet: 'linear-gradient(135deg,#6b6ee8,#9c4af0)',
}

const signed = (v, lang) => `${v < 0 ? '−' : v > 0 ? '+' : ''}${money(Math.abs(v), lang, 0)}`

/* ------------------------------ 1. Painel ------------------------------ */

export function SceneDash({ s, lang, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.from(q('[data-a=head]'), { y: -14, opacity: 0, duration: 0.5 }, 0)
    tl.from(q('[data-a=card]'), { y: 34, opacity: 0, scale: 0.95, duration: 0.8 }, 0.12)
    kit.count('[data-a=total]', 0, 287.4, 0.35, 1.5, (v) => money(v, lang))
    tl.from(q('[data-a=spark] path'), { strokeDashoffset: 1, duration: 1.4, ease: 'power2.inOut' }, 0.5)
    tl.from(q('[data-a=metric]'), { y: 22, opacity: 0, stagger: 0.09, duration: 0.55 }, 0.8)
    tl.from(q('[data-a=row]'), { x: -26, opacity: 0, stagger: 0.12, duration: 0.6 }, 1.25)
    tl.from(q('[data-a=tabbar]'), { y: 30, opacity: 0, duration: 0.6 }, 0.6)
    tl.fromTo(q('[data-a=due]'), { scale: 1 }, { scale: 1.08, yoyo: true, repeat: 3, duration: 0.45, ease: 'sine.inOut', transformOrigin: 'right center' }, 2.4)
    tl.to({}, { duration: 1 }, 3.4)
  }, onDone)

  return (
    <div className="sim-scene" ref={ref}>
      <div className="sim-head" data-a="head">
        <div>
          <small>{s.hello}</small>
          <h4>{s.overview}</h4>
        </div>
        <span className="sim-plus"><Icon name="plus" size={16} strokeWidth={2.4} /></span>
      </div>

      <div className="sim-hero-card" data-a="card">
        <small>{s.monthly}</small>
        <strong data-a="total">{money(287.4, lang)}</strong>
        <span>{s.yearly}</span>
        <svg className="sim-spark" viewBox="0 0 120 34" data-a="spark" aria-hidden="true">
          <path d="M2 28 C 18 26, 22 12, 38 16 S 62 30, 76 18 S 100 4, 118 8" pathLength="1" strokeDasharray="1" />
        </svg>
        <em className="sim-pill">{s.active}</em>
      </div>

      <div className="sim-metrics">
        {[['grid', '5', 'violet'], ['calendar', money(9.58, lang), 'green'], ['bell', '2', 'orange'], ['chart', money(3448, lang, 0), 'blue']].map(([icon, value, tone], i) => (
          <div className="sim-metric" data-a="metric" key={icon}>
            <Badge icon={icon} tint={COLORS[tone]} size="7.5cqw" />
            <small>{s.m[i]}</small>
            <b>{value}</b>
          </div>
        ))}
      </div>

      <div className="sim-sec">{s.upcoming}</div>
      <div className="sim-list">
        {[['play', 'red', 'Netflix', '12 nov', 55.9, s.in3, true], ['music', 'green', 'Spotify', '18 nov', 21.9, s.in9], ['cloud', 'blue', 'iCloud+', '27 nov', 14.9, s.in15], ['target', 'orange', 'Academia', '2 dez', 119.9, s.in25]].map(([icon, tone, name, date, price, when, due]) => (
          <div className="sim-row" data-a="row" key={name}>
            <Badge icon={icon} tint={COLORS[tone]} />
            <div className="sim-row-main">
              <b>{name}</b>
              <small>{date}</small>
            </div>
            <div className="sim-row-end">
              <b>{money(price, lang)}</b>
              <small className={due ? 'warn' : ''} data-a={due ? 'due' : undefined}>{when}</small>
            </div>
          </div>
        ))}
      </div>
      <TabBar labels={s.tabs} active={0} />
    </div>
  )
}

/* ----------------------------- 2. Adicionar ----------------------------- */

export function SceneAdd({ s, lang, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.set(q('[data-a=sheet]'), { yPercent: 104 })
    tl.set(q('[data-a=dim]'), { opacity: 0 })
    tl.set(q('[data-a=new]'), { height: 0, opacity: 0, paddingTop: 0, paddingBottom: 0 })
    tl.set(q('[data-a=iconpop], [data-a=autochip]'), { opacity: 0, scale: 0.4 })
    tl.from(q('[data-a=head]'), { y: -12, opacity: 0, duration: 0.5 }, 0)
    tl.from(q('[data-a=old]'), { x: -24, opacity: 0, stagger: 0.12, duration: 0.55 }, 0.25)

    let t = kit.tap('[data-a=plus]', 1.0)
    tl.to(q('[data-a=dim]'), { opacity: 1, duration: 0.4 }, t)
    tl.to(q('[data-a=sheet]'), { yPercent: 0, duration: 0.7, ease: 'power3.out' }, t)

    t = kit.tap('[data-a=namefield]', t + 0.9)
    t = kit.type('[data-a=nametext]', 'Netflix', t + 0.1, 0.11)
    tl.to(q('[data-a=iconpop]'), { opacity: 1, scale: 1, duration: 0.5, ease: 'back.out(2.4)' }, t + 0.1)
    tl.to(q('[data-a=autochip]'), { opacity: 1, scale: 1, duration: 0.5, ease: 'back.out(2.4)' }, t + 0.35)

    t = kit.tap('[data-a=pricefield]', t + 1.0)
    t = kit.type('[data-a=pricetext]', '55,90', t + 0.1, 0.13)

    t = kit.tap('[data-a=save]', t + 0.7)
    tl.to(q('[data-a=sheet]'), { yPercent: 104, duration: 0.6, ease: 'power3.in' }, t + 0.1)
    tl.to(q('[data-a=dim]'), { opacity: 0, duration: 0.4 }, t + 0.2)
    kit.hideCursor(t + 0.3)
    tl.to(q('[data-a=new]'), { height: 'auto', opacity: 1, paddingTop: '2.6cqw', paddingBottom: '2.6cqw', duration: 0.7, ease: 'power3.out' }, t + 0.6)
    kit.count('[data-a=sum]', 43.8, 99.7, t + 0.7, 0.9, (v) => money(v, lang))
    tl.fromTo(q('[data-a=new]'), { boxShadow: '0 0 0 0 rgba(84,87,219,.5)' }, { boxShadow: '0 0 0 14px rgba(84,87,219,0)', duration: 1.1 }, t + 1.2)
    tl.to({}, { duration: 1.6 }, t + 1.4)
  }, onDone)

  const rows = [['music', 'green', 'Spotify', '18 nov', 21.9], ['cloud', 'blue', 'iCloud+', '27 nov', 21.9]]

  return (
    <div className="sim-scene" ref={ref}>
      <div className="sim-head" data-a="head">
        <div>
          <small>{s.monthly}</small>
          <h4 data-a="sum">{money(43.8, lang)}</h4>
        </div>
        <span className="sim-plus" data-a="plus"><Icon name="plus" size={16} strokeWidth={2.4} /></span>
      </div>

      <div className="sim-sec">{s.subs}</div>
      <div className="sim-list">
        <div className="sim-row sim-row-new" data-a="new">
          <Badge icon="play" tint={COLORS.red} />
          <div className="sim-row-main"><b>Netflix</b><small>{s.monthlyWord}</small></div>
          <div className="sim-row-end"><b>{money(55.9, lang)}</b><small className="warn">{s.in3}</small></div>
        </div>
        {rows.map(([icon, tone, name, date, price]) => (
          <div className="sim-row" data-a="old" key={name}>
            <Badge icon={icon} tint={COLORS[tone]} />
            <div className="sim-row-main"><b>{name}</b><small>{date}</small></div>
            <div className="sim-row-end"><b>{money(price, lang)}</b></div>
          </div>
        ))}
      </div>

      <TabBar labels={s.tabs} active={1} />

      <div className="sim-dim" data-a="dim" />
      <div className="sim-sheet" data-a="sheet">
        <i className="sim-grab" />
        <h5>{s.newSub}</h5>
        <label className="sim-field" data-a="namefield">
          <small>{s.name}</small>
          <span><b data-a="nametext" /></span>
        </label>
        <div className="sim-auto">
          <span className="sim-badge" data-a="iconpop" style={{ width: '10cqw', height: '10cqw', background: COLORS.red }}><Icon name="play" size={16} strokeWidth={2.2} /></span>
          <span className="sim-chip" data-a="autochip"><Icon name="sparkle" size={11} strokeWidth={2.2} /> {s.category} · {s.auto}</span>
        </div>
        <label className="sim-field" data-a="pricefield">
          <small>{s.price}</small>
          <span><em>R$</em><b data-a="pricetext" /></span>
        </label>
        <button className="sim-cta" data-a="save" type="button" tabIndex={-1}>{s.save}</button>
      </div>
    </div>
  )
}

/* ----------------------------- 3. Importar ----------------------------- */

export function SceneImport({ s, lang, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.set(q('[data-a=file]'), { opacity: 0, y: 40, scale: 0.9 })
    tl.set(q('[data-a=read]'), { opacity: 0 })
    tl.set(q('[data-a=results]'), { opacity: 0, y: 30 })
    tl.set(q('[data-a=addbar]'), { opacity: 0, y: 40 })
    tl.set(q('[data-a=toast]'), { opacity: 0, y: 20, scale: 0.9 })
    tl.set(q('[data-a=tick]'), { scale: 0 })
    tl.from(q('[data-a=head]'), { y: -12, opacity: 0, duration: 0.5 }, 0)
    tl.from(q('[data-a=intro]'), { y: 24, opacity: 0, duration: 0.6 }, 0.2)

    let t = kit.tap('[data-a=choose]', 1.0)
    tl.to(q('[data-a=file]'), { opacity: 1, y: 0, scale: 1, duration: 0.6, ease: 'back.out(1.8)' }, t)
    tl.to(q('[data-a=read]'), { opacity: 1, duration: 0.3 }, t + 0.5)
    tl.fromTo(q('[data-a=bar] i'), { scaleX: 0 }, { scaleX: 1, duration: 1.3, ease: 'power1.inOut', transformOrigin: 'left' }, t + 0.5)
    t += 2.0
    kit.hideCursor(t)
    tl.to(q('[data-a=intro]'), { opacity: 0, y: -30, height: 0, marginBottom: 0, padding: 0, duration: 0.5, ease: 'power2.in' }, t)
    tl.to(q('[data-a=results]'), { opacity: 1, y: 0, duration: 0.6 }, t + 0.3)
    tl.from(q('[data-a=found]'), { y: 20, opacity: 0, stagger: 0.14, duration: 0.5 }, t + 0.5)
    tl.to(q('[data-a=tick]'), { scale: 1, stagger: 0.18, duration: 0.4, ease: 'back.out(3)' }, t + 1.0)
    tl.to(q('[data-a=addbar]'), { opacity: 1, y: 0, duration: 0.6 }, t + 1.9)

    t = kit.tap('[data-a=addbtn]', t + 2.8)
    kit.hideCursor(t + 0.2)
    tl.to(q('[data-a=addbar]'), { opacity: 0, y: 30, duration: 0.4 }, t)
    tl.to(q('[data-a=toast]'), { opacity: 1, y: 0, scale: 1, duration: 0.6, ease: 'back.out(2)' }, t + 0.3)
    tl.to({}, { duration: 1.8 }, t + 0.6)
  }, onDone)

  const found = [
    ['play', 'red', 'Netflix', 55.9, 3, true],
    ['music', 'green', 'Spotify', 21.9, 4, true],
    ['cloud', 'blue', 'iCloud+', 14.9, 3, true],
    ['target', 'orange', 'Academia', 119.9, 3, false],
  ]

  return (
    <div className="sim-scene" ref={ref}>
      <div className="sim-head" data-a="head">
        <div><h4 className="sim-h4-sm">{s.importTitle}</h4></div>
        <span className="sim-plus sim-plus-ghost"><Icon name="download" size={16} strokeWidth={2.2} /></span>
      </div>

      <div className="sim-card sim-intro" data-a="intro">
        <button className="sim-choose" data-a="choose" type="button" tabIndex={-1}>
          <Icon name="file" size={16} strokeWidth={2} /> {s.chooseFile}
        </button>
        <div className="sim-file" data-a="file">
          <Icon name="file" size={18} strokeWidth={1.8} />
          <b>extrato-outubro.csv</b>
          <small>48 KB</small>
        </div>
        <div className="sim-read" data-a="read">
          <small>{s.reading}</small>
          <span className="sim-bar" data-a="bar"><i /></span>
        </div>
      </div>

      <div className="sim-results" data-a="results">
        <div className="sim-sec">{s.found}</div>
        <div className="sim-list">
          {found.map(([icon, tone, name, price, n, on]) => (
            <div className={`sim-row${on ? '' : ' is-off'}`} data-a="found" key={name}>
              <span className={`sim-check${on ? ' on' : ''}`}>
                <span data-a={on ? 'tick' : undefined}><Icon name="check" size={11} strokeWidth={3} /></span>
              </span>
              <Badge icon={icon} tint={COLORS[tone]} size="8.5cqw" />
              <div className="sim-row-main">
                <b>{name}</b>
                <small>{on ? `${n} ${s.charges}` : s.looksCancelled}</small>
              </div>
              <div className="sim-row-end"><b>{money(price, lang)}</b></div>
            </div>
          ))}
        </div>
      </div>

      <div className="sim-addbar" data-a="addbar">
        <button className="sim-cta" data-a="addbtn" type="button" tabIndex={-1}>{s.addN}</button>
      </div>
      <div className="sim-toast" data-a="toast"><Icon name="check" size={14} strokeWidth={3} /> {s.added}</div>
    </div>
  )
}

/* ------------------------------ 4. Câmbio ------------------------------ */

export function SceneFx({ s, lang, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.set(q('[data-a=diffrow]'), { background: 'rgba(36,184,115,0)' })
    tl.from(q('[data-a=head]'), { y: -12, opacity: 0, duration: 0.5 }, 0)
    tl.from(q('[data-a=sum]'), { y: 20, opacity: 0, stagger: 0.12, duration: 0.55 }, 0.3)
    kit.count('[data-a=paid]', 0, 150, 0.6, 1.2, (v) => money(v, lang))
    kit.count('[data-a=would]', 0, 120, 0.8, 1.2, (v) => money(v, lang))
    kit.count('[data-a=diff]', 0, -30, 1.4, 1.1, (v) => signed(v, lang))
    tl.to(q('[data-a=diffrow]'), { background: 'rgba(36,184,115,.14)', duration: 0.6 }, 1.9)
    tl.from(q('[data-a=chart]'), { y: 26, opacity: 0, duration: 0.6 }, 1.1)
    tl.from(q('[data-a=line]'), { strokeDashoffset: 1, duration: 1.6, ease: 'power2.inOut' }, 1.5)
    tl.from(q('[data-a=dot]'), { scale: 0, transformOrigin: 'center', stagger: 0.4, duration: 0.4, ease: 'back.out(3)' }, 1.9)
    tl.from(q('[data-a=pay]'), { x: -24, opacity: 0, stagger: 0.15, duration: 0.55 }, 2.4)
    kit.hideCursor(0)
    tl.to({}, { duration: 2.2 }, 3.5)
  }, onDone)

  const pays = [
    ['5 ago', 5.0, 50, -10, -0.2],
    ['5 set', 4.5, 45, -5, -0.11],
    ['5 out', 4.0, 40, 0, 0],
  ]

  return (
    <div className="sim-scene" ref={ref}>
      <div className="sim-head" data-a="head">
        <div>
          <small><Icon name="chevron" size={10} strokeWidth={3} className="sim-back" /> Notion · US$ 10,00</small>
          <h4 className="sim-h4-sm">{s.fxTitle}</h4>
        </div>
      </div>

      <div className="sim-card sim-sumcard">
        <div className="sim-sumrow" data-a="sum"><span>{s.rateToday}</span><b>1 USD = {money(4, lang)}</b></div>
        <div className="sim-sumrow" data-a="sum"><span>{s.paid}</span><b data-a="paid">{money(150, lang)}</b></div>
        <div className="sim-sumrow" data-a="sum"><span>{s.wouldCost}</span><b data-a="would">{money(120, lang)}</b></div>
        <div className="sim-sumrow is-diff" data-a="diffrow"><span>{s.diff}</span><b className="good" data-a="diff">{signed(-30, lang)}</b></div>
      </div>

      <div className="sim-card sim-chart" data-a="chart">
        <svg viewBox="0 0 200 64" aria-hidden="true">
          <defs>
            <linearGradient id="sim-fx-g" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#5457db" stopOpacity=".28" />
              <stop offset="1" stopColor="#5457db" stopOpacity="0" />
            </linearGradient>
          </defs>
          <path d="M6 10 C 40 12, 60 22, 100 30 S 160 50, 194 54 L194 62 L6 62 Z" fill="url(#sim-fx-g)" />
          <path d="M6 10 C 40 12, 60 22, 100 30 S 160 50, 194 54" pathLength="1" strokeDasharray="1" data-a="line" className="sim-line" />
          <circle cx="6" cy="10" r="3.4" className="sim-dot" data-a="dot" />
          <circle cx="100" cy="30" r="3.4" className="sim-dot" data-a="dot" />
          <circle cx="194" cy="54" r="3.4" className="sim-dot" data-a="dot" />
        </svg>
      </div>

      <div className="sim-sec">{s.payments}</div>
      <div className="sim-list">
        {pays.map(([date, rate, paid, diff, frac]) => (
          <div className="sim-row sim-row-pay" data-a="pay" key={date}>
            <div className="sim-row-main">
              <b>{date}</b>
              <small>US$ 10,00 · {s.rateThen} {money(rate, lang)}</small>
            </div>
            <div className="sim-row-end">
              <b>{money(paid, lang)}</b>
              <small className={diff < 0 ? 'good' : ''}>{diff === 0 ? '—' : `${signed(diff, lang)} (${Math.round(frac * 100)}%)`.replace('-', '−')}</small>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

/* --------------------------- 5. Ilha Dinâmica --------------------------- */

export function SceneIsland({ s, lang, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.set(q('[data-a=full]'), { opacity: 0 })
    tl.set(q('[data-a=done]'), { opacity: 0, scale: 0.6 })
    tl.set(q('[data-a=live]'), { width: '27cqw', height: '8cqw', borderRadius: '5cqw' })
    tl.from(q('[data-a=wall]'), { opacity: 0, duration: 0.6 }, 0)
    tl.from(q('[data-a=clock]'), { y: 24, opacity: 0, duration: 0.8 }, 0.2)
    tl.from(q('[data-a=compact]'), { opacity: 0, duration: 0.4 }, 0.6)

    // expande
    let t = 1.8
    tl.to(q('[data-a=compact]'), { opacity: 0, duration: 0.18 }, t)
    tl.to(q('[data-a=live]'), { width: '90cqw', height: '41cqw', borderRadius: '9cqw', duration: 0.75, ease: 'elastic.out(1,0.8)' }, t)
    tl.to(q('[data-a=full]'), { opacity: 1, duration: 0.4 }, t + 0.35)
    tl.from(q('[data-a=full] > *'), { y: 10, opacity: 0, stagger: 0.07, duration: 0.4 }, t + 0.4)
    tl.fromTo(q('[data-a=prog]'), { scaleX: 0.12 }, { scaleX: 0.78, duration: 2.4, ease: 'none', transformOrigin: 'left' }, t + 0.5)

    t = kit.tap('[data-a=paybtn]', t + 2.4, { move: 0.9 })
    tl.to(q('[data-a=paybtn]'), { backgroundColor: '#24b873', duration: 0.3 }, t)
    tl.to(q('[data-a=paylabel]'), { opacity: 0, duration: 0.15 }, t)
    tl.to(q('[data-a=done]'), { opacity: 1, scale: 1, duration: 0.4, ease: 'back.out(3)' }, t + 0.1)
    kit.hideCursor(t + 0.3)

    // recolhe
    t += 1.4
    tl.to(q('[data-a=full]'), { opacity: 0, duration: 0.25 }, t)
    tl.to(q('[data-a=live]'), { width: '27cqw', height: '8cqw', borderRadius: '5cqw', duration: 0.6, ease: 'power3.inOut' }, t + 0.15)
    tl.to(q('[data-a=compact]'), { opacity: 1, duration: 0.3 }, t + 0.7)
    tl.to({}, { duration: 1.6 }, t + 0.8)
  }, onDone)

  return (
    <div className="sim-scene sim-scene-dark sim-scene-island" ref={ref}>
      <div className="sim-wall" data-a="wall" />
      <div className="sim-clock" data-a="clock">
        <small>{s.lock}</small>
        <b>9:41</b>
      </div>

      <div className="sim-live" data-a="live">
        <div className="sim-live-compact" data-a="compact">
          <Badge icon="play" tint={COLORS.red} size="5.2cqw" />
          <span>3d</span>
        </div>
        <div className="sim-live-full" data-a="full">
          <div className="sim-live-top">
            <Badge icon="play" tint={COLORS.red} size="9cqw" />
            <div className="sim-live-name"><b>Netflix</b><small>{s.nextCharge}</small></div>
            <div className="sim-live-amt"><b>{money(55.9, lang)}</b><small>{s.in3}</small></div>
          </div>
          <span className="sim-prog"><i data-a="prog" /></span>
          <button className="sim-live-btn" data-a="paybtn" type="button" tabIndex={-1}>
            <span data-a="paylabel"><Icon name="check" size={12} strokeWidth={3} /> {s.pay}</span>
            <span className="sim-live-done" data-a="done"><Icon name="check" size={14} strokeWidth={3} /> {s.paidDone}</span>
          </button>
        </div>
      </div>
    </div>
  )
}

/* -------------------------------- 6. Siri -------------------------------- */

export function SceneSiri({ s, onDone }) {
  const ref = useScene(({ q, tl }) => {
    tl.set(q('[data-a=answer]'), { opacity: 0, y: 40, scale: 0.94 })
    tl.set(q('[data-a=ask]'), { opacity: 0 })
    tl.from(q('[data-a=wall]'), { opacity: 0, duration: 0.6 }, 0)
    tl.from(q('[data-a=orb]'), { scale: 0, opacity: 0, duration: 0.9, ease: 'elastic.out(1,0.6)' }, 0.3)
    tl.from(q('[data-a=listen]'), { opacity: 0, y: 10, duration: 0.5 }, 0.9)
    tl.to(q('[data-a=listen]'), { opacity: 0, duration: 0.3 }, 1.9)
    tl.to(q('[data-a=ask]'), { opacity: 1, duration: 0.2 }, 1.9)

    const el = q('[data-a=ask]')[0]
    const o = { n: 0 }
    tl.to(o, { n: s.siriAsk.length, duration: 2.4, ease: 'none', onUpdate() { el.textContent = s.siriAsk.slice(0, Math.round(o.n)) } }, 2.0)
    tl.to(q('[data-a=orb]'), { scale: 0.72, y: 14, duration: 0.6 }, 4.6)
    tl.to(q('[data-a=answer]'), { opacity: 1, y: 0, scale: 1, duration: 0.7, ease: 'back.out(1.6)' }, 4.9)
    tl.from(q('[data-a=answer] [data-a=okmark]'), { scale: 0, duration: 0.5, ease: 'back.out(3)' }, 5.3)
    tl.to({}, { duration: 2.4 }, 6.0)
  }, onDone)

  return (
    <div className="sim-scene sim-scene-dark" ref={ref}>
      <div className="sim-wall sim-wall-siri" data-a="wall" />
      <div className="sim-siri-text">
        <small data-a="listen">{s.listening}</small>
        <p data-a="ask" />
      </div>
      <div className="sim-answer" data-a="answer">
        <div className="sim-answer-head"><AppIcon size="7cqw" /><b>SubCheck</b></div>
        <p>{s.siriAnswer}</p>
        <span className="sim-ok" data-a="okmark"><Icon name="check" size={14} strokeWidth={3} /></span>
      </div>
      <div className="sim-orb" data-a="orb"><i /><i /><i /></div>
    </div>
  )
}

/* ------------------------------ 7. Notificação ------------------------------ */

export function SceneNotify({ s, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.set(q('[data-a=banner]'), { y: -90, opacity: 0 })
    tl.set(q('[data-a=actions]'), { height: 0, opacity: 0, marginTop: 0 })
    tl.set(q('[data-a=toast]'), { opacity: 0, y: 14, scale: 0.9 })
    tl.from(q('[data-a=wall]'), { opacity: 0, duration: 0.5 }, 0)
    tl.from(q('[data-a=clock]'), { y: 24, opacity: 0, duration: 0.8 }, 0.1)
    tl.to(q('[data-a=banner]'), { y: 0, opacity: 1, duration: 0.8, ease: 'back.out(1.5)' }, 1.0)
    tl.to(q('[data-a=banner]'), { y: -5, repeat: 1, yoyo: true, duration: 0.15 }, 1.9)
    tl.to(q('[data-a=actions]'), { height: 'auto', opacity: 1, marginTop: 10, duration: 0.55, ease: 'power3.out' }, 2.6)

    let t = kit.tap('[data-a=mark]', 3.5, { move: 0.9 })
    tl.to(q('[data-a=mark]'), { backgroundColor: '#24b873', color: '#fff', duration: 0.25 }, t)
    kit.hideCursor(t + 0.2)
    tl.to(q('[data-a=banner]'), { y: -110, opacity: 0, scale: 0.94, duration: 0.55, ease: 'power3.in' }, t + 0.45)
    tl.to(q('[data-a=toast]'), { opacity: 1, y: 0, scale: 1, duration: 0.6, ease: 'back.out(2)' }, t + 0.9)
    tl.to({}, { duration: 2 }, t + 1.2)
  }, onDone)

  return (
    <div className="sim-scene sim-scene-dark" ref={ref}>
      <div className="sim-wall" data-a="wall" />
      <div className="sim-clock sim-clock-lock" data-a="clock">
        <small>{s.lock}</small>
        <b>9:41</b>
      </div>

      <div className="sim-banner" data-a="banner">
        <div className="sim-banner-top">
          <AppIcon size="8cqw" radius="24%" />
          <div className="sim-banner-text">
            <div className="sim-banner-title"><b>{s.notifTitle}</b><small>{s.now}</small></div>
            <p>{s.notifBody}</p>
          </div>
        </div>
        <div className="sim-actions" data-a="actions">
          <span data-a="mark">{s.markPaid}</span>
          <span>{s.snooze}</span>
        </div>
      </div>

      <div className="sim-toast sim-toast-dark" data-a="toast"><Icon name="check" size={14} strokeWidth={3} /> {s.paidDone} · Netflix</div>
    </div>
  )
}

/* ------------------------------ 8. Teste grátis ------------------------------ */

export function ScenePro({ s, onDone }) {
  const ref = useScene(({ q, tl, kit }) => {
    tl.from(q('[data-a=disc]'), { scale: 0, rotate: -30, duration: 0.9, ease: 'back.out(1.8)' }, 0.1)
    kit.count('[data-a=num]', 0, 7, 0.4, 0.9, (v) => String(Math.round(v)))
    tl.from(q('[data-a=tag]'), { y: 14, opacity: 0, duration: 0.5 }, 0.9)
    tl.from(q('[data-a=title]'), { y: 20, opacity: 0, duration: 0.6 }, 1.1)
    tl.from(q('[data-a=perk]'), { x: -20, opacity: 0, stagger: 0.14, duration: 0.5 }, 1.5)
    tl.from(q('[data-a=perk] .sim-tickc'), { scale: 0, stagger: 0.14, duration: 0.4, ease: 'back.out(3)' }, 1.7)
    tl.from(q('[data-a=note]'), { opacity: 0, duration: 0.5 }, 2.4)
    tl.from(q('[data-a=cont]'), { y: 24, opacity: 0, duration: 0.6 }, 2.4)
    tl.fromTo(q('[data-a=disc]'), { boxShadow: '0 0 0 0 rgba(156,74,240,.45)' }, { boxShadow: '0 0 0 26px rgba(156,74,240,0)', duration: 1.4, repeat: 2 }, 1.2)
    const t = kit.tap('[data-a=cont]', 3.4)
    tl.to(q('[data-a=cont]'), { scale: 0.96, yoyo: true, repeat: 1, duration: 0.12 }, t - 0.25)
    kit.hideCursor(t + 0.2)
    tl.to({}, { duration: 2.4 }, t + 0.3)
  }, onDone)

  return (
    <div className="sim-scene sim-scene-pro" ref={ref}>
      <div className="sim-trial">
        <div className="sim-disc" data-a="disc">
          <b data-a="num">7</b>
          <small>{s.trialDays}</small>
        </div>
        <span className="sim-tag" data-a="tag">{s.trialTag}</span>
        <h4 data-a="title">{s.trialTitle}</h4>
        <ul>
          {s.perks.map((p) => (
            <li data-a="perk" key={p}>
              <span className="sim-tickc"><Icon name="check" size={11} strokeWidth={3} /></span>
              {p}
            </li>
          ))}
        </ul>
        <p className="sim-trial-note" data-a="note">{s.trialNote}</p>
      </div>
      <button className="sim-cta sim-cta-bottom" data-a="cont" type="button" tabIndex={-1}>{s.cont}</button>
    </div>
  )
}

export const SCENES = {
  dash: SceneDash,
  add: SceneAdd,
  import: SceneImport,
  fx: SceneFx,
  island: SceneIsland,
  siri: SceneSiri,
  notify: SceneNotify,
  pro: ScenePro,
}
