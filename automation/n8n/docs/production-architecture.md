# Arquitetura de Producao

Este documento descreve a arquitetura atual dos workflows de producao do `n8n` para o CRM, com foco no agente de vendas via WhatsApp.

## Componentes principais

- `whatsapp-sales-agent`: ponto de entrada do atendimento automatizado
- `firestore-mcp-server`: camada MCP que expoe ferramentas para o agente
- subworkflows de `customer`, `catalog`, `cart`, `channel` e `handoff`: operacoes de negocio reutilizaveis

## Fluxo de alto nivel

1. O WhatsApp envia um evento para o webhook `whatsapp-incoming`.
2. O workflow principal filtra mensagens invalidas, grupos, status e mensagens do proprio sistema.
3. O fluxo identifica ou cria o cliente no Firestore do tenant.
4. O atendimento aplica controle de fila, espera e consolidacao de mensagens para evitar respostas sobrepostas.
5. O agente de IA recebe contexto da loja, do cliente e instrucoes comerciais.
6. Quando precisa consultar ou alterar dados, o agente usa o MCP `mcp-firestore`.
7. O MCP direciona a chamada para um subworkflow especializado.
8. O workflow principal envia resposta em texto ou audio e atualiza status no canal.
9. Se necessario, o atendimento e escalado para humano e o cliente fica marcado com `agent_off`.

## Responsabilidades por camada

### Entrypoint

O workflow [whatsapp-sales-agent.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/entrypoints/whatsapp-sales-agent.json) concentra:

- recepcao do webhook
- higiene e filtragem da mensagem
- identificacao e cadastro inicial do cliente
- controle de fila de mensagens e janela de espera
- transcricao de audio e geracao de TTS
- chamada do agente de IA
- entrega da resposta pelo canal WhatsApp

### MCP

O workflow [firestore-mcp-server.json](/Users/heliojunior/Projetos/saas_manu/automation/n8n/workflows/production/mcp/firestore-mcp-server.json) funciona como camada de ferramentas para o agente. Ele expoe funcoes de negocio com nomes curtos e previsiveis:

- `Atualizar_Cliente`
- `Buscar_Produtos`
- `Carrinho_Operar`
- `Carrinho_View`
- `Escalar_Humano`

Essa camada ajuda a separar a conversa da logica de dados.

### Subworkflows

Os subworkflows encapsulam operacoes de negocio:

- `customer`: atualizacao de cadastro
- `catalog`: busca e ranqueamento de produtos
- `cart`: leitura e escrita do carrinho
- `channel`: atualizacao de status no WhatsApp
- `handoff`: escalonamento para time humano

## Dependencias externas identificadas

- Firestore REST API para leitura e escrita de dados do tenant
- Evolution API para envio de mensagens e atualizacao de status no WhatsApp
- OpenAI para chat, transcricao de audio e TTS
- Postgres para fila e consolidacao de mensagens
- endpoint publico de MCP em `mcp-firestore`

## Regras de negocio explicitas no agente

O prompt do agente implementa algumas politicas importantes:

- buscar produto real antes de responder disponibilidade ou preco
- nunca inventar estoque, frete, prazo ou dados internos
- operar carrinho apenas com pedido explicito do cliente
- atualizar cadastro enviando todos os campos conhecidos
- escalar para humano quando houver pedido do cliente ou falha recorrente da IA

## Pontos de atencao

- o workflow principal foi exportado sem `id`; o repositorio preserva o conteudo e adiciona apenas `name`
- o subworkflow de escalacao ainda referencia `ESCALAR_HUMANO_ID`, o que sugere placeholder
- parte do comportamento operacional depende de endpoints externos e credenciais do ambiente do `n8n`
