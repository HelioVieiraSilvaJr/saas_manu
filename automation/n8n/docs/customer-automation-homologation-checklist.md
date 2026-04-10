# Checklist de Homologacao das Automacoes de Atendimento

Este roteiro cobre as tres evolucoes aprovadas da plataforma:

- notificacao de mudanca de status do pedido
- recuperacao de carrinho abandonado
- visibilidade de saude operacional no dashboard

## Objetivo

Validar comportamento real sem risco de contato indevido com clientes de producao.

## Pre-condicoes obrigatorias

- usar um `tenant` isolado para homologacao
- usar um numero de WhatsApp controlado pela equipe
- garantir que esse `tenant` nao compartilha clientes reais
- confirmar que a instancia WhatsApp do tenant de teste esta conectada
- confirmar que o tenant possui configuracao valida para envio via Evolution

## Validacoes automaticas antes da homologacao real

Executar:

```bash
cd functions
npm run test:customer-automation
cd ..
flutter test test/dashboard_tenant_repository_test.dart test/dashboard_tenant_view_model_test.dart test/dashboard_tenant_operational_views_test.dart
```

Resultado esperado:

- todos os cenarios da automacao passam
- todos os testes do dashboard passam

## Cenario 1: notificacao de mudanca de status do pedido

Preparacao:

- criar um cliente de teste com `customer_whatsapp` controlado
- criar uma venda com `source = whatsapp_automation`
- definir `status = confirmed`
- manter `last_notified_order_status` vazio

Passos:

1. atualizar `order_status` para `awaiting_processing`
2. verificar se o cliente recebeu a mensagem
3. verificar se a venda gravou `last_notified_order_status`
4. atualizar para `ready_for_pickup` ou `ready`
5. verificar nova mensagem
6. atualizar novamente para o mesmo status normalizado
7. confirmar que nao houve novo disparo

Resultado esperado:

- envia uma mensagem por mudanca relevante
- nao duplica quando o status normalizado nao muda
- registra tentativa e ultimo status notificado

Bloqueios que devem ser testados:

- `source = manual` nao deve enviar
- `status != confirmed` nao deve enviar
- cliente sem telefone nao deve enviar
- cliente com `human_handoff_pending = true` nao deve enviar
- cliente com `agent_off = true` nao deve enviar

## Cenario 2: recuperacao de carrinho abandonado

Preparacao:

- criar um carrinho `open` para o cliente de teste
- garantir `updated_at` com mais de 2 horas
- manter `recovery_status = open`
- manter `recovery_attempt_count = 0`

Passos:

1. aguardar a execucao agendada ou acionar a janela de verificacao em horario compativel
2. verificar se o cliente recebeu mensagem de retomada
3. validar se o carrinho foi marcado com:
   `recovery_status = recovery_sent`
4. validar se `recovery_attempt_count = 1`
5. validar se `last_recovery_at` foi preenchido

Resultado esperado:

- apenas um disparo por carrinho agrupado por tenant + telefone
- mensagem usa o contexto mais recente do carrinho
- o carrinho nao deve ser reenviado logo em seguida

Bloqueios que devem ser testados:

- cliente respondeu depois da ultima atualizacao do carrinho
- cliente com handoff humano ativo
- cliente com agente pausado
- tenant sem configuracao de WhatsApp

## Cenario 3: expiracao do carrinho apos tentativa ignorada

Preparacao:

- usar um carrinho com `recovery_status = recovery_sent`
- garantir `last_recovery_at` com mais de 24 horas
- garantir que nao houve resposta do cliente depois disso
- garantir que o carrinho nao foi alterado depois do envio

Passos:

1. aguardar nova execucao do scheduler
2. consultar a colecao `tenants/{tenantId}/carts`

Resultado esperado:

- o carrinho deve ser removido
- um novo contato futuro do cliente deve recomecar o fluxo sem lixo de contexto antigo

Bloqueios que devem ser testados:

- se o cliente respondeu depois da tentativa, o carrinho nao expira
- se o carrinho foi atualizado depois da tentativa, o carrinho nao expira

## Cenario 4: dashboard de saude operacional

Preparacao:

- criar dados de teste no tenant homologado para cada categoria:
  - escalacoes pendentes
  - alertas de estoque pendentes
  - vendas pendentes
  - vendas com `payment_sent`
  - carrinhos abertos com mais de 2 horas

Passos:

1. abrir o dashboard do tenant
2. verificar se os cards operacionais aparecem
3. conferir se os contadores batem com os dados criados
4. zerar uma categoria por vez
5. confirmar que o card correspondente some

Resultado esperado:

- cada card aparece apenas quando a contagem e maior que zero
- a visibilidade acompanha o estado real dos dados
- o dashboard ajuda o operador a agir sobre pendencias concretas

## Checklist de seguranca

- nunca usar telefone real de cliente
- nunca usar tenant com operacao ativa
- registrar no teste qual `tenant_id` foi usado
- registrar o horario do scheduler observado
- limpar carrinhos, vendas e clientes de teste ao final

## Evidencias minimas a guardar

- print do WhatsApp de teste com notificacao de status
- print do WhatsApp de teste com recuperacao de carrinho
- print do dashboard com cards operacionais visiveis
- IDs dos documentos de teste usados na homologacao
- horario da execucao validada

## Fechamento recomendado

Homologacao aprovada quando:

- os testes automaticos passam
- os tres cenarios reais acima passam em tenant isolado
- nao ha disparo indevido
- os contadores do dashboard refletem corretamente os dados de teste
