# SubCheck — roteiro de teste no iPhone (≈ 30 min)

Rode isto num **iPhone real**, com uma build de TestFlight (ou do Xcode) antes de enviar para a revisão. O simulador já foi coberto pelos 69 testes automáticos; aqui estão só as coisas que ele não consegue provar. Marque `[x]` e anote o que estranhar.

> Dica: para testar o teste grátis, use **Ajustes > Geral > Data e Hora** e avance o relógio. O app foi feito para não reabrir o teste se você voltar a data.

## 1. Instalação limpa (3 min)
- [ ] Apague o app, instale de novo: abre a **introdução** (7 páginas), sem dados de exemplo.
- [ ] Trocar idioma e tema na primeira página muda o texto na hora, sem voltar ao início.
- [ ] A permissão de notificação **só** aparece depois da introdução.
- [ ] A página do teste grátis mostra "7 dias grátis", "sem cartão". Termina em "Começar".

## 2. Cadastro e painel (3 min)
- [ ] Adicionar uma assinatura (nome, valor, categoria) → aparece no painel e em Assinaturas.
- [ ] Adicionar em **dólar**; abrir a assinatura > **Histórico e cotação** abre sem travar.
- [ ] Marcar como paga, editar o valor, cancelar e excluir funcionam.
- [ ] No limite grátis (5 ativas) a 6ª pede o Pro (depois do teste).

## 3. Importar do extrato (4 min)
- [ ] Exporte o **CSV real** do seu banco/cartão (3 meses ou mais) e importe em Assinaturas > ⬇︎.
- [ ] As assinaturas conhecidas aparecem; as canceladas vêm desmarcadas.
- [ ] Se **não** reconhecer o formato, anote as colunas (sem dados pessoais) para eu ajustar o leitor.

## 4. Teste grátis e Pro (5 min)
- [ ] Ajustes > SubCheck Pro mostra os dias restantes.
- [ ] Avance o relógio **8 dias**: recursos Pro travam; o app continua grátis.
- [ ] Volte o relógio: o Pro **não** destrava de novo.
- [ ] Compra com **Sandbox tester**: libera o Pro. **Restaurar compra** funciona em outro aparelho.
- [ ] iCloud ligado durante o teste e teste expirado: aparece "Sincronização pausada".

## 5. Ilha Dinâmica e widgets (4 min)
*(iPhone 14 Pro ou mais novo.)*
- [ ] Ajustes > Testar Ilha Dinâmica; volte à tela inicial: aparece a ilha compacta.
- [ ] Toque e segure: expande com contagem e botão **Registrar pagamento**; o botão funciona.
- [ ] Bloqueie a tela: a Live Activity aparece na tela de bloqueio.
- [ ] Adicione os 3 widgets à tela inicial; mudam quando você paga algo.
- [ ] Deixe 5+ horas sem abrir o app e abra de novo: a ilha **volta** sozinha.

## 6. Notificações e Siri (4 min)
- [ ] Crie uma assinatura que vença em 2 dias com lembrete: chega a notificação.
- [ ] Segure a notificação: **Marcar como pago** e **Lembrar amanhã** funcionam.
- [ ] "Ei Siri, qual a próxima cobrança no SubCheck".
- [ ] "Ei Siri, registrar pagamento de [nome] no SubCheck" registra e responde.
- [ ] "Ei Siri, adicionar assinatura no SubCheck" pergunta nome e valor.
- [ ] Ajustes > Siri e Atalhos abre o tutorial e o botão abre o app Atalhos.

## 6b. Contas do mês (5 min)
- [ ] Aba **Contas**: toque em "Informar salário", digite o líquido (já com descontos) e salve: o cartão mostra "Sobra do mês".
- [ ] Cadastre **Conta de água** (vence hoje, varia todo mês) e **Aluguel** (valor fixo). O aluguel já vem com o valor.
- [ ] Na água, toque em "Informar valor", digite e salve: vai para "Pagas este mês" e a sobra diminui.
- [ ] Mês anterior sem histórico não quebra nada; depois de 2+ meses aparece "x% acima da média".
- [ ] Crie uma conta que vença **amanhã** com lembrete "1 dia antes": chega a notificação às 9h; **tocar nela abre a tela de valor** dessa conta.
- [ ] "Pular este mês" e "Desmarcar pagamento" (segurar a linha) funcionam.
- [ ] A 6ª conta ativa pede o Pro (depois do teste).
- [ ] O cartão **Seu mês** aparece no Resumo e leva à aba Contas.
- [ ] Histórico de assinaturas excluídas agora está em Ajustes > Dados.

## 6c. Aviso de conta, meses e calendário (6 min)
- [ ] Cadastre uma conta que vence **amanhã** (lembrete "1 dia antes", depois das 9h): ao fim do dia nada chega, mas **amanhã às 9h** chega "Conta vence hoje" e, à noite (19h), "Falta informar o valor" se ainda não digitou.
- [ ] Segure a notificação: **Informar valor** abre o app na conta; **Lembrar em 3 h** reaparece; em conta de valor fixo existe **Marcar como paga**.
- [ ] Cadastre uma conta que vence **hoje**: o app já abre a tela do valor.
- [ ] Abra o app com uma conta vencida: aparece **"Contas para informar"** (Preencher agora / Depois). "Depois" só volta amanhã.
- [ ] Com o Pro ativo e uma conta vencendo hoje, a **Ilha Dinâmica** mostra a conta com "Informar valor" (abre a tela da conta).
- [ ] Setas do cartão passam de mês: meses passados mostram o que foi pago; futuros mostram **Previstas** com "~valor".
- [ ] **Calendário**: pontinhos por situação; tocar num dia lista contas, assinaturas e o salário.
- [ ] **Evolução**: barras por categoria, "contra o mês anterior" e "O que mudou".

## 6d. Pro só quando a pessoa escolhe (3 min)
- [ ] Instalação limpa: na introdução aparecem **"Ativar 7 dias grátis"** e **"Continuar no grátis"**; escolhendo grátis, recursos Pro ficam travados.
- [ ] No Resumo aparece o card **"Experimente o Pro por 7 dias"**; "Ativar" libera tudo na hora.
- [ ] Ajustes > SubCheck Pro e o paywall mostram **"Testar 7 dias grátis"** enquanto o teste não foi ativado.
- [ ] Depois de 7 dias (avance o relógio) o card vira "Seu teste do Pro terminou".

## 7. iCloud (4 min) — precisa de **dois** aparelhos no mesmo Apple ID
- [ ] Ligue "Sincronizar com iCloud" nos dois e **reabra** o app.
- [ ] Uma assinatura criada no aparelho A aparece no B em alguns minutos.
- [ ] Anote se o que foi criado **antes** de ligar o iCloud também sobe.

## 8. Acessibilidade e aparência (3 min)
- [ ] **VoiceOver** (triplo clique no lateral): navegue pelo painel; cada cartão e linha é lido como uma frase ("Netflix, R$ 55,90, mensal, cobra em 3 dias").
- [ ] Ajustes > Acessibilidade > Tamanho do texto > o maior: nada fica cortado no painel e nas assinaturas.
- [ ] **Reduzir movimento** ligado: o app segue usável.
- [ ] Modo escuro e claro, em português e em inglês.

## O que anotar
Para cada item que falhar: o que você esperava, o que aconteceu e, se der, uma captura de tela. Erros de "não foi possível salvar" também importam.

## 6e. Siri para contas e telas largas
- Siri/Atalhos: "Registrar conta de luz no SubCheck" → pergunta o valor → grava na linha em aberto (a vencida mais antiga, senão a do mês). "Contas para pagar no SubCheck" lista as vencidas/de hoje.
- iPad / dobrável aberto / janela dividida: conteúdo em coluna centralizada (720 pt), abas no topo; girar o aparelho e redimensionar o Split View sem cortes.
- Pendente: validar em um dobrável real; para a App Store, o iPad exige capturas próprias.

## 6f. v1.1 (build 3) — rodar no iPhone real
- **Campo de dinheiro:** salário, orçamento, conta, assinatura e pagamento avulso mostram a máscara (digitar 1-2-3-4-5 → 123,45); o botão "OK" fecha o teclado.
- **Ilha/Atividade ao Vivo:** só com Pro; aparece só se algo vence em até 3 dias; some em 1 minuto; respeita "Avisos por dia" (Ajustes). Em iPhone **sem** Ilha o texto diz "Atividade ao Vivo". Botão "Registrar pagamento" mostra "Pago ✓" e segue para a próxima.
- **Ícones:** logo da marca na tela de bloqueio e na Ilha; texto da legenda ("Próxima cobrança") correto.
- **Pro:** comprar (Sandbox) cria a despesa "SubCheck Pro" de R$ 49,90 (uma vez). Preço também precisa estar em R$ 49,90 no App Store Connect.
- **Pagamentos avulsos:** registrar em USD sem internet (modo avião) com cotação digitada e com valor aproximado.
- **Assinatura:** descrição, "Pessoas dividindo" (preço cheio × sua parte), pacote (Apple One → iCloud+: não soma em dobro), tipo "Por uso" (pede o valor ao registrar).
- **Resumo:** alternância Hoje × Futuro com teste grátis em curso; rosquinha de categorias responde ao toque.
- **Contas:** no dia do salário aparece "Marcar todas como pagas" (e fora dele, para vencidas).
- **Simulador (Pro):** arrastar o gráfico, horizonte 1–10 anos, inflação e rendimento.
- **Onboarding:** passo "Do seu jeito" (idioma e aparência mudam na hora).
- **Siri/Atalhos:** "Registrar conta de luz no SubCheck", "Quais contas vencem"; dicas prontas na tela de Siri e Atalhos.
- **Landing no iPhone (Safari):** cabeçalho cabe, tour fixo cabe na tela, cartões novos.
