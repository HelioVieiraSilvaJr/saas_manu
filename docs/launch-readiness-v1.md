# Launch Readiness V1

Checklist objetivo para acelerar a plataforma rumo a uma v1 comercial com menor risco operacional.

## O que ja foi fechado no codigo

- workflows do `n8n` versionados em `automation/n8n/`
- backend critico movido para `functions/`
- criacao de tenant e provisionamento de equipe feitos no backend
- webhook oficial para registrar vendas automatizadas
- scaffold de billing com checkout PIX e webhook interno
- regras multi-tenant endurecidas para Firestore e Storage
- teste da Evolution API migrado para backend, evitando CORS no app web
- onboarding com senha temporaria dinamica em vez de senha fixa exposta

## Checklist de go-live

1. Instalar dependencias em `functions/` e publicar as functions.
2. Configurar as variaveis de ambiente descritas em `functions/.env.example`.
3. Executar `syncMembershipAccessIndex` no ambiente real antes de publicar as regras novas.
4. Publicar `firestore.rules` e `storage.rules`.
5. Definir o provedor de pagamento e conectar o `PAYMENT_ORCHESTRATOR_URL`.
6. Validar o fluxo ponta a ponta:
   - criar tenant
   - adicionar membro
   - gerar webhook de vendas do `n8n`
   - registrar venda automatizada
   - gerar checkout PIX
   - receber confirmacao de pagamento
   - atualizar plano do tenant
7. Resolver placeholders restantes do `n8n`, especialmente `ESCALAR_HUMANO_ID`.
8. Configurar credenciais reais da Evolution API e do `n8n` por tenant.

## Gaps ainda relevantes para a v1

- inbox de conversas do WhatsApp ainda nao existe como modulo dedicado no app
- billing esta preparado para integracao, mas ainda depende do provedor escolhido
- faltam validacoes operacionais em ambiente real para regras do Firebase
- o projeto ainda carrega muitos avisos antigos no `flutter analyze`

## Recomendacao de ordem

1. Deploy do backend e das regras
2. Integracao de pagamento
3. Validacao do fluxo real WhatsApp -> n8n -> CRM
4. Fechamento do modulo de inbox/conversas
5. Limpeza de warnings e acabamento comercial
