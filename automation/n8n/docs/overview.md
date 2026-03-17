# Visao Geral

Os workflows do `n8n` sao parte da arquitetura operacional do CRM. Eles devem refletir como o sistema reage a eventos, executa vendas assistidas por IA e faz escalonamento para humanos.

## Casos de uso esperados

- captacao e qualificacao de leads
- atendimento inicial por agente de IA
- consulta de produtos, estoque e historico do cliente
- criacao ou atualizacao de conversas e vendas
- escalonamento para atendimento humano
- follow-up, cobranca e reativacao

## Relacao com o CRM

Ao documentar ou revisar um workflow, descreva pelo menos:

- gatilho de entrada
- fontes de dados consultadas
- colecoes ou APIs alteradas
- regra de negocio principal
- criterio de escalonamento
- impacto por tenant

## Leitura rapida para revisao

Quando um workflow novo entrar no repositorio, vale anexar no commit ou PR:

- qual problema ele resolve
- quais campos ou colecoes usa
- quais falhas sao tratadas
- como validar o comportamento em staging
