# SubCheck — App Store listing (pronto para colar)

Copy bilíngue (pt-BR + English) para o App Store Connect, mais o que preencher
fora do código. Os textos respeitam os limites de caracteres da Apple.

- **Nome do app:** SubCheck
- **Subtítulo:** ver abaixo (máx. 30 caracteres)
- **Bundle ID:** `com.viniciusmicarelli.subcheck`
- **IAP (produto):** `com.viniciusmicarelli.subcheck.pro.lifetime` (não consumível)
- **Idioma principal:** Português (Brasil)
- **Categoria:** Finanças (principal) · Produtividade (secundária)
- **Classificação:** 4+

---

## 1. Campos por idioma

### Português (Brasil)

**Nome (30)**
```
SubCheck
```

**Subtítulo (30)**
```
Controle suas assinaturas
```

**Texto promocional (170)** — pode ser atualizado a qualquer momento sem revisão
```
Descubra para onde vai o seu dinheiro. Acompanhe cada assinatura, receba avisos antes da cobrança e economize de verdade.
```

**Palavras-chave (100, separadas por vírgula, sem espaço)**
```
assinaturas,controle de gastos,orçamento mensal,streaming,cobrança,recorrente,despesas,finanças,widget,ilha dinâmica
```

**Descrição (4000)**
```
Você paga por streaming, música, nuvem, academia, apps… mas sabe quanto isso soma por mês? O SubCheck organiza tudo em um só lugar e mostra, sem enrolação, para onde vai o seu dinheiro.

CADASTRE EM SEGUNDOS
Adicione um serviço e o app preenche o ícone, a categoria e a próxima cobrança para você. Cada assinatura mostra quanto custa por mês e por ano, na sua moeda.

SAIBA O QUE VEM POR AÍ
Veja o total mensal, o custo por dia e o que mais pesa no seu bolso. Acompanhe o que vence nos próximos dias e nos próximos 30 dias.

NADA DE COBRANÇA SURPRESA
Receba um aviso antes de cada cobrança e na véspera do fim de um teste gratuito. No iPhone com Ilha Dinâmica, acompanhe a contagem regressiva ao vivo, direto na tela de bloqueio.

ENTENDA E ECONOMIZE
• Análise com evolução dos gastos e comparação mês a mês e ano a ano.
• Mapa de calor das cobranças e custo por dia.
• Previsão de 12 meses e acumulado.
• Insights automáticos que apontam onde dá para cortar.
• Simulador de cancelamento: veja quanto você economizaria.
• Orçamento mensal com alerta ao ultrapassar.

FEITO PARA O SEU DIA A DIA
• Múltiplas moedas, com cotação atualizada automaticamente.
• Widgets para a tela de início e a tela de bloqueio.
• Relatório em PDF e exportação em CSV.
• Bloqueio por Face ID e sincronização opcional com iCloud.
• Atalhos e Siri para consultar seus gastos por voz.
• Português e inglês.

SubCheck Pro
Um pagamento único libera todos os recursos para sempre, sem assinatura e sem renovação.

Comece grátis: você tem 7 dias para experimentar tudo.
```

**Novidades (4000)**
```
Primeira versão do SubCheck.
```

### English

**Name (30)**
```
SubCheck
```

**Subtitle (30)**
```
Control your subscriptions
```

**Promotional text (170)**
```
See where your money goes. Track every subscription, get warned before each charge and actually save money.
```

**Keywords (100)**
```
subscriptions,recurring spending,monthly budget,streaming,bills,tracker,expenses,finance,widget,dynamic island
```

**Description (4000)**
```
You pay for streaming, music, cloud storage, the gym, apps… but do you know how much that adds up to each month? SubCheck keeps it all in one place and shows, plainly, where your money goes.

ADD IN SECONDS
Add a service and the app fills in the icon, the category and the next charge for you. Each subscription shows what it costs per month and per year, in your currency.

KNOW WHAT'S COMING
See your monthly total, the cost per day and what weighs most on your wallet. Track what is due in the coming days and the next 30 days.

NO SURPRISE CHARGES
Get a heads-up before every charge and the day before a free trial ends. On iPhone with the Dynamic Island, follow the live countdown right from the Lock Screen.

UNDERSTAND AND SAVE
• Analysis with spending trends and month-over-month, year-over-year comparisons.
• Charge heatmap and cost per day.
• 12-month forecast and cumulative view.
• Automatic insights pointing out where to cut.
• Cancellation simulator: see how much you would save.
• Monthly budget with an alert when you go over.

BUILT FOR YOUR ROUTINE
• Multiple currencies with rates refreshed automatically.
• Home Screen and Lock Screen widgets.
• PDF report and CSV export.
• Face ID lock and optional iCloud sync.
• Shortcuts and Siri to check your spending by voice.
• English and Portuguese.

SubCheck Pro
One single payment unlocks every feature for good — no subscription, no renewal.

Start free: you get 7 days to try everything.
```

**What's New (4000)**
```
First release of SubCheck.
```

---

## 2. URLs e informações obrigatórias

Estes campos são preenchidos no App Store Connect. Para aparecerem dentro do
app (Ajustes › Sobre), coloque também em [AppLinks.swift](file:///Users/viniciusmicarelli/development/mobile/SubCheck/SubCheck/Services/AppLinks.swift).

| Campo | Valor |
|---|---|
| URL de suporte (obrigatória) | `https://viniciusmicarelli.github.io/sub-check/support.html` |
| URL da política de privacidade (obrigatória) | `https://viniciusmicarelli.github.io/sub-check/privacy.html` |
| URL de marketing (opcional) | `https://viniciusmicarelli.github.io/sub-check/` |
| Copyright | `2026 Vinicius Micarelli` |
| Contato para revisão | `viniciusmicarelli@hotmail.com` |

As páginas já existem na pasta `docs/` deste repositório e estão ligadas em
[AppLinks.swift](file:///Users/viniciusmicarelli/development/mobile/SubCheck/SubCheck/Services/AppLinks.swift).
Basta publicar a pasta: **Settings › Pages › Deploy from a branch › `main` / `/docs`**.

### Privacidade (App Privacy)
- **Dados coletados:** nenhum (sem analytics e sem rastreamento).
- O app consulta `api.frankfurter.app` para cotações (sem dados do usuário) e
  baixa imagens de ícones que o próprio usuário informa.
- Dados de assinaturas ficam no aparelho; com iCloud ligado, vão para a base
  privada do próprio usuário (CloudKit).
- Manter `PrivacyInfo.xcprivacy` nos dois alvos (já incluído).

---

## 3. Compra dentro do app (SubCheck Pro)

- **Tipo:** Não consumível (pagamento único).
- **ID do produto:** `com.viniciusmicarelli.subcheck.pro.lifetime`
- **Nome de exibição (pt-BR):** `SubCheck Pro`
- **Descrição (pt-BR):** `Libera todos os recursos para sempre, com um único pagamento.`
- **Nome de exibição (en):** `SubCheck Pro`
- **Descrição (en):** `Unlocks every feature for good with a single payment.`
- **Preço:** definir no App Store Connect (o arquivo local usa R$ 49,90).
- **Screenshot de revisão:** captura do paywall (tela "SubCheck Pro").

O paywall mostra preço, descrição, botão de **Restaurar compra** e o texto de
pagamento único — exigências comuns da revisão já estão atendidas.

---

## 4. Testes gratuitos locais (explicar na revisão)

O app oferece **7 dias de teste** contados a partir da instalação (data guardada
no Keychain, que sobrevive à reinstalação). Não é uma assinatura com teste
gratuito — é a liberação temporária das funções Pro, e não há cobrança
automática. Depois do período, tudo continua funcionando com o limite grátis
(5 assinaturas e sem os recursos Pro), e a compra única libera o resto.

**Nota para a revisão da Apple:**
> O SubCheck Pro é uma compra única (não consumível). Novos usuários recebem 7
> dias com todos os recursos liberados, contados a partir da instalação — não é
> uma assinatura e não há cobrança automática. Não é necessário login. Para
> testar o paywall: Ajustes › SubCheck Pro › Ver opções.

---

## 5. Checklist antes de enviar

- [ ] Criar o App ID com App Groups, iCloud/CloudKit, Push e In-App Purchase.
- [ ] Criar o app no App Store Connect com o bundle `com.viniciusmicarelli.subcheck`.
- [ ] Criar o IAP não consumível `com.viniciusmicarelli.subcheck.pro.lifetime` e anexá-lo à versão.
- [ ] Completar "Acordos, impostos e bancário" (contrato de Apps pagos).
- [ ] Publicar a pasta `docs/` no GitHub Pages (Settings › Pages › `main` / `/docs`) e usar as URLs no App Store Connect.
- [ ] Deploy do schema do CloudKit para produção (CloudKit Dashboard), se o iCloud for publicado.
- [ ] Screenshots: iPhone 6.9" (obrigatório). O 1.0 é só para iPhone (`TARGETED_DEVICE_FAMILY: "1"`).
- [ ] `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` corretos em `project.yml` + `xcodegen generate`.
- [ ] Archive (Release) › Distribute › App Store Connect › Upload.
- [ ] TestFlight interno → externo; testar compra em Sandbox, restaurar compra, widgets e Ilha Dinâmica.
- [ ] Enviar para revisão.

Detalhes técnicos de iCloud, Ilha Dinâmica e arquivamento: ver [PUBLISHING.md](file:///Users/viniciusmicarelli/development/mobile/SubCheck/PUBLISHING.md).
