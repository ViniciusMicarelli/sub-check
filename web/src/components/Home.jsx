import { useI18n } from '../i18n'
import { Layout } from './Layout'
import { Bento, Faq, FinalCta, Manifesto, Pricing } from '../home/Rest'
import { Calculator, Hero, Marquee } from '../home/Hero'
import { Tutorial } from '../home/Tutorial'
import '../home/home.css'

/**
 * Landing: herói com o app funcionando, faixa de categorias, calculadora,
 * tutorial interativo fixo na tela, recursos, manifesto, preços, dúvidas e
 * chamada final. Trocar o idioma remonta as seções (os títulos animados
 * dividem o texto em linhas, então precisam recomeçar do zero).
 */
export function Home() {
  const { lang } = useI18n()

  return (
    <Layout page="home">
      <div className="lp" key={lang}>
        <Hero lang={lang} />
        <Marquee lang={lang} />
        <Calculator lang={lang} />
        <Tutorial lang={lang} />
        <Bento lang={lang} />
        <Manifesto lang={lang} />
        <Pricing lang={lang} />
        <Faq lang={lang} />
        <FinalCta lang={lang} />
      </div>
    </Layout>
  )
}
