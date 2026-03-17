# n8n Workflows

Esta pasta concentra os workflows do `n8n` que suportam o CRM, o agente de IA e as integracoes operacionais da plataforma.

## Objetivo

Manter os fluxos perto do codigo ajuda a relacionar:

- regras de negocio do CRM
- eventos e colecoes do Firebase
- handoff entre IA e atendimento humano
- automacoes por tenant

## Estrutura

```text
automation/n8n/
├── workflows/
│   ├── drafts/       # Fluxos em elaboracao
│   ├── staging/      # Fluxos validados para homologacao
│   └── production/   # Fluxos que refletem o ambiente produtivo
│       ├── entrypoints/
│       ├── mcp/
│       └── subworkflows/
└── docs/
    ├── overview.md
    ├── tenants.md
    └── conventions.md
```

Na pasta `production/`, os arquivos ficam organizados por responsabilidade:

- `entrypoints/`: workflows principais expostos por webhook ou gatilho externo
- `mcp/`: servidores MCP e definicoes de ferramentas para o agente
- `subworkflows/`: blocos reutilizaveis por dominio de negocio

## Fluxo recomendado

1. Modelar ou ajustar o workflow no `n8n`.
2. Exportar o JSON sem credenciais sensiveis.
3. Salvar no diretorio adequado em `workflows/`.
4. Atualizar a documentacao em `docs/` se houver impacto funcional.
5. Versionar junto da mudanca de produto correspondente.

## Regras basicas

- Nunca commitar segredos, tokens ou chaves privadas.
- Preferir nomes de arquivos estaveis e descritivos.
- Promover workflow de `drafts/` para `staging/` e depois `production/` quando fizer sentido.
- Registrar dependencias externas e colecoes impactadas.
