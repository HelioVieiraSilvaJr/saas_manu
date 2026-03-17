# Multi-tenant e Workflows

Como a plataforma e multi-tenant, os workflows precisam respeitar isolamento de dados e configuracoes por empresa.

## Principios

- Todo processamento deve saber qual `tenant` esta em contexto.
- Nenhum workflow deve misturar dados entre tenants.
- Configuracoes especificas do tenant devem ser lidas de fontes controladas.
- Logs e eventos precisam permitir rastreio por tenant.

## Checklist por workflow

- Qual campo ou parametro identifica o tenant?
- O fluxo consulta apenas recursos autorizados daquele tenant?
- O agente de IA usa prompt, regras e canais corretos para aquele tenant?
- O handoff para humano preserva contexto da conversa?
- O fluxo gera eventos auditaveis?

## Convencao sugerida

Sempre que possivel, registrar no inicio do fluxo:

- `tenant_id`
- `channel`
- `customer_id`
- `conversation_id`
- `workflow_version`

Isso facilita observabilidade, auditoria e troubleshooting.
