# Pontos de Integracao

Este documento resume as integracoes externas e colecoes impactadas pelos workflows atuais.

## Endpoints expostos

- `POST /whatsapp-incoming`: entrada principal de mensagens do WhatsApp
- `POST /mcp-firestore`: servidor MCP para ferramentas do agente
- `POST /e56e25c6-d00e-40aa-83b6-4985aea910f1`: webhook operacional de atualizacao de status no canal

## Servicos externos

### Firestore REST API

Uso identificado:
- consulta de clientes
- criacao de clientes
- atualizacao de cliente
- consulta de produtos
- leitura e persistencia de carrinho
- gravacao de escalacoes

Colecoes e caminhos observados:
- `tenants/{tenant_id}/customers`
- `tenants/{tenant_id}/products`
- `tenants/{tenant_id}/escalations`

Observacao:
- os workflows usam chamadas REST diretas para o projeto `saas-manu-project`

### Evolution API

Uso identificado:
- envio de texto
- envio de audio
- marcacao de mensagem como lida
- atualizacao de status no canal

### OpenAI

Uso identificado:
- modelo de chat para o agente de vendas
- transcricao de audio recebido
- geracao de fala para respostas em audio

### Postgres

Uso identificado:
- enfileiramento de mensagens
- leitura da fila
- limpeza apos consolidacao

Objetivo aparente:
- evitar concorrencia e respostas duplicadas quando o cliente manda varias mensagens em sequencia

## Dados de contexto essenciais

Os workflows dependem fortemente destes identificadores:

- `tenant_id`
- `customer_id`
- `phone`
- `messageId`
- `conversation_id`

## Riscos operacionais para monitorar

- referencias de workflow por ID no MCP podem quebrar apos importacao em outro ambiente
- endpoints externos hardcoded exigem revisao ao trocar dominio ou instancia do `n8n`
- placeholders como `ESCALAR_HUMANO_ID` precisam ser resolvidos antes de replicar o ambiente
- credenciais de Firestore, OpenAI, Evolution API e Postgres continuam sendo dependencia do ambiente do `n8n`
