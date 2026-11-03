import { useRef } from 'react'
import { useI18n } from '../i18n'
import { Layout } from './Layout'
import { Reveal, Stagger, scrollToId, useHeroTimeline } from '../motion'
import { Accordion } from './Accordion'
import { Icon } from './Icons'
import { CONTACT_EMAIL, REPO_URL } from '../content'

/* ------------------ Cabeçalho comum às páginas internas ------------------ */

function PageHero({ heroRef, icon, kicker, title, lead, meta }) {
  return (
    <section className="page-hero" ref={heroRef}>
      <div className="container narrow">
        <span className="badge" data-hero="badge">
          <Icon name={icon} size={14} />
          {kicker}
        </span>
        <h1 data-hero="title">{title}</h1>
        <p className="lead" data-hero="lead">
          {lead}
        </p>
        {meta && (
          <p className="page-meta" data-hero="note">
            {meta}
          </p>
        )}
      </div>
    </section>
  )
}

function DocBlocks({ blocks }) {
  return blocks.map((block, index) =>
    block.ul ? (
      <ul key={index}>
        {block.ul.map((item) => (
          <li key={item} dangerouslySetInnerHTML={{ __html: item }} />
        ))}
      </ul>
    ) : (
      <p key={index} dangerouslySetInnerHTML={{ __html: block.p }} />
    ),
  )
}

/* ------------------------- Privacidade e Termos -------------------------- */

export function DocsPage({ kind }) {
  const { t } = useI18n()
  const doc = t.docs[kind]
  const heroRef = useRef(null)
  useHeroTimeline(heroRef)

  const goTo = (event, id) => {
    event.preventDefault()
    scrollToId(`#${id}`)
  }

  return (
    <Layout page={kind}>
      <PageHero
        heroRef={heroRef}
        icon="shield"
        kicker={doc.kicker}
        title={doc.title}
        lead={doc.lead}
        meta={doc.effective}
      />

      <section className="section">
        <div className="container doc-grid">
          <aside className="doc-toc" aria-label={t.toc}>
            <p className="doc-toc-title">{t.toc}</p>
            <nav>
              {doc.sections.map((section) => (
                <a key={section.id} href={`#${section.id}`} onClick={(e) => goTo(e, section.id)}>
                  {section.title}
                </a>
              ))}
            </nav>
          </aside>

          <div className="doc-body">
            <Reveal className="doc-summary">
              <span className="doc-summary-icon">
                <Icon name="sparkle" size={18} />
              </span>
              <p>{doc.summary}</p>
            </Reveal>

            {doc.sections.map((section) => (
              <Reveal as="section" className="doc-block" id={section.id} key={section.id}>
                <h2>{section.title}</h2>
                <DocBlocks blocks={section.blocks} />
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <Reveal className="cta-band">
            <div className="cta-glow" aria-hidden="true" />
            <h2>{t.cta.title}</h2>
            <p>{t.cta.text}</p>
            <a className="btn light" href="index.html">
              <Icon name="arrow" size={18} />
              {t.nav.home}
            </a>
          </Reveal>
        </div>
      </section>
    </Layout>
  )
}

/* -------------------------------- Suporte -------------------------------- */

export function SupportPage() {
  const { t } = useI18n()
  const s = t.support
  const heroRef = useRef(null)
  useHeroTimeline(heroRef)

  return (
    <Layout page="support">
      <PageHero
        heroRef={heroRef}
        icon="sparkle"
        kicker={s.kicker}
        title={s.title}
        lead={s.lead}
      />

      <section className="section">
        <div className="container">
          <Reveal className="section-head">
            <h2>{s.contactTitle}</h2>
            <p>{s.contactText}</p>
          </Reveal>

          <Stagger className="contact-grid">
            <a className="contact-card" href={`mailto:${CONTACT_EMAIL}`}>
              <span className="contact-icon">
                <Icon name="mail" size={22} />
              </span>
              <h3>{s.emailLabel}</h3>
              <p>{CONTACT_EMAIL}</p>
            </a>

            <a className="contact-card" href={REPO_URL} target="_blank" rel="noreferrer">
              <span className="contact-icon">
                <Icon name="code" size={22} />
              </span>
              <h3>{s.repoLabel}</h3>
              <p>{REPO_URL.replace('https://', '')}</p>
            </a>
          </Stagger>

          <Reveal className="contact-note">
            <Icon name="bolt" size={16} />
            <p>{s.tip}</p>
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="container narrow">
          <Reveal className="section-head">
            <h2>{s.faqTitle}</h2>
          </Reveal>

          <Reveal>
            <Accordion items={s.faq} defaultOpen={0} />
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <Reveal className="cta-band">
            <div className="cta-glow" aria-hidden="true" />
            <h2>{s.finalTitle}</h2>
            <p>{s.finalText}</p>
            <a className="btn light" href={`mailto:${CONTACT_EMAIL}`}>
              <Icon name="mail" size={18} />
              {CONTACT_EMAIL}
            </a>
          </Reveal>
        </div>
      </section>
    </Layout>
  )
}
