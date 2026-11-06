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
      note: "Ative 7 dias com todos os recursos liberados quando quiser. Depois, o plano gratuito continua funcionando.",
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
          a: "O teste não começa sozinho. Na introdução (ou depois, em Ajustes) você escolhe entre “Ativar 7 dias grátis” e “Continuar no grátis”. Ao ativar, todos os recursos do Pro ficam liberados por 7 dias, sem cartão e sem cobrança. Quando termina, nada é cobrado e o plano gratuito continua funcionando.",
        },
        {
          q: "O que é grátis e o que é Pro?",
          a: "Grátis: até 5 assinaturas ativas e 5 contas da casa, salário líquido e quanto sobra no mês, painel, widgets, avisos antes de cada cobrança, Siri e Atalhos, importar do extrato, cotação por pagamento, projeção com reajuste e guias de cancelamento. Pro: assinaturas e contas ilimitadas, Análise com previsão de 12 meses, insights completos, Ilha Dinâmica, orçamento com alertas, simulador de cancelamento, relatório em PDF e exportação em CSV, Face ID e sincronização com iCloud.",
        },
        {
          q: "Como funcionam as contas da casa?",
          a: "Informe seu salário líquido (já com os descontos) e cadastre contas como água, luz, internet e aluguel, com o dia do vencimento. As fixas já vêm com o valor; nas que variam, você digita o valor no dia em que vencem, e o SubCheck avisa nesse dia (às 9h, e à noite se ainda faltar o valor). O app mostra quanto sobra do salário depois das contas e das assinaturas, tem calendário, navegação por meses com previsão e a evolução de cada conta, para você ver quando ela subiu. Tudo fica no seu aparelho: o salário não é enviado nem sincronizado.",
        },
        {
          q: "Como a Siri funciona?",
          a: "Diga “Ei Siri, registrar pagamento de Netflix no SubCheck” para marcar uma cobrança como paga. Também dá para adicionar uma assinatura, atualizar um valor ou perguntar a próxima cobrança. A fala é interpretada pela Apple; o SubCheck recebe só o nome e o valor e executa tudo no seu aparelho. Há um passo a passo em Ajustes › Siri e Atalhos.",
        },
        {
          q: "Posso importar o extrato do meu banco? É seguro?",
          a: "Sim. Exporte o extrato em CSV no app do banco e escolha o arquivo na aba Assinaturas. O arquivo é lido só no seu iPhone para achar cobranças que se repetem: não é enviado a nenhum servidor, não é guardado e o SubCheck nunca acessa a sua conta bancária.",
        },
        {
          q: "Como funciona a cotação do dólar?",
          a: "Cada pagamento em moeda estrangeira guarda a cotação do dia. Na assinatura, em Histórico e cotação, você vê quanto o câmbio mudou o custo desde então. Pagamentos de antes do app guardar cotações aparecem como “sem cotação”, em vez de um número inventado.",
        },
        {
          q: "A Ilha Dinâmica fica sempre ativa?",
          a: "O iOS encerra a atividade depois de cerca de 8 horas, e ela volta quando você abre o SubCheck. Precisa de iPhone 14 Pro ou mais novo e faz parte do Pro.",
        },
        {
          q: "Meus dados ficam sincronizados entre aparelhos?",
          a: "Sim, se você ligar a sincronização com iCloud (Pro), na introdução ou em Ajustes, e entrar na mesma conta nos dois aparelhos. Os dados ficam na sua base privada do iCloud.",
        },
        {
          q: "Preciso criar conta?",
          a: "Não. Não há cadastro, login, analytics ou anúncios. Tudo fica no seu aparelho.",
        },
        {
          q: "Comprei o Pro e troquei de aparelho. Como recupero?",
          a: "Em Ajustes › SubCheck Pro › Ver opções, toque em Restaurar compra usando a mesma conta da App Store.",
        },
        {
          q: "Funciona no iPad ou no Mac?",
          a: "A versão 1.0 é só para iPhone. iPad e Mac ficam para uma próxima versão.",
        },
      ],
    },
    cta: {
      title: "Comece a controlar suas assinaturas hoje",
      text: "Grátis para começar. Ative 7 dias com todos os recursos liberados quando quiser.",
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
        effective: "Vigente desde 5 de novembro de 2026.",
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
              {
                p: "Você também pode informar o seu <strong>salário líquido</strong> e cadastrar <strong>contas recorrentes</strong> (nome, dia do vencimento e os valores que você digitar). Esses dados ficam no seu aparelho e servem só para mostrar quanto sobra no mês. O salário não é enviado a ninguém nem sincronizado.",
              },
              {
                p: "Cada pagamento registrado guarda também a <strong>cotação da moeda no dia</strong>, para mostrar quanto o câmbio mudou o custo desde então. Esse histórico fica no seu aparelho.",
              },
              {
                p: "<strong>Importar do extrato (opcional):</strong> se você escolher um arquivo CSV do seu banco ou cartão, ele é lido <strong>apenas no seu aparelho</strong> para encontrar cobranças que se repetem. O arquivo não é enviado a nenhum servidor e não é copiado: só as assinaturas que você confirmar são cadastradas.",
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
                p: "Nas versões com o SubCheck Pro, você pode ligar “Sincronizar com iCloud”. Quando ligado, os seus dados de assinaturas e contas são gravados na <strong>sua base privada do iCloud</strong> (Apple CloudKit), para ficarem iguais nos seus aparelhos. Essa base pertence a você e segue a política de privacidade da Apple; nós não conseguimos ler nem acessar o conteúdo. Você pode desligar a opção a qualquer momento em Ajustes › iCloud.",
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
                  "<strong>Siri e Atalhos:</strong> a fala é interpretada pela Apple. O SubCheck recebe só o nome da assinatura e o valor para executar a ação no seu aparelho.",
                  "<strong>Teste grátis:</strong> o teste só começa quando você o ativa; a data de ativação fica guardada no Keychain do aparelho, para o teste não reiniciar ao reinstalar. Não enviamos essa data a lugar nenhum.",
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
                  "Você pode ativar um teste de <strong>7 dias</strong> com todos os recursos liberados, sem cobrança. O teste <strong>só começa quando você o ativa</strong>. É uma liberação temporária e <strong>não</strong> gera nenhuma assinatura nem cobrança automática ao terminar.",
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
          a: "O teste começa quando você ativa (na introdução, em Ajustes ou no card do Resumo), com tudo liberado por 7 dias e sem cobrança. Não é uma assinatura: quando termina, nada é cobrado e o app continua no plano gratuito.",
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
        {
          q: "Não recebi o aviso da minha conta. O que fazer?",
          a: "O aviso chega às 9h do dia do vencimento (e às 19h se você ainda não informou o valor). Confira em Ajustes do iPhone › Notificações › SubCheck se as notificações estão permitidas. Mesmo sem notificação, ao abrir o app uma folha “Contas para informar” aparece quando há conta vencida ou vencendo hoje. “Depois” adia o recado até amanhã.",
        },
        {
          q: "Como cadastro meu salário e minhas contas?",
          a: "Abra a aba Contas. Toque em “Informar salário” e digite o valor líquido, já com os descontos. Depois toque em + para cadastrar uma conta: nome, dia do vencimento e se o valor é fixo ou varia. No dia do vencimento, toque na conta e digite o valor. O salário fica só neste aparelho.",
        },
        {
          q: "Como uso a Siri?",
          a: "Diga “Ei Siri, registrar pagamento de [nome] no SubCheck”. Se ela não responder, ligue o SubCheck em Ajustes do iPhone › Siri › Aplicativos e confira o idioma da Siri. O passo a passo está em Ajustes › Siri e Atalhos.",
        },
        {
          q: "Como importo o extrato do banco?",
          a: "Exporte o extrato em CSV no app do banco, abra a aba Assinaturas e toque no botão de importar. Se o formato não for reconhecido, ele precisa de colunas de data, descrição e valor. O arquivo é lido só no seu aparelho.",
        },
        {
          q: "Por que um pagamento antigo está “sem cotação”?",
          a: "O app guarda a cotação do dia a cada pagamento novo. Pagamentos de antes disso não têm cotação registrada, e preferimos mostrar isso a inventar um valor.",
        },
        {
          q: "O app funciona no iPad?",
          a: "A versão 1.0 é só para iPhone.",
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
      note: "Activate 7 days with every feature unlocked whenever you like. After that, the free plan keeps working.",
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
          a: "The trial never starts by itself. In the intro (or later, in Settings) you choose between “Activate 7 free days” and “Continue on Free”. When you activate it, every Pro feature is unlocked for 7 days, with no card and no charge. When it ends, nothing is charged and the free plan keeps working.",
        },
        {
          q: "What is free and what is Pro?",
          a: "Free: up to 5 active subscriptions and 5 household bills, net salary and what's left each month, dashboard, widgets, alerts before each charge, Siri and Shortcuts, statement import, rate per payment, forecast with price hikes and cancellation guides. Pro: unlimited subscriptions and bills, Analysis with a 12-month forecast, full insights, Dynamic Island, budget with alerts, cancellation simulator, PDF report and CSV export, Face ID and iCloud sync.",
        },
        {
          q: "How do household bills work?",
          a: "Enter your net salary (after deductions) and add bills such as water, electricity, internet and rent, with their due day. Fixed ones come with the amount; for the ones that vary, you type the amount on the day they are due, and SubCheck reminds you that day (at 9 am, and in the evening if the amount is still missing). The app shows how much of your salary is left after bills and subscriptions, has a calendar, month browsing with a forecast and each bill's evolution, so you can see when it went up. Everything stays on your device: your salary is never sent or synced.",
        },
        {
          q: "How does Siri work?",
          a: "Say “Hey Siri, register payment for Netflix in SubCheck” to mark a charge as paid. You can also add a subscription, update a price or ask for the next charge. Speech is interpreted by Apple; SubCheck only receives the name and amount and runs everything on your device. There is a walkthrough in Settings › Siri and Shortcuts.",
        },
        {
          q: "Can I import my bank statement? Is it safe?",
          a: "Yes. Export the statement as CSV from your bank app and pick the file in the Subscriptions tab. The file is read only on your iPhone to find repeating charges: it is not sent to any server, it is not stored, and SubCheck never accesses your bank account.",
        },
        {
          q: "How does the dollar rate work?",
          a: "Each foreign-currency payment keeps that day's rate. On the subscription, under History & exchange rate, you see how much the rate changed its cost since. Payments from before the app kept rates show as “no rate recorded” instead of an invented number.",
        },
        {
          q: "Is the Dynamic Island always on?",
          a: "iOS ends the activity after about 8 hours, and it comes back when you open SubCheck. It needs an iPhone 14 Pro or newer and is part of Pro.",
        },
        {
          q: "Is my data synced between devices?",
          a: "Yes, if you turn on iCloud sync (Pro), in the intro or in Settings, and sign in with the same account on both devices. Your data lives in your own private iCloud database.",
        },
        {
          q: "Do I need an account?",
          a: "No. There is no sign-up, login, analytics or ads. Everything stays on your device.",
        },
        {
          q: "I bought Pro and changed phones. How do I restore it?",
          a: "In Settings › SubCheck Pro › See options, tap Restore Purchase using the same App Store account.",
        },
        {
          q: "Does it work on iPad or Mac?",
          a: "Version 1.0 is iPhone only. iPad and Mac are planned for a later version.",
        },
      ],
    },
    cta: {
      title: "Start tracking your subscriptions today",
      text: "Free to start. Activate 7 days with every feature unlocked whenever you like.",
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
        effective: "Effective November 5, 2026.",
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
              {
                p: "You can also enter your <strong>net salary</strong> and add <strong>recurring bills</strong> (name, due day and the amounts you type). This data stays on your device and is used only to show how much is left in the month. Your salary is never sent to anyone or synced.",
              },
              {
                p: "Each logged payment also keeps the <strong>currency rate of that day</strong>, to show how much the exchange rate changed its cost since. This history stays on your device.",
              },
              {
                p: "<strong>Import from a statement (optional):</strong> if you pick a CSV file from your bank or card, it is read <strong>only on your device</strong> to find repeating charges. The file is not sent to any server and is not copied: only the subscriptions you confirm are added.",
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
                p: "In builds with SubCheck Pro you can turn on “Sync with iCloud”. When on, your subscription and bill data is written to <strong>your own private iCloud database</strong> (Apple CloudKit) so it stays the same across your devices. That database belongs to you and is governed by Apple's privacy policy; we cannot read or access its contents. You can turn it off anytime in Settings › iCloud.",
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
                  "<strong>Siri and Shortcuts:</strong> speech is interpreted by Apple. SubCheck only receives the subscription name and amount to run the action on your device.",
                  "<strong>Free trial:</strong> the trial only starts when you activate it; the activation date is kept in the device Keychain so the trial does not restart on reinstall. We never send this date anywhere.",
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
                  "You can activate a <strong>7-day</strong> trial with every feature unlocked, free of charge. The trial <strong>only starts when you activate it</strong>. It is a temporary unlock and does <strong>not</strong> create a subscription or any automatic charge when it ends.",
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
          a: "The trial starts when you activate it (in the intro, in Settings or on the Overview card), with everything unlocked for 7 days and free of charge. It is not a subscription: when it ends, nothing is charged and the app stays on the free plan.",
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
        {
          q: "I didn't get my bill reminder. What now?",
          a: "The reminder arrives at 9 am on the due date (and at 7 pm if you haven't entered the amount yet). Check iPhone Settings › Notifications › SubCheck to make sure notifications are allowed. Even without a notification, opening the app shows a “Bills to enter” sheet when a bill is overdue or due today. “Later” snoozes it until tomorrow.",
        },
        {
          q: "How do I add my salary and bills?",
          a: "Open the Bills tab. Tap “Enter salary” and type the net amount, after deductions. Then tap + to add a bill: name, due day and whether the amount is fixed or varies. On the due date, tap the bill and type the amount. Your salary stays only on this device.",
        },
        {
          q: "How do I use Siri?",
          a: "Say “Hey Siri, register payment for [name] in SubCheck”. If it does not respond, turn SubCheck on in iPhone Settings › Siri › Apps and check Siri's language. The walkthrough is in Settings › Siri and Shortcuts.",
        },
        {
          q: "How do I import my bank statement?",
          a: "Export the statement as CSV from your bank app, open the Subscriptions tab and tap the import button. If the format is not recognized, it needs date, description and amount columns. The file is read only on your device.",
        },
        {
          q: "Why does an old payment say “no rate recorded”?",
          a: "The app keeps the day's rate with each new payment. Payments from before that have no rate recorded, and we prefer to show that over inventing a number.",
        },
        {
          q: "Does the app work on iPad?",
          a: "Version 1.0 is iPhone only.",
        },
      ],
      finalTitle: "Still stuck?",
      finalText: "Email us and we'll get back to you as soon as we can.",
    },
  },
};

export const otherLang = { pt: "en", en: "pt" };
