# Catalogo de Workflows

Este catalogo traduz os workflows atuais para uma leitura funcional e operacional.

## Entrypoint principal

### `whatsapp-sales-agent`

Arquivo: [whatsapp-sales-agent.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/entrypoints/whatsapp-sales-agent.json)

Papel:
- atender mensagens recebidas no WhatsApp
- qualificar a interacao
- consultar dados do cliente
- acionar o agente de vendas
- responder em texto ou audio

Entrada:
- webhook `POST /whatsapp-incoming`

Capacidades observadas:
- ignora mensagens de grupo, status e mensagens enviadas pelo proprio bot
- permite texto e audio
- cria cliente quando ainda nao existe
- controla mensagens encavaladas usando Postgres e `wait`
- usa MCP para consultar e alterar dados do CRM

Dependencias:
- Firestore
- Evolution API
- OpenAI
- Postgres
- MCP `mcp-firestore`

## Servidor MCP

### `firestore-mcp-server`

Arquivo: [firestore-mcp-server.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/mcp/firestore-mcp-server.json)

Papel:
- expor ferramentas consumiveis pelo agente de IA
- mapear chamadas do agente para subworkflows com IDs internos do `n8n`

Entrada:
- MCP trigger em `mcp-firestore`

Tools expostas:
- `Atualizar_Cliente`
- `Buscar_Produtos`
- `Carrinho_Operar`
- `Carrinho_View`
- `Escalar_Humano`

## Subworkflows

### `update-customer`

Arquivo: [update-customer.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/customer/update-customer.json)

Papel:
- atualizar dados cadastrais do cliente no tenant

Entradas:
- `tenant_id`
- `document_id`
- `name`
- `phone`
- `email`
- `address`

Efeitos:
- executa `PATCH` no documento `customers/{document_id}`
- atualiza `name`, `phone`, `email`, `address` e `updated_at`

Retorno esperado:
- `success`
- `document_id`
- campos atualizados do cliente

### `search-products`

Arquivo: [search-products.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/catalog/search-products.json)

Papel:
- consultar catalogo do tenant e ranquear resultados por relevancia

Entradas:
- `tenant_id`
- `search_term`

Efeitos:
- consulta produtos no Firestore
- filtra inativos
- aplica match por nome, descricao, categoria, tags, cor e tamanho

Retorno esperado:
- `found`
- `exact_matches`
- `alternative_colors`
- `alternative_sizes`
- `out_of_stock`
- `message` quando nada util e encontrado

Observacao:
- o algoritmo foi desenhado para dar contexto suficiente para o agente sugerir alternativas sem inventar disponibilidade

### `cart-operate`

Arquivo: [cart-operate.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/cart/cart-operate.json)

Papel:
- operar o carrinho de compras do cliente

Entradas:
- `tenant_id`
- `phone`
- `action`
- `customer_name`
- `customer_id`
- `sku`
- `product_name`
- `price`
- `quantity`

Acoes suportadas:
- `add`
- `remove`
- `update_qty`
- `clear`

Efeitos:
- consulta carrinho existente
- cria, atualiza ou remove carrinho no Firestore
- recalcula total e quantidade de itens

Retorno esperado:
- `success`
- `items`
- `total`
- `item_count`
- `message`

### `cart-view`

Arquivo: [cart-view.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/cart/cart-view.json)

Papel:
- consultar o carrinho sem alterar seu estado

Entradas:
- `tenant_id`
- `phone`
- `customer_name`
- `customer_id`

Retorno esperado:
- `success`
- `empty`
- `items`
- `total`
- `item_count`
- `message` quando carrinho estiver vazio

### `update-whatsapp-status`

Arquivo: [update-whatsapp-status.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/channel/update-whatsapp-status.json)

Papel:
- atualizar status assincro nos eventos do canal WhatsApp

Entrada:
- webhook `POST /e56e25c6-d00e-40aa-83b6-4985aea910f1`

Observacao:
- o workflow principal dispara esse endpoint para sinalizacao operacional, possivelmente digitando ou gravando

### `escalate-human`

Arquivo: [escalate-human.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/handoff/escalate-human.json)

Papel:
- retirar o agente automatico da conversa e criar uma escalacao para o time humano

Entradas:
- `tenant_id`
- `phone`
- `customer_name`
- `customer_id`
- `reason`
- `summary`

Efeitos:
- marca `agent_off` no cliente
- grava documento de escalacao no Firestore

Retorno esperado:
- `success`
- `message`
- `escalation_id`
- `customer_name`
- `reason`

Ponto de atencao:
- o ID atual do workflow aparece como `ESCALAR_HUMANO_ID`, sugerindo que a referencia final ainda precisa ser confirmada
