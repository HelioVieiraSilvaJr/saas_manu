# saas_manu

Plataforma CRM multi-tenant em Flutter/Firebase, preparada para operar junto de automacoes no `n8n` e agentes de IA que atendem clientes dos tenants.

## Documentacao principal

- `ARCHITECTURE.md`: arquitetura, multi-tenancy e padroes do projeto
- `FUNCTIONAL_SPECS.md`: especificacao funcional da plataforma
- `FIREBASE_CONFIG.md`: configuracao e apoio para Firebase
- `automation/n8n/README.md`: organizacao dos workflows do `n8n`
- `functions/README.md`: backend Firebase Functions para operacoes criticas
- `docs/launch-readiness-v1.md`: checklist de go-live e prontidao da v1
- `docs/payment-providers-saas-brasil.md`: comparativo de meios de pagamento para SaaS

## Estrutura de automacao

Os workflows do `n8n` ficam versionados em `automation/n8n/` para manter:

- visao geral entre CRM, dados e automacoes
- historico de mudancas junto do produto
- documentacao do comportamento do agente de IA
- separacao entre rascunhos, homologacao e producao

Antes de versionar um workflow, remova credenciais, tokens e qualquer segredo embutido.

## Backend

Operacoes criticas da plataforma agora possuem uma camada server-side em `functions/`, incluindo:

- provisionamento de tenants e membros
- webhook oficial para receber vendas do `n8n`
- checkout de pagamento via orquestrador externo
- webhook interno para atualizacao de pagamentos
- teste server-side da Evolution API

## Proxima etapa recomendada

O caminho mais curto para liberar a v1 comercial agora e:

1. publicar `functions/`
2. migrar memberships com `syncMembershipAccessIndex`
3. publicar regras do Firebase
4. conectar provedor de pagamento
5. validar o fluxo real WhatsApp -> n8n -> CRM -> billing
