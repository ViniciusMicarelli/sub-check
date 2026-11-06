# SubCheck — Plano de ação v1.1

> **Status (build 3):** Fases 0, 1, 2 e 3 implementadas; Fase 4 na opção A (ilha curta com o app aberto) e atalhos prontos por dica da Siri. Pendente: preço R$ 49,90 no App Store Connect, validação em aparelho real, link de atalho do iCloud (precisa ser criado no app Atalhos) e servidor de push (opção B).

Norte do produto: **controle financeiro completo, mas com as assinaturas como diferencial.**
Cada item abaixo precisa responder "isso ajuda a entender o que as assinaturas custam, hoje e no futuro?".

Legenda: 🔴 quebra algo hoje · 🟠 muda o produto · 🟡 polimento · ⚠️ limite técnico do iOS (ver "Decisões").

---

## Fase 0 — Consertar o que está quebrado (build 3)

| # | Item | Causa provável / abordagem | Pronto quando |
|---|------|----------------------------|---------------|
| 0.1 🔴 | **Botão "Registrar pagamento" da Live Activity não funciona / não mostra ação** | `Button(intent:)` roda na extensão; ela não vê o Keychain do app (o portão Pro novo lê uma flag compartilhada, então precisa estar gravada) e o banco pode estar em outro contexto. Investigar no aparelho com o log do Console. Dar **retorno visual**: estado "Pago ✓" por alguns segundos antes de trocar para a próxima cobrança. | Tocar paga a assinatura, a ilha mostra "Pago ✓" e atualiza |
| 0.2 🔴 | **Animação do teste de 7 dias bugada no iPhone 15 (landing)** + outras cenas | Reproduzir em **WebKit** com viewport 393×852 (Playwright `webkit`, Safari iOS). Suspeitas: `cqw`/container queries, `svh/dvh`, `position: sticky` + pin do ScrollTrigger com a barra do Safari, `will-change`/blur. Passar **todas as 10 cenas** em WebKit mobile, não só a do Pro. | Sem corte/pulo em WebKit mobile nas 10 cenas (capturas) |
| 0.3 🔴 | **Teclado do orçamento não fecha + sem máscara** | Criar **um único `CurrencyField`** (centavos inteiros, 2 casas, máscara pt-BR/en, botão "OK" na barra do teclado, `.scrollDismissesKeyboard`). Usar em orçamento, salário, contas, nova assinatura, pagamento avulso. | Digita 1-2-3-4-5 → R$ 123,45; teclado fecha |
| 0.4 🔴 | **Ilha Dinâmica: detectar o aparelho** e não prometer onde não existe | Não há API pública "tem ilha?". Usar `safeAreaInsets.top ≥ 51` na janela (ilha ≈ 59–62 pt; notch ≈ 47–50) com lista de modelos como reforço. Sem ilha: textos falam só de "tela de bloqueio"; sem Live Activities: esconder o recurso. App **nunca** depende de `Activity` para abrir. | iPhone SE/11/13: nenhuma menção à ilha; nada quebra com atividades desligadas |
| 0.5 🟠 | **Pro: R$ 39,90 → R$ 49,90 e registrar como despesa** | (a) **Você** muda o preço no App Store Connect (tier ≈ R$ 49,90). (b) No app: atualizar `Config/SubCheck.storekit`, textos, FAQ, landing, `APPSTORE_LISTING.md`. (c) Na compra confirmada, criar um **pagamento avulso** com o valor **real da transação** (`transaction.price` + moeda), categoria "Assinaturas/Software". Idempotente (uma vez por `transaction.id`). | Comprar → aparece "SubCheck Pro" nas despesas do mês |

## Fase 1 — Modelo de dados v2 (uma migração só)

Tudo o que muda o banco entra **junto**, para fazer **uma** publicação do esquema CloudKit. Todos os campos novos têm valor padrão (migração leve).

**`Subscription` ganha:**
- `notes: String` — descrição (e-mail da conta, o que compõe, etc.).
- `billingKind` — `fixed` | `variable` (por uso; muda todo mês). Variável guarda histórico mensal e usa média/último valor como previsão.
- `sharedPeople: Int` (1 = só eu) → mostra **preço cheio + minha parte**.
- `bundleParentID: UUID?` — liga serviços a um pacote (Apple One → iCloud+, Music, Arcade, TV+). O filho vira "incluído": **não soma duas vezes**; aparece dentro do pai.
- `manualRate: Double?` e `rateIsManual: Bool` — cotação digitada.

**Novo `OneOffPayment`:** nome, valor, moeda, `amountBRL` aproximado, data, nota, `manualRate`, categoria. Ex.: "Trae, US$ 8, uma vez".

**Regras novas (puras e testadas):**
- **Hoje vs. Futuro:** o total "comprometido" separa *cobrança real hoje* de *trial/teste que vira cobrança depois*. Visão "Futuro" soma os trials quando acabarem (data de virada). Resolve "tenho coisa no free trial, mas meu custo futuro é outro".
- **Cotação:** usa a do dia quando há internet; **sem internet usa a última em cache**; a pessoa pode **digitar a cotação** ou **informar o valor aproximado já em reais**. Nunca bloqueia nem quebra.
- **Compartilhado:** `minhaParte = preçoCheio / pessoas`; os totais usam a minha parte (opção de ver o cheio).

## Fase 2 — Telas das funções novas

1. **Detalhe da assinatura:** campo de descrição, "Compartilhado com N pessoas", "Faz parte de…", "Inclui…".
2. **Assinatura por uso:** lançar o valor do mês (mesmo fluxo de conta variável); gráfico mês a mês.
3. **Pagamentos avulsos:** lista + botão "Registrar pagamento"; aparecem no Resumo e no calendário.
4. **Resumo com alternância Hoje | Futuro.**
5. **Contas: "Marcar todas como pagas" no dia do salário.** No dia do salário, ao abrir o app (e na aba Contas), oferecer "Marcar N pendentes como pagas" com confirmação e **desfazer**.
6. **Gráfico por categoria:** tocar na **rosquinha** seleciona a fatia (`chartAngleSelection`), sincronizado com a lista.

## Fase 3 — Simulação, onboarding e ícones

1. **Simulador de cancelamento em gráficos:** horizonte arrastável de **1 a 10 anos**, linha "sem cancelar" × "cancelando", **inflação** configurável (padrão IPCA ≈ valor editável), opção de rendimento do dinheiro economizado. Swift Charts com *scrubbing* (arrastar e ler o valor).
2. **Onboarding redesenhado:** escolha de **idioma** e **cor** em cartões visuais com prévia ao vivo (não listas); menos passos, uma ideia por tela. *Preciso de uma referência do que não agrada.*
3. **Mais ícones de marca:** Apple Developer, Apple One, Apple Music/TV+/Arcade/Fitness+, **IA** (ChatGPT, Claude, Gemini, Perplexity, Copilot, Grok, Cursor, Trae, Midjourney, Suno, ElevenLabs…), Dazz Cam, CapCut, Canva, Notion, Figma, Duolingo, etc. Pesquisar os mais usados no Brasil e nos EUA. Fonte: *Simple Icons* (CC0) quando existir; marca sem logo livre → letra/monograma na cor da marca. Lista final em `BrandIconCatalog`, com teste de que todo ícone tem asset.

## Fase 4 — Notificações da ilha e atalhos (⚠️ ver Decisões)

1. **Configuração da ilha:** quantas vezes por dia (0–5), janela de horário, e **duração máxima de 1 minuto**.
2. **Pré-atalhos com um toque:** tela "Automações sugeridas" (ex.: "avisar quando a conta vencer", "registrar pagamento ao chegar em casa"), cada uma com `SiriTipView`/`ShortcutsLink` e **link de atalho do iCloud** para instalar.

---

## Decisões que preciso de você (⚠️ limites do iOS)

1. **Ilha "no máximo 1 minuto, N vezes por dia":** o iOS **não deixa o app abrir uma Live Activity sozinho em segundo plano** sem um **servidor de push (APNs)**. Sem servidor, ela só começa com o app aberto, e o encerramento em 60 s só é garantido com o app em primeiro plano. Opções:
   - **A (recomendada agora):** ilha curta quando você abre o app ou toca na notificação; a frequência vira "quantos avisos por dia pelo app". Sem custo.
   - **B (completa):** pequeno servidor que envia push de início/fim no horário certo (iOS 17.2+). Dá exatamente o que você descreveu, mas exige servidor e token de push.
2. **Atalhos "criados automaticamente":** o iOS **não permite que o app crie automações** no app Atalhos. Dá para oferecer **atalhos prontos** (link do iCloud, um toque para adicionar) e as ações do app já aparecem sozinhas. **Automações pessoais** (por horário/local) o usuário confirma na hora. Serve assim?
3. **Compartilhado:** os totais do app devem contar **só a minha parte** (sugestão) ou o preço cheio por padrão?
4. **Preço Pro:** confirmo **R$ 49,90** em tudo; você ajusta o preço no App Store Connect.

## Ordem sugerida

`0.3 → 0.4 → 0.1 → 0.2 → 0.5` (build 3) · `Fase 1` (build 4) · `Fase 2` · `Fase 3` · `Fase 4`.
Cada fase: branch `feature/*` → `develop` → `release/1.0` → `main`, com testes e atualização do `TESTPLAN.md` e da landing.

## Lembretes de publicação

- Esquema do CloudKit em **produção** deve incluir `Bill`, `BillEntry`, `OneOffPayment` e os campos novos de `Subscription` **antes** de lançar na App Store.
- Cada upload do TestFlight precisa de número de build maior que o anterior (hoje: 2).
