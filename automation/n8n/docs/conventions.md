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
