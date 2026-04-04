# Firebase Functions

Esta pasta concentra o backend server-side da plataforma.

## Funcoes atuais

- `createTenantWithAdmin`: cria tenant e vincula o primeiro admin sem trocar a sessao do operador
- `provisionTenantMember`: provisiona membros do tenant no backend
- `receiveN8nSale`: endpoint oficial para receber vendas automatizadas do `n8n`
- `createPixCheckout`: cria checkout de pagamento e delega a geracao real ao orquestrador configurado
- `paymentWebhook`: endpoint interno para atualizar status de pagamentos
- `syncMembershipAccessIndex`: migra memberships antigos para IDs deterministas
- `testEvolutionConnection`: testa a Evolution API no backend, evitando CORS e exposicao direta no navegador

## Por que isso existe

Esta camada reduz tres riscos importantes:

- criacao de usuarios no client usando Firebase Auth
- dependencias criticas sem validacao server-side
- regras multi-tenant fracas por falta de um indice de memberships previsivel

## Variaveis esperadas

As funcoes aceitam operar com configuracao minima, mas para fluxo completo de billing voce deve configurar:

- `DEFAULT_INVITE_PASSWORD`
- `PAYMENT_ORCHESTRATOR_URL`
- `PAYMENT_ORCHESTRATOR_SECRET`
- `PAYMENT_WEBHOOK_SECRET`
- `EVOLUTION_API_URL`
- `EVOLUTION_API_KEY`

Se `DEFAULT_INVITE_PASSWORD` nao for informado, as funcoes passam a gerar uma senha temporaria aleatoria por usuario.

Para a integracao gerenciada do WhatsApp via Evolution API, prefira cadastrar `EVOLUTION_API_URL` e `EVOLUTION_API_KEY` no Secret Manager e vincular esses secrets as functions que provisionam instancia, consultam status e enviam notificacoes de reposicao.

## Deploy sugerido

1. Instalar dependencias em `functions/`.
2. Fazer deploy das functions.
3. Executar `syncMembershipAccessIndex` uma vez com um usuario `superAdmin`.
4. Publicar `firestore.rules` e `storage.rules`.
5. Validar criacao de tenant, convite de membro, webhook do `n8n` e fluxo de pagamento.

## Arquivo de exemplo

Use `functions/.env.example` como base para configurar as variaveis locais e do ambiente de deploy.

## Observacao importante

As regras novas assumem memberships com ID determinista no formato:

```text
{tenant_id}_{user_id}
```

Se o ambiente atual possui memberships legados com ID aleatorio, execute a migracao antes de endurecer as regras em producao.
