# saas_manu

Plataforma CRM multi-tenant em Flutter/Firebase, preparada para operar junto de automacoes no `n8n` e agentes de IA que atendem clientes dos tenants.

## Documentacao principal

- `ARCHITECTURE.md`: arquitetura, multi-tenancy e padroes do projeto
- `FUNCTIONAL_SPECS.md`: especificacao funcional da plataforma
- `FIREBASE_CONFIG.md`: configuracao e apoio para Firebase
- `automation/n8n/README.md`: organizacao dos workflows do `n8n`

## Estrutura de automacao

Os workflows do `n8n` ficam versionados em `automation/n8n/` para manter:

- visao geral entre CRM, dados e automacoes
- historico de mudancas junto do produto
- documentacao do comportamento do agente de IA
- separacao entre rascunhos, homologacao e producao

Antes de versionar um workflow, remova credenciais, tokens e qualquer segredo embutido.
