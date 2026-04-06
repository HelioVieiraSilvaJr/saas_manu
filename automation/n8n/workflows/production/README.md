# Production Workflows

Esta pasta representa a arquitetura atual dos workflows de producao do projeto.

## Estrutura

```text
production/
├── entrypoints/
│   └── whatsapp-sales-agent.json
├── mcp/
│   └── firestore-mcp-server.json
└── subworkflows/
    ├── cart/
    │   ├── cart-operate.json
    │   ├── register-sale.json
    │   └── cart-view.json
    ├── catalog/
    │   ├── register-stock-alert.json
    │   └── search-products.json
    ├── channel/
    │   └── update-whatsapp-status.json
    ├── customer/
    │   └── update-customer.json
    └── handoff/
        └── escalate-human.json
```

## Mapa rapido

- `entrypoints/whatsapp-sales-agent.json`: workflow principal de atendimento e vendas via WhatsApp
- `mcp/firestore-mcp-server.json`: servidor MCP exposto em `mcp-firestore` para ferramentas do agente
- `subworkflows/customer/update-customer.json`: atualizacao de cadastro do cliente
- `subworkflows/catalog/search-products.json`: consulta de produtos no Firestore
- `subworkflows/catalog/register-stock-alert.json`: registra interesse em reposicao para produto sem estoque
- `subworkflows/cart/cart-operate.json`: operacoes de carrinho
- `subworkflows/cart/cart-view.json`: leitura e resumo do carrinho
- `subworkflows/cart/register-sale.json`: registra a venda fechada a partir do carrinho atual
- `subworkflows/channel/update-whatsapp-status.json`: atualizacao de status no canal
- `subworkflows/handoff/escalate-human.json`: escalonamento para atendimento humano

## IDs atuais

- `MCP Firestore`: `Zg8e0FW3Mq6awJx5`
- `Sub - Atualizar Cliente`: `QZuTflMvrNdNMmiB`
- `Sub - Buscar Produtos`: `SIXIOZ0NM0w1Kp1s`
- `Sub - Carrinho Operar`: `W9oVFsD5vGMJrnS9`
- `Sub - Carrinho View`: `gxZhfi6ne4nkSITs`
- `Sub - Registrar Venda`: `Rpx4VA5kvlMPk7kd`
- `Sub - Registrar Aviso de Estoque`: `47qiiS7zFoTZd3qm`
- `Sub - Escalar Humano`: `QvblWeXM9HTYVXDk`

## Endpoints identificados

- webhook principal: `whatsapp-incoming`
- servidor MCP: `mcp-firestore`

## Ordem recomendada de importacao

1. Importar os arquivos de `subworkflows/`.
2. Confirmar ou atualizar os IDs dos subworkflows no `n8n`.
3. Importar `mcp/firestore-mcp-server.json` e validar referencias de `toolWorkflow`.
4. Importar `entrypoints/whatsapp-sales-agent.json`.
5. Testar webhook, MCP e credenciais antes de publicar.

## Observacoes

- O arquivo `entrypoints/whatsapp-sales-agent.json` veio sem `name` e sem `id` no export original; o `name` foi preenchido no repositorio para facilitar manutencao.
- O workflow `Sub - Registrar Venda` depende da `webhook_url` oficial do tenant para usar o endpoint `receiveN8nSale` com validacao server-side.
- A whitelist de remetentes de teste do workflow principal agora e aplicada apenas para tenants listados em `test_sender_whitelist_tenant_ids`. Se o `tenant_id` atual nao estiver nessa lista, o fluxo ignora a whitelist e segue normalmente.
