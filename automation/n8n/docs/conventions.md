# Convencoes

Este documento define um padrao simples para manter os workflows legiveis e seguros dentro do repositorio.

## Nome de arquivo

Use nomes descritivos em `kebab-case`, por exemplo:

- `lead-qualification.json`
- `sales-agent-inbound.json`
- `handoff-human-support.json`

Se houver versao relevante no arquivo exportado, use sufixo explicito:

- `sales-agent-inbound.v2.json`

## Ambientes

- `workflows/drafts/`: ideias, testes e fluxos ainda instaveis
- `workflows/staging/`: fluxos prontos para validacao
- `workflows/production/`: espelho do que esta ativo em producao

## Organizacao interna

Dentro de cada ambiente, prefira separar por papel tecnico:

- `entrypoints/`: fluxos principais que recebem eventos externos
- `mcp/`: servidores MCP, catalogos de tools e camadas de exposicao para agentes
- `subworkflows/`: componentes reutilizaveis chamados por outros workflows

Dentro de `subworkflows/`, agrupe por dominio quando houver volume:

- `customer/`
- `catalog/`
- `cart/`
- `channel/`
- `handoff/`

## Seguranca

- Remover credenciais antes de exportar
- Nao versionar tokens em campos de node, webhook ou headers
- Preferir referencia a variaveis/segredos gerenciados fora do JSON

## Documentacao minima

Para cada workflow importante, registrar no PR ou em arquivo adjacente:

- objetivo do fluxo
- trigger de entrada
- integracoes envolvidas
- entidades do CRM afetadas
- regras de erro e reprocessamento

## Compatibilidade

Quando um workflow depender de estrutura especifica do app ou banco, deixar explicito:

- colecoes Firestore acessadas
- endpoints consumidos
- contrato esperado de payload
- regra de versionamento

## Importacao e restauracao

Quando um conjunto de workflows depender de IDs internos do `n8n`:

- documentar a ordem de importacao
- registrar os IDs atuais dos subworkflows em um `README.md` do ambiente
- destacar qualquer placeholder que precise ser trocado apos import
