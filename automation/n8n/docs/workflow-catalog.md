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
- `Registrar_Aviso_Estoque`
- `Registrar_Venda`
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
- consulta candidatos no Firestore com pre-filtro por `search_tokens`
- usa fallback legado de leitura mais ampla apenas quando ainda nao ha candidatos tokenizados
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
- produtos novos e atualizados passam a gravar `search_tokens` e `search_text` no app para reduzir custo da consulta

### `register-stock-alert`

Arquivo: [register-stock-alert.json](/Users/heliojunior/projetos/saas_manu/automation/n8n/workflows/production/subworkflows/catalog/register-stock-alert.json)

Papel:
- registrar ou atualizar o interesse do cliente em um produto sem estoque

Entradas:
- `tenant_id`
- `phone`
- `customer_name`
- `customer_id`
- `product_id`
- `product_name`
- `desired_quantity`

Efeitos:
- valida se o produto existe e esta sem estoque
- evita duplicar aviso pendente para o mesmo cliente e produto
- atualiza a quantidade desejada quando o cliente ja estava aguardando

Retorno esperado:
- `success`
- `created`
- `alert_id`
- `message`

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

### `register-sale`

Arquivo: [register-sale.json](/Users/heliojunior/projetos/saas_manu/automation/n8n/workflows/production/subworkflows/cart/register-sale.json)

Papel:
- transformar o carrinho atual em uma venda registrada no CRM

Entradas:
- `webhook_url`
- `tenant_id`
- `phone`
- `customer_name`
- `customer_id`
- `customer_email`
- `customer_address`
- `notes`
- `conversation_id`
- `status`
- `decrement_stock`

Efeitos:
- lê o carrinho atual do cliente
- monta payload padronizado de venda automatizada
- envia para o endpoint `receiveN8nSale`

Retorno esperado:
- `success`
- `sale_id`
- `customer_id`
- `created`
- `message`

### `update-whatsapp-status`

Arquivo: [update-whatsapp-status.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/subworkflows/channel/update-whatsapp-status.json)

Papel:
- atualizar status assincro nos eventos do canal WhatsApp

Entrada:
- chamada interna de subworkflow com `instancia`, `telefone`, `status`, `delay`, `apikey` e `server_url`

Observacao:
- o workflow principal dispara esse subworkflow de forma assincro para ligar o feedback antes do agente e resetar antes do envio da resposta

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
- o subworkflow `Sub - Escalar Humano` usa o ID de producao `QvblWeXM9HTYVXDk`

Pontos de atencao gerais:
- `register-sale` depende da `webhook_url` oficial do tenant estar configurada no ambiente do agente
- os subworkflows `Sub - Registrar Venda` e `Sub - Registrar Aviso de Estoque` usam os IDs de producao `Rpx4VA5kvlMPk7kd` e `47qiiS7zFoTZd3qm`
