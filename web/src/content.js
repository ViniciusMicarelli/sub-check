// Todo o texto do site, em português e inglês. As chaves de estrutura são as
// mesmas nos dois idiomas, então os componentes não precisam saber o idioma.

export const CONTACT_EMAIL = "viniciusmicarelli@hotmail.com";
export const REPO_URL = "https://github.com/ViniciusMicarelli/sub-check";
// Preencha com o link da App Store depois da aprovação. Enquanto estiver vazio,
// os botões aparecem como “em breve” em vez de levar a um link quebrado.
export const APP_STORE_URL = "";

const shared = {
  year: 2026,
  author: "Vinicius Micarelli",
};

export const content = {
  pt: {
    code: "pt-BR",
    langLabel: "PT",
    soon: "Em breve",
    toc: "Nesta página",
    nav: {
      features: "Recursos",
      how: "Como funciona",
      pro: "Pro",
      faq: "Dúvidas",
      support: "Suporte",
      download: "Baixar",
      home: "Início",
      privacy: "Privacidade",
      terms: "Termos",
    },
    hero: {
      badge: "Novo · contagem regressiva na Ilha Dinâmica",
      title: "Todas as suas assinaturas.",
      titleAccent: "Um único lugar.",
      subtitle:
        "O SubCheck organiza o que você paga todo mês, avisa antes de cada cobrança e mostra onde dá para economizar. Sem planilhas, sem sustos.",
      ctaPrimary: "Baixar para iPhone",
      ctaSecondary: "Ver recursos",
      note: "7 dias grátis · sem assinatura · pagamento único",
    },
    mock: {
      greetingPrefix: "Olá,",
      totalLabel: "Total mensal",
      total: "R$ 287,40",
      yearly: "R$ 3.448,80 por ano",
      active: "5 ativas",
      nextPill: "Próxima: Streaming · em 3 dias",
      island: { label: "Próxima cobrança", service: "Streaming", when: "em 3 dias" },
      metrics: [
        { icon: "grid", label: "Assinaturas ativas", value: "5" },
        { icon: "calendar", label: "Custo por dia", value: "R$ 9,58" },
        { icon: "bell", label: "Vencem em 7 dias", value: "2" },
        { icon: "chart", label: "Custo anual", value: "R$ 3.448" },
      ],
      upcomingTitle: "Próximas cobranças",
      upcomingPeriod: "30 dias",
      upcoming: [
        { icon: "play", name: "Streaming", when: "12 nov", price: "R$ 55,90", days: "em 3 dias", level: "warn" },
        { icon: "music", name: "Música", when: "18 nov", price: "R$ 21,90", days: "em 9 dias", level: "ok" },
        { icon: "cloud", name: "Nuvem", when: "24 nov", price: "R$ 34,90", days: "em 15 dias", level: "ok" },
      ],
      onboarding: {
        skip: "Pular",
        title: "Bem-vindo ao SubCheck",
        body: "Veja todas as suas assinaturas num só lugar e descubra para onde vai o seu dinheiro.",
        namePlaceholder: "Como podemos te chamar?",
        nameHelper: "Serve só para personalizar o resumo. Você pode pular.",
        next: "Continuar",
      },
      add: {
        title: "Nova assinatura",
        cancel: "Cancelar",
        save: "Salvar",
        details: "Detalhes",
        iconTitle: "Ícone",
        categoryTitle: "Categoria",
        detected: "Detectado automaticamente",
        nameLabel: "Nome",
        nameValue: "Streaming",
        valueLabel: "Valor",
        valueValue: "R$ 55,90",
        frequencyLabel: "Frequência",
        frequencyValue: "Mensal",
        dateLabel: "Primeira cobrança",
        dateValue: "12 de novembro",
        categoryValue: "Entretenimento",
      },
      chips: [
        { label: "Custo por dia", value: "R$ 9,58" },
        { label: "Orçamento do mês", value: "74%" },
        { label: "Próxima cobrança", value: "em 3 dias" },
      ],
    },
    story: {
      title: "Veja o SubCheck em ação",
      subtitle: "Role a página: o app se monta na sua frente, do primeiro toque ao painel pronto.",
      namePrompt: "Como podemos te chamar?",
      namePlaceholder: "Digite seu nome",
      nameNote: "Ele aparece no app logo abaixo. Nada sai do seu aparelho.",
      hint: "Role para continuar",
      scenes: [
        {
          title: "Boas-vindas",
          text: "Uma apresentação rápida e o seu nome para personalizar o resumo.",
        },
        {
          title: "Nova assinatura",
          text: "Digite o serviço e o ícone, a categoria e a próxima cobrança vêm preenchidos.",
        },
        {
          title: "Painel pronto",
          text: "Total mensal, custo por dia e as próximas cobranças, tudo num painel só.",
        },
      ],
      finalNote: "Pronto. É assim que o SubCheck fica no seu iPhone.",
    },
    marqueeTitle: "Para todo tipo de assinatura",
    marquee: [
      "Streaming",
      "Música",
      "Nuvem",
      "Academia",
      "Apps",
      "Notícias",
      "Jogos",
      "Educação",
      "Produtividade",
      "Saúde",
    ],
    features: {
      title: "Tudo o que você precisa saber sobre o seu dinheiro recorrente",
      subtitle: "Informação clara, no lugar certo e na hora certa.",
      items: [
        {
          icon: "bolt",
          title: "Cadastre em segundos",
          text: "Digite o nome do serviço e o app preenche o ícone, a categoria e a próxima cobrança.",
        },
        {
          icon: "calendar",
          title: "Veja o que vem por aí",
          text: "Total mensal, custo por dia e o que vence nos próximos 30 dias.",
        },
        {
          icon: "bell",
          title: "Nada de cobrança surpresa",
          text: "Aviso antes de cada cobrança e na véspera do fim de um teste gratuito.",
        },
        {
          icon: "chart",
          title: "Análise completa",
          text: "Evolução, mapa de calor das cobranças, previsão de 12 meses e comparativos.",
        },
        {
          icon: "target",
          title: "Orçamento com alertas",
          text: "Defina um teto mensal e seja avisado assim que ultrapassar.",
        },
        {
          icon: "scissors",
          title: "Simulador de cancelamento",
          text: "Veja exatamente quanto você economizaria cortando cada serviço.",
        },
      ],
      extras: [
        "Relatório em PDF",
        "Exportação em CSV",
        "Widgets",
        "Face ID",
        "Sincronização com iCloud",
        "Multi-moeda",
        "Atalhos e Siri",
        "Português e inglês",
      ],
    },
    showcase: {
      title: "Números que fazem sentido",
      subtitle: "Gráficos pensados para decidir, não para enfeitar.",
      cards: [
        { title: "Evolução dos gastos", text: "Mês a mês e ano a ano, no mesmo lugar." },
        { title: "Custo por dia", text: "Quanto cada assinatura pesa no seu dia." },
        { title: "Previsão de 12 meses", text: "O que você vai gastar até o fim do ano." },
      ],
    },
    steps: {
      title: "Como funciona",
      subtitle: "Três toques e está pronto.",
      items: [
        {
          title: "Adicione",
          text: "Toque em + e escolha o serviço. O ícone e a categoria já vêm preenchidos.",
        },
        {
          title: "Acompanhe",
          text: "Veja o total mensal, o custo por dia e as próximas cobranças num painel só.",
        },
        {
          title: "Economize",
          text: "Receba avisos, analise os gráficos e corte o que não vale mais a pena.",
        },
      ],
    },
    pricing: {
      title: "SubCheck Pro",
      subtitle: "Um pagamento único. Para sempre.",
      badge: "Sem assinatura",
      price: "R$ 39,90",
      period: "uma vez",
      items: [
        "Assinaturas ilimitadas",
        "Análise e histórico completos",
        "Ilha Dinâmica ao vivo",
        "Orçamento com alertas",
        "Simulador de cancelamento",
        "Relatório em PDF e exportação em CSV",
        "Bloqueio por Face ID",
        "Sincronização com iCloud",
      ],
      note: "Comece com 7 dias com todos os recursos liberados. Depois, o plano gratuito continua funcionando.",
      cta: "Baixar na App Store",
    },
    faq: {
      title: "Perguntas frequentes",
      subtitle: "O essencial, sem rodeios.",
      items: [
        {
          q: "O SubCheck Pro é uma assinatura?",
          a: "Não. É uma compra única (não consumível). Você paga uma vez e usa para sempre, sem renovação automática.",
        },
        {
          q: "Como funciona o teste de 7 dias?",
          a: "Ao instalar, você tem 7 dias com todos os recursos liberados, sem cobrança. Quando o período termina, nada é cobrado e o plano gratuito continua funcionando.",
        },
        {
          q: "Meus dados ficam sincronizados entre aparelhos?",
          a: "Sim, se você ligar a sincronização com iCloud (Pro) e entrar na mesma conta nos dois aparelhos. Os dados ficam na sua base privada do iCloud.",
        },
        {
          q: "Preciso criar conta?",
          a: "Não. Não há cadastro, login, analytics ou anúncios. Tudo fica no seu aparelho.",
        },
        {
          q: "Comprei o Pro e troquei de aparelho. Como recupero?",
          a: "Em Ajustes › SubCheck Pro › Ver opções, toque em Restaurar compra usando a mesma conta da App Store.",
        },
      ],
    },
    cta: {
      title: "Comece a controlar suas assinaturas hoje",
      text: "Grátis para começar. 7 dias com todos os recursos liberados.",
      button: "Baixar para iPhone",
    },
    footer: {
      tagline: "Suas assinaturas em um só lugar.",
      productTitle: "Produto",
      legalTitle: "Legal",
      supportTitle: "Suporte",
      rights: `© ${shared.year} ${shared.author}. Todos os direitos reservados.`,
    },
    docs: {
      privacy: {
        kicker: "Legal",
        title: "Política de Privacidade",
        lead: "Sem contas, sem rastreamento e sem anúncios.",
        effective: "Vigente desde 3 de novembro de 2026.",
        summary:
          "O SubCheck não pede cadastro, não usa analytics, não exibe anúncios e não rastreia você. Tudo o que você digita fica no seu aparelho. Se você ligar a sincronização com iCloud, os seus dados vão para a sua própria conta do iCloud — nós não temos acesso a eles.",
        sections: [
          {
            id: "quem-somos",
            title: "Quem somos",
            blocks: [
              {
                p: `O SubCheck é um aplicativo para iPhone desenvolvido por <strong>${shared.author}</strong> (“nós”). Contato para assuntos de privacidade: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.`,
              },
            ],
          },
          {
            id: "dados",
            title: "Dados que você informa",
            blocks: [
              {
                p: "Você pode cadastrar assinaturas (nome do serviço, valor, moeda, frequência, datas, categoria, lembrete e um ícone) e, opcionalmente, um nome para a saudação do app. Esses dados ficam <strong>armazenados no seu aparelho</strong> e são usados apenas para exibir os seus gastos, gerar gráficos, previsões e lembretes.",
              },
            ],
          },
          {
            id: "nao-fazemos",
            title: "O que não fazemos",
            blocks: [
              {
                ul: [
                  "Não criamos conta nem pedimos login.",
                  "Não usamos ferramentas de analytics, publicidade ou rastreamento.",
                  "Não vendemos, alugamos ou compartilhamos os seus dados.",
                  "Não acessamos os seus dados financeiros de bancos ou operadoras.",
                ],
              },
            ],
          },
          {
            id: "icloud",
            title: "iCloud (opcional)",
            blocks: [
              {
                p: "Nas versões com o SubCheck Pro, você pode ligar “Sincronizar com iCloud”. Quando ligado, os seus dados de assinaturas são gravados na <strong>sua base privada do iCloud</strong> (Apple CloudKit), para ficarem iguais nos seus aparelhos. Essa base pertence a você e segue a política de privacidade da Apple; nós não conseguimos ler nem acessar o conteúdo. Você pode desligar a opção a qualquer momento em Ajustes › iCloud.",
              },
            ],
          },
          {
            id: "rede",
            title: "Conexões de rede",
            blocks: [
              {
                p: "<strong>Cotações de moeda:</strong> o app consulta a API pública <code>api.frankfurter.app</code> para atualizar as taxas de câmbio. Nenhum dado pessoal é enviado nessa requisição.",
              },
              {
                p: "<strong>Ícones por endereço:</strong> se você escolher um ícone a partir de um link de imagem, o app baixa essa imagem do endereço que você informou. O site escolhido pode registrar a requisição, como qualquer acesso à internet.",
              },
            ],
          },
          {
            id: "seguranca",
            title: "Face ID, notificações e compras",
            blocks: [
              {
                ul: [
                  "<strong>Face ID / senha:</strong> o desbloqueio é feito pelo iOS (LocalAuthentication). O app recebe apenas “liberado” ou “não liberado” — nunca os seus dados biométricos.",
                  "<strong>Notificações:</strong> os lembretes de cobrança são agendados localmente no aparelho. Não enviamos notificações por servidores nossos.",
                  "<strong>Compras:</strong> o pagamento do SubCheck Pro é processado pela Apple (StoreKit). Nós não recebemos nem armazenamos dados do seu cartão. Guardamos apenas se o Pro está desbloqueado neste aparelho.",
                ],
              },
            ],
          },
          {
            id: "retencao",
            title: "Por quanto tempo guardamos",
            blocks: [
              {
                p: "Os dados ficam no aparelho enquanto o app estiver instalado ou até você apagá-los. Para remover tudo, use <em>Ajustes › Apagar todos os dados</em> dentro do app, ou desinstale o aplicativo. Se a sincronização com iCloud estiver ligada, remova os dados pelo próprio iCloud (Ajustes do iOS › Apple ID › iCloud › Gerenciar armazenamento).",
              },
            ],
          },
          {
            id: "direitos",
            title: "Seus direitos (LGPD e GDPR)",
            blocks: [
              {
                p: `Como os dados ficam sob o seu controle no seu aparelho (e na sua conta do iCloud), você já exerce os direitos de acesso, correção, exclusão e portabilidade diretamente no app — inclusive exportando seus dados em CSV ou PDF. Se tiver qualquer dúvida, escreva para <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.`,
              },
            ],
          },
          {
            id: "criancas",
            title: "Crianças",
            blocks: [
              {
                p: "O SubCheck não é direcionado a crianças e não coleta dados pessoais de menores. Não há coleta de dados de qualquer usuário.",
              },
            ],
          },
          {
            id: "alteracoes",
            title: "Alterações",
            blocks: [
              {
                p: "Podemos atualizar esta política para refletir mudanças no app ou na lei. A data de vigência no topo sempre indica a versão mais recente.",
              },
            ],
          },
          {
            id: "contato",
            title: "Contato",
            blocks: [
              {
                p: `Dúvidas sobre privacidade: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>. Veja também a página de <a href="support.html">Suporte</a>.`,
              },
            ],
          },
        ],
      },
      terms: {
        kicker: "Legal",
        title: "Termos de Uso",
        lead: "Pagamento único, sem assinatura e sem renovação.",
        effective: "Vigente desde 3 de novembro de 2026.",
        summary:
          "Ao instalar e usar o SubCheck, você concorda com estes Termos. O SubCheck Pro é uma compra única: não há renovação automática e nada é cobrado de novo.",
        sections: [
          {
            id: "licenca",
            title: "Licença de uso",
            blocks: [
              {
                p: `Concedemos a você uma licença pessoal, não exclusiva e intransferível para usar o SubCheck nos aparelhos vinculados à sua conta da App Store, conforme as <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Regras de Uso padrão da Apple</a> (Licença de Usuário Final).`,
              },
            ],
          },
          {
            id: "pro",
            title: "SubCheck Pro e teste gratuito",
            blocks: [
              {
                ul: [
                  "O <strong>SubCheck Pro</strong> é uma <strong>compra única</strong> (não consumível). Não é uma assinatura: não há renovação automática e nada é cobrado de novo.",
                  "Ao instalar, você tem <strong>7 dias</strong> com todos os recursos liberados, sem cobrança. É uma liberação temporária e <strong>não</strong> gera nenhuma assinatura nem cobrança automática ao terminar.",
                  "Depois do período, o app continua funcionando no plano gratuito (com limites, como número de assinaturas e recursos avançados). A compra única libera tudo para sempre.",
                  "Pagamentos, impostos e reembolsos são processados pela Apple. Pedidos de reembolso seguem as políticas da App Store.",
                ],
              },
            ],
          },
          {
            id: "uso",
            title: "Uso adequado",
            blocks: [
              {
                p: "Você é responsável pelas informações que cadastra e por manter uma cópia dos seus dados. Não é permitido usar o app para fins ilícitos, para tentar burlar mecanismos de compra ou para redistribuí-lo sem autorização.",
              },
            ],
          },
          {
            id: "estimativas",
            title: "Cotações, previsões e informações",
            blocks: [
              {
                p: "Os totais, gráficos, previsões e cotações de moeda são <strong>estimativas</strong> geradas a partir dos dados que você informa e de fontes públicas de câmbio (como <code>api.frankfurter.app</code>). Eles podem conter imprecisões e têm caráter meramente informativo. O SubCheck <strong>não é consultoria financeira</strong> e não substitui os termos, faturas ou avisos dos serviços que você assina.",
              },
            ],
          },
          {
            id: "marcas",
            title: "Marcas de terceiros",
            blocks: [
              {
                p: "Nomes, marcas e logotipos de serviços (por exemplo, plataformas de streaming) são propriedade de seus respectivos donos. O SubCheck não é afiliado, patrocinado nem endossado por esses serviços.",
              },
            ],
          },
          {
            id: "responsabilidade",
            title: "Limitação de responsabilidade",
            blocks: [
              {
                p: "O app é fornecido “no estado em que se encontra”. Na máxima extensão permitida pela lei, não nos responsabilizamos por lucros cessantes, dados perdidos ou danos indiretos decorrentes do uso do app, inclusive decisões tomadas com base nas estimativas apresentadas.",
              },
            ],
          },
          {
            id: "alteracoes",
            title: "Alterações",
            blocks: [
              {
                p: "Podemos atualizar estes Termos. A versão vigente é sempre a publicada nesta página, com a data de vigência indicada no topo. O uso contínuo após uma alteração significa que você concorda com os novos Termos.",
              },
            ],
          },
          {
            id: "lei",
            title: "Lei aplicável",
            blocks: [
              {
                p: "Estes Termos são regidos pelas leis do Brasil. Eventuais controvérsias serão resolvidas no foro do domicílio do consumidor, quando aplicável.",
              },
            ],
          },
          {
            id: "contato",
            title: "Contato",
            blocks: [
              {
                p: `Dúvidas: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>. Veja também a <a href="privacy.html">Política de Privacidade</a> e o <a href="support.html">Suporte</a>.`,
              },
            ],
          },
        ],
      },
    },
    support: {
      kicker: "Ajuda",
      title: "Suporte",
      lead: "Precisa de ajuda com o SubCheck? Estamos por aqui.",
      contactTitle: "Fale com a gente",
      contactText: "Escreva para o e-mail abaixo ou abra um tópico no repositório. Respondemos em até 2 dias úteis.",
      emailLabel: "E-mail",
      repoLabel: "Abrir um tópico",
      tip: "Para agilizar, conte o modelo do seu iPhone, a versão do iOS e o que aconteceu. Se possível, anexe uma captura de tela.",
      faqTitle: "Perguntas frequentes",
      faq: [
        {
          q: "Como adiciono uma assinatura?",
          a: "Toque no botão + na tela Resumo ou Assinaturas. Digite o nome do serviço; o ícone, a categoria e a próxima cobrança são preenchidos automaticamente. Você pode ajustar tudo antes de salvar.",
        },
        {
          q: "O que é o SubCheck Pro?",
          a: "É uma compra única (não consumível) que libera todos os recursos para sempre: assinaturas ilimitadas, Análise, Ilha Dinâmica, orçamento com alertas, simulador de cancelamento, relatório em PDF, exportação em CSV, bloqueio por Face ID e sincronização com iCloud. Não é assinatura e não renova.",
        },
        {
          q: "Como funciona o teste de 7 dias?",
          a: "Ao instalar, você tem 7 dias com tudo liberado, sem cobrança. Não é uma assinatura: quando o período termina, nada é cobrado. O app continua funcionando no plano gratuito.",
        },
        {
          q: "Comprei o Pro e troquei de aparelho. Como recupero?",
          a: "Abra Ajustes › SubCheck Pro › Ver opções e toque em Restaurar compra. Use a mesma conta da App Store da compra.",
        },
        {
          q: "Os meus dados ficam sincronizados entre aparelhos?",
          a: "Sim, se você ligar Ajustes › Sincronizar com iCloud (Pro) e entrar na mesma conta do iCloud em ambos. A sincronização acontece pela sua base privada do iCloud.",
        },
        {
          q: "A Ilha Dinâmica não aparece. O que fazer?",
          a: "Confirme que o aparelho tem Ilha Dinâmica (iPhone 14 Pro ou mais novo), deixe Atividades ao Vivo ligadas em Ajustes do iOS › SubCheck e use Ajustes › Ilha Dinâmica › Testar no app. Depois saia do app: a ilha aparece quando o SubCheck não está na frente.",
        },
        {
          q: "Como apago todos os meus dados?",
          a: "Em Ajustes › Apagar todos os dados. Isso remove as assinaturas e o histórico do aparelho. Se a sincronização com iCloud estiver ligada, remova também pelo iCloud (Ajustes do iOS › Apple ID › iCloud › Gerenciar armazenamento). Desinstalar o app também apaga os dados locais.",
        },
        {
          q: "Os valores e as cotações estão errados.",
          a: "Os totais e a conversão de moeda são estimativas com base no que você cadastrou e em fontes públicas de câmbio. Confira sempre na fatura do serviço. Você pode atualizar as cotações em Ajustes › Moeda e cotação › Atualizar cotação.",
        },
      ],
      finalTitle: "Ainda com dúvida?",
      finalText: "Fale com a gente por e-mail e respondemos o quanto antes.",
    },
  },

  en: {
    code: "en",
    langLabel: "EN",
    soon: "Coming soon",
    toc: "On this page",
    nav: {
      features: "Features",
      how: "How it works",
      pro: "Pro",
      faq: "FAQ",
      support: "Support",
      download: "Get the app",
      home: "Home",
      privacy: "Privacy",
      terms: "Terms",
    },
    hero: {
      badge: "New · countdown in the Dynamic Island",
      title: "All your subscriptions.",
      titleAccent: "One single place.",
      subtitle:
        "SubCheck organizes what you pay every month, warns you before each charge and shows where you can save. No spreadsheets, no surprises.",
      ctaPrimary: "Download for iPhone",
      ctaSecondary: "See features",
      note: "7 days free · no subscription · one-time payment",
    },
    mock: {
      greetingPrefix: "Hi,",
      totalLabel: "Monthly total",
      total: "R$ 287.40",
      yearly: "R$ 3,448.80 per year",
      active: "5 active",
      nextPill: "Next: Streaming · in 3 days",
      island: { label: "Next charge", service: "Streaming", when: "in 3 days" },
      metrics: [
        { icon: "grid", label: "Active subscriptions", value: "5" },
        { icon: "calendar", label: "Cost per day", value: "R$ 9.58" },
        { icon: "bell", label: "Due in 7 days", value: "2" },
        { icon: "chart", label: "Yearly cost", value: "R$ 3,448" },
      ],
      upcomingTitle: "Upcoming charges",
      upcomingPeriod: "30 days",
      upcoming: [
        { icon: "play", name: "Streaming", when: "Nov 12", price: "R$ 55.90", days: "in 3 days", level: "warn" },
        { icon: "music", name: "Music", when: "Nov 18", price: "R$ 21.90", days: "in 9 days", level: "ok" },
        { icon: "cloud", name: "Cloud", when: "Nov 24", price: "R$ 34.90", days: "in 15 days", level: "ok" },
      ],
      onboarding: {
        skip: "Skip",
        title: "Welcome to SubCheck",
        body: "See all your subscriptions in one place and find out where your money goes.",
        namePlaceholder: "What should we call you?",
        nameHelper: "It only personalises the summary. You can skip it.",
        next: "Continue",
      },
      add: {
        title: "New subscription",
        cancel: "Cancel",
        save: "Save",
        details: "Details",
        iconTitle: "Icon",
        categoryTitle: "Category",
        detected: "Detected automatically",
        nameLabel: "Name",
        nameValue: "Streaming",
        valueLabel: "Amount",
        valueValue: "R$ 55.90",
        frequencyLabel: "Frequency",
        frequencyValue: "Monthly",
        dateLabel: "First charge",
        dateValue: "November 12",
        categoryValue: "Entertainment",
      },
      chips: [
        { label: "Cost per day", value: "R$ 9.58" },
        { label: "Monthly budget", value: "74%" },
        { label: "Next charge", value: "in 3 days" },
      ],
    },
    story: {
      title: "See SubCheck in action",
      subtitle: "Scroll the page: the app builds itself in front of you, from the first tap to a ready dashboard.",
      namePrompt: "What should we call you?",
      namePlaceholder: "Type your name",
      nameNote: "It shows up in the app below. Nothing leaves your device.",
      hint: "Keep scrolling",
      scenes: [
        {
          title: "Welcome",
          text: "A quick introduction and your name to personalise the summary.",
        },
        {
          title: "New subscription",
          text: "Type the service and the icon, the category and the next charge come filled in.",
        },
        {
          title: "Dashboard ready",
          text: "Monthly total, cost per day and the next charges, all on one panel.",
        },
      ],
      finalNote: "Done. That is what SubCheck looks like on your iPhone.",
    },
    marqueeTitle: "For every kind of subscription",
    marquee: [
      "Streaming",
      "Music",
      "Cloud",
      "Gym",
      "Apps",
      "News",
      "Games",
      "Education",
      "Productivity",
      "Health",
    ],
    features: {
      title: "Everything you need to know about your recurring spending",
      subtitle: "Clear information, in the right place, at the right time.",
      items: [
        {
          icon: "bolt",
          title: "Add in seconds",
          text: "Type the service name and the app fills in the icon, the category and the next charge.",
        },
        {
          icon: "calendar",
          title: "Know what's coming",
          text: "Monthly total, cost per day and what is due in the next 30 days.",
        },
        {
          icon: "bell",
          title: "No surprise charges",
          text: "A heads-up before every charge and the day before a free trial ends.",
        },
        {
          icon: "chart",
          title: "Full analysis",
          text: "Trends, a charge heatmap, a 12-month forecast and comparisons.",
        },
        {
          icon: "target",
          title: "Budget with alerts",
          text: "Set a monthly cap and get warned as soon as you go over it.",
        },
        {
          icon: "scissors",
          title: "Cancellation simulator",
          text: "See exactly how much you would save by cutting each service.",
        },
      ],
      extras: [
        "PDF report",
        "CSV export",
        "Widgets",
        "Face ID",
        "iCloud sync",
        "Multi-currency",
        "Shortcuts and Siri",
        "English and Portuguese",
      ],
    },
    showcase: {
      title: "Numbers that make sense",
      subtitle: "Charts built to help you decide, not to decorate.",
      cards: [
        { title: "Spending trends", text: "Month over month and year over year, all in one place." },
        { title: "Cost per day", text: "How much each subscription weighs on your day." },
        { title: "12-month forecast", text: "What you will spend until the end of the year." },
      ],
    },
    steps: {
      title: "How it works",
      subtitle: "Three taps and you're set.",
      items: [
        {
          title: "Add",
          text: "Tap + and pick the service. The icon and the category come filled in.",
        },
        {
          title: "Track",
          text: "See your monthly total, the cost per day and the next charges on one panel.",
        },
        {
          title: "Save",
          text: "Get alerts, read the charts and cut what is no longer worth it.",
        },
      ],
    },
    pricing: {
      title: "SubCheck Pro",
      subtitle: "One payment. Forever.",
      badge: "No subscription",
      price: "R$ 39.90",
      period: "one time",
      items: [
        "Unlimited subscriptions",
        "Full analysis and history",
        "Live Dynamic Island",
        "Budget with alerts",
        "Cancellation simulator",
        "PDF report and CSV export",
        "Face ID lock",
        "iCloud sync",
      ],
      note: "Start with 7 days with every feature unlocked. After that, the free plan keeps working.",
      cta: "Download on the App Store",
    },
    faq: {
      title: "Frequently asked questions",
      subtitle: "The essentials, no fluff.",
      items: [
        {
          q: "Is SubCheck Pro a subscription?",
          a: "No. It is a one-time purchase (non-consumable). You pay once and use it forever, with no auto-renewal.",
        },
        {
          q: "How does the 7-day trial work?",
          a: "When you install the app you get 7 days with every feature unlocked, free of charge. When the period ends, nothing is charged and the free plan keeps working.",
        },
        {
          q: "Do my data sync between devices?",
          a: "Yes, if you turn on iCloud sync (Pro) and sign in with the same account on both devices. Your data lives in your own private iCloud database.",
        },
        {
          q: "Do I need an account?",
          a: "No. There is no sign-up, login, analytics or ads. Everything stays on your device.",
        },
        {
          q: "I bought Pro and changed phones. How do I restore it?",
          a: "In Settings › SubCheck Pro › See options, tap Restore purchase using the same App Store account.",
        },
      ],
    },
    cta: {
      title: "Start tracking your subscriptions today",
      text: "Free to start. 7 days with every feature unlocked.",
      button: "Download for iPhone",
    },
    footer: {
      tagline: "All your subscriptions in one place.",
      productTitle: "Product",
      legalTitle: "Legal",
      supportTitle: "Support",
      rights: `© ${shared.year} ${shared.author}. All rights reserved.`,
    },
    docs: {
      privacy: {
        kicker: "Legal",
        title: "Privacy Policy",
        lead: "No accounts, no tracking, no ads.",
        effective: "Effective November 3, 2026.",
        summary:
          "SubCheck has no sign-up, no analytics, no ads and no tracking. Everything you type stays on your device. If you turn on iCloud sync, your data goes to your own iCloud account — we cannot access it.",
        sections: [
          {
            id: "who",
            title: "Who we are",
            blocks: [
              {
                p: `SubCheck is an iPhone app developed by <strong>${shared.author}</strong> (“we”). Privacy contact: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.`,
              },
            ],
          },
          {
            id: "data",
            title: "Data you enter",
            blocks: [
              {
                p: "You can add subscriptions (service name, amount, currency, frequency, dates, category, reminder and an icon) and, optionally, a name used for the app greeting. This data is <strong>stored on your device</strong> and used only to show your spending, charts, forecasts and reminders.",
              },
            ],
          },
          {
            id: "never",
            title: "What we do not do",
            blocks: [
              {
                ul: [
                  "We do not create accounts or ask you to log in.",
                  "We do not use analytics, advertising or tracking tools.",
                  "We do not sell, rent or share your data.",
                  "We do not access your financial data from banks or carriers.",
                ],
              },
            ],
          },
          {
            id: "icloud",
            title: "iCloud (optional)",
            blocks: [
              {
                p: "In builds with SubCheck Pro you can turn on “Sync with iCloud”. When on, your subscription data is written to <strong>your own private iCloud database</strong> (Apple CloudKit) so it stays the same across your devices. That database belongs to you and is governed by Apple's privacy policy; we cannot read or access its contents. You can turn it off anytime in Settings › iCloud.",
              },
            ],
          },
          {
            id: "network",
            title: "Network connections",
            blocks: [
              {
                p: "<strong>Exchange rates:</strong> the app calls the public <code>api.frankfurter.app</code> API to refresh currency rates. No personal data is sent in that request.",
              },
              {
                p: "<strong>Icons from a URL:</strong> if you choose an icon from an image link, the app downloads that image from the address you provided. The chosen site may log the request, as with any internet access.",
              },
            ],
          },
          {
            id: "security",
            title: "Face ID, notifications and purchases",
            blocks: [
              {
                ul: [
                  "<strong>Face ID / passcode:</strong> unlocking is handled by iOS (LocalAuthentication). The app only receives “unlocked” or “not unlocked” — never your biometric data.",
                  "<strong>Notifications:</strong> charge reminders are scheduled locally on the device. We do not send notifications from our servers.",
                  "<strong>Purchases:</strong> SubCheck Pro payments are processed by Apple (StoreKit). We never receive or store your card details. We only keep whether Pro is unlocked on this device.",
                ],
              },
            ],
          },
          {
            id: "retention",
            title: "How long we keep it",
            blocks: [
              {
                p: "Data stays on the device while the app is installed or until you delete it. To remove everything, use <em>Settings › Erase all data</em> inside the app, or uninstall the app. If iCloud sync is on, remove the data from iCloud itself (iOS Settings › Apple ID › iCloud › Manage Storage).",
              },
            ],
          },
          {
            id: "rights",
            title: "Your rights (GDPR and LGPD)",
            blocks: [
              {
                p: `Because the data stays under your control on your device (and in your iCloud account), you already exercise your access, correction, deletion and portability rights directly in the app — including exporting your data as CSV or PDF. Any question, email <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.`,
              },
            ],
          },
          {
            id: "children",
            title: "Children",
            blocks: [
              {
                p: "SubCheck is not directed to children and does not collect personal data from minors. It collects no data from any user.",
              },
            ],
          },
          {
            id: "changes",
            title: "Changes",
            blocks: [
              {
                p: "We may update this policy to reflect changes in the app or the law. The effective date at the top always shows the latest version.",
              },
            ],
          },
          {
            id: "contact",
            title: "Contact",
            blocks: [
              {
                p: `Privacy questions: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>. See also the <a href="support.html">Support</a> page.`,
              },
            ],
          },
        ],
      },
      terms: {
        kicker: "Legal",
        title: "Terms of Use",
        lead: "One-time payment, no subscription, no renewal.",
        effective: "Effective November 3, 2026.",
        summary:
          "By installing and using SubCheck, you agree to these Terms. SubCheck Pro is a one-time purchase: there is no auto-renewal and you are never charged again.",
        sections: [
          {
            id: "license",
            title: "License",
            blocks: [
              {
                p: `We grant you a personal, non-exclusive, non-transferable license to use SubCheck on the devices linked to your App Store account, under <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Apple's standard Licensed Application End User License Agreement</a>.`,
              },
            ],
          },
          {
            id: "pro",
            title: "SubCheck Pro and free trial",
            blocks: [
              {
                ul: [
                  "<strong>SubCheck Pro</strong> is a <strong>one-time purchase</strong> (non-consumable). It is not a subscription: there is no auto-renewal and you are never charged again.",
                  "When you install the app you get <strong>7 days</strong> with every feature unlocked, free of charge. It is a temporary unlock and does <strong>not</strong> create a subscription or any automatic charge when it ends.",
                  "After that period the app keeps working on the free plan (with limits such as the number of subscriptions and advanced features). The one-time purchase unlocks everything for good.",
                  "Payments, taxes and refunds are handled by Apple. Refund requests follow App Store policies.",
                ],
              },
            ],
          },
          {
            id: "use",
            title: "Acceptable use",
            blocks: [
              {
                p: "You are responsible for the information you enter and for keeping a copy of your data. You may not use the app for unlawful purposes, to circumvent purchasing, or to redistribute it without permission.",
              },
            ],
          },
          {
            id: "estimates",
            title: "Rates, forecasts and information",
            blocks: [
              {
                p: "Totals, charts, forecasts and currency rates are <strong>estimates</strong> generated from the data you enter and from public exchange-rate sources (such as <code>api.frankfurter.app</code>). They may be inaccurate and are provided for information only. SubCheck <strong>is not financial advice</strong> and does not replace the terms, invoices or notices of the services you subscribe to.",
              },
            ],
          },
          {
            id: "trademarks",
            title: "Third-party brands",
            blocks: [
              {
                p: "Service names, brands and logos (for example, streaming platforms) are the property of their respective owners. SubCheck is not affiliated with, sponsored by or endorsed by those services.",
              },
            ],
          },
          {
            id: "liability",
            title: "Limitation of liability",
            blocks: [
              {
                p: "The app is provided “as is”. To the maximum extent permitted by law, we are not liable for lost profits, lost data or indirect damages arising from the use of the app, including decisions made based on the estimates it shows.",
              },
            ],
          },
          {
            id: "changes",
            title: "Changes",
            blocks: [
              {
                p: "We may update these Terms. The current version is always the one published on this page, with the effective date shown at the top. Continued use after a change means you accept the new Terms.",
              },
            ],
          },
          {
            id: "law",
            title: "Governing law",
            blocks: [
              {
                p: "These Terms are governed by the laws of Brazil. Any dispute will be resolved in the consumer's home jurisdiction, where applicable.",
              },
            ],
          },
          {
            id: "contact",
            title: "Contact",
            blocks: [
              {
                p: `Questions: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>. See also the <a href="privacy.html">Privacy Policy</a> and <a href="support.html">Support</a>.`,
              },
            ],
          },
        ],
      },
    },
    support: {
      kicker: "Help",
      title: "Support",
      lead: "Need help with SubCheck? We're here.",
      contactTitle: "Get in touch",
      contactText: "Email us below or open a topic in the repository. We reply within 2 business days.",
      emailLabel: "Email",
      repoLabel: "Open a topic",
      tip: "To help us faster, tell us your iPhone model, your iOS version and what happened. A screenshot helps a lot.",
      faqTitle: "Frequently asked questions",
      faq: [
        {
          q: "How do I add a subscription?",
          a: "Tap the + button on the Overview or Subscriptions screen. Type the service name; the icon, the category and the next charge are filled in automatically. You can adjust everything before saving.",
        },
        {
          q: "What is SubCheck Pro?",
          a: "A one-time purchase (non-consumable) that unlocks every feature for good: unlimited subscriptions, Analysis, Dynamic Island, budget with alerts, cancellation simulator, PDF report, CSV export, Face ID lock and iCloud sync. It is not a subscription and does not renew.",
        },
        {
          q: "How does the 7-day trial work?",
          a: "When you install the app you get 7 days with everything unlocked, free of charge. It is not a subscription: when the period ends, nothing is charged. The app keeps working on the free plan.",
        },
        {
          q: "I bought Pro and changed phones. How do I restore it?",
          a: "Open Settings › SubCheck Pro › See options and tap Restore purchase. Use the same App Store account you bought it with.",
        },
        {
          q: "Do my data sync between devices?",
          a: "Yes, if you turn on Settings › Sync with iCloud (Pro) and sign in with the same iCloud account on both devices. Syncing happens through your own private iCloud database.",
        },
        {
          q: "The Dynamic Island does not show up. What should I do?",
          a: "Make sure the device has a Dynamic Island (iPhone 14 Pro or newer), keep Live Activities on in iOS Settings › SubCheck, and use Settings › Dynamic Island › Test in the app. Then leave the app: the island shows while SubCheck is not in the foreground.",
        },
        {
          q: "How do I delete all my data?",
          a: "In Settings › Erase all data. This removes subscriptions and history from the device. If iCloud sync is on, also remove it from iCloud (iOS Settings › Apple ID › iCloud › Manage Storage). Uninstalling the app also deletes local data.",
        },
        {
          q: "The amounts and rates look wrong.",
          a: "Totals and currency conversion are estimates based on what you entered and on public exchange-rate sources. Always check the service's invoice. You can refresh rates in Settings › Currency & rates › Refresh rates.",
        },
      ],
      finalTitle: "Still stuck?",
      finalText: "Email us and we'll get back to you as soon as we can.",
    },
  },
};

export const otherLang = { pt: "en", en: "pt" };
