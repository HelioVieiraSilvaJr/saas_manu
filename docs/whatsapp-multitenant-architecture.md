# WhatsApp Multi-tenant Architecture

Este documento descreve a evolucao recomendada para transformar o projeto em uma plataforma SaaS onde cada tenant conecta o proprio numero de WhatsApp, mas todos compartilham um unico "mestre de vendas" no `n8n`.

## Objetivo

- cada tenant conecta o proprio WhatsApp dentro da aplicacao
- toda mensagem recebida entra em uma automacao compartilhada
- a IA atende com contexto isolado por `tenant_id`
- o agente usa apenas catalogo, politicas e dados daquele tenant
- a especializacao comercial muda por segmento e perfil do negocio

## Diagnostico do estado atual

- a plataforma ja possui configuracao manual da Evolution API em [IntegrationsSection.dart](/Users/heliojunior/projetos/saas_manu/lib/Scenes/TenantSettings/Widgets/IntegrationsSection.dart)
- o tenant ja guarda credenciais e token de webhook em [TenantModel.dart](/Users/heliojunior/projetos/saas_manu/lib/Commons/Models/TenantModel.dart)
- o backend ja testa conexao e recebe vendas do `n8n` em [index.js](/Users/heliojunior/projetos/saas_manu/functions/index.js)
- o fluxo principal de atendimento ja e multi-tenant por `tenant_id` em [whatsapp-sales-agent.json](/Users/heliojunior/projetos/saas_manu/automation/n8n/workflows/production/entrypoints/whatsapp-sales-agent.json)

O maior gap nao esta no agente de vendas, e sim na falta de um dominio completo para o canal WhatsApp: provisionamento, QR Code, ciclo de conexao, health-check, roteamento por instancia e especializacao estruturada por negocio.

## Modelo recomendado

### 1. Um unico mestre de vendas

Nao criar um agente por tenant. Manter um workflow principal compartilhado e injetar contexto dinamico do tenant:

- identificacao do tenant
- segmento e subsegmento
- horario de atendimento
- politicas comerciais
- tom de voz
- playbook de vendas
- catalogo e disponibilidade

### 2. Roteamento por instancia

O canal deve usar o mapeamento:

`whatsapp_instance_id -> tenant_id`

Fluxo:

1. mensagem chega do provedor de WhatsApp
2. webhook central identifica a instancia
3. backend ou `n8n` resolve o `tenant_id`
4. o mestre de vendas carrega contexto e atende no escopo correto

### 3. Dominio de integracao WhatsApp

O tenant deve ter campos dedicados para estado operacional do canal:

- `whatsapp_provider`
- `whatsapp_instance_id`
- `whatsapp_connection_status`
- `whatsapp_connected_number`
- `whatsapp_webhook_url`
- `whatsapp_last_seen_at`
- `whatsapp_qr_expires_at`

As credenciais manuais atuais da Evolution API devem continuar apenas como modo avancado ou fallback operacional.

## UX recomendada

Criar uma secao propria chamada `Integracao com WhatsApp` dentro de Configuracoes.

Fluxo ideal:

1. usuario clica em `Conectar WhatsApp`
2. backend cria ou recupera a instancia do tenant
3. a tela mostra QR Code e status da conexao
4. frontend faz polling ate conectar
5. apos conectar, exibir numero, provider, saude do canal e acoes de reconexao

Acoes desejadas:

- conectar numero
- reconectar
- desconectar
- testar envio
- copiar webhook
- ver ultimo heartbeat

## Contexto comercial por tenant

O agente precisa de contexto mais estruturado no documento do tenant:

- `business_segment`
- `business_subsegment`
- `business_description`
- `sales_playbook`
- `tone_of_voice`
- `target_audience`
- `business_hours`
- `delivery_policies`
- `payment_policies`
- `exchange_policies`
- `ai_sales_profile_version`

## Especializacao por segmento

O mestre de vendas deve trabalhar em 3 camadas:

1. prompt-base compartilhado
2. overlay por segmento
3. overlay especifico do tenant

Exemplos:

- moda: cor, tamanho, tecido, combinacao, caimento
- alimentacao: ingredientes, tamanho, combos, prazo de preparo, entrega
- eletronicos: modelo, compatibilidade, voltagem, garantia
- beleza: tipo de pele, composicao, beneficios, rotina
- servicos: agenda, disponibilidade, escopo, prazo

## Normalizacao de catalogo

O modelo atual de produto ja cobre boa parte do necessario, mas deve ser enriquecido por segmento. O objetivo nao e complicar o cadastro e sim entregar melhores argumentos para a IA vender.

Sugestao:

- manter atributos base comuns
- adicionar campos opcionais por vertical
- usar `tags`, `category`, `color`, `size` e campos especificos para tornar a busca mais precisa

## Providers nao oficiais recomendados

### Evolution API

Melhor opcao para fase 1 deste projeto porque:

- ja esta parcialmente integrada
- costuma suportar onboarding por QR Code
- encaixa bem em webhook + instancia por tenant
- reduz tempo de entrega

### Wrapper proprio com Baileys

Boa opcao apenas se o produto exigir controle muito fino de sessao, protocolo e infraestrutura.

Tradeoff:

- mais controle
- mais custo de manutencao
- mais fragilidade operacional

## Riscos operacionais

- APIs nao oficiais tem risco real de desconexao e instabilidade
- e preciso isolar tenants por instancia para evitar vazamento de contexto
- o produto precisa de health-check, reconnect e handoff humano
- falha no canal nao pode travar a operacao comercial do tenant

## Roadmap recomendado

### Fase 1

- consolidar Evolution API como provider inicial
- manter configuracao manual como fallback
- formalizar campos do tenant para contexto comercial e status do canal

### Fase 2

- criar funcoes backend para provisionar instancia, obter QR e ler status
- remodelar a tela de configuracoes para onboarding guiado

### Fase 3

- ajustar o workflow mestre para bootstrap dinamico completo do tenant
- separar overlays de prompt por segmento

### Fase 4

- adicionar observabilidade, fila de falhas, reconnect e handoff humano
- preparar camada de abstracao para trocar provider no futuro

## Decisao recomendada para este repositorio

- manter um unico workflow mestre de vendas
- usar `Evolution API` como provider inicial
- transformar WhatsApp em capacidade nativa do tenant
- enriquecer o tenant com contexto comercial estruturado
- rotear toda mensagem por `whatsapp_instance_id -> tenant_id`
