# Configuração do Firebase - SaaS Manu

Este projeto usa Firebase como base transacional da plataforma e agora conta com uma camada server-side em `functions/` para operacoes criticas.

## Projeto atual

- Projeto Firebase: `saas-manu-project`
- Plataformas configuradas: Android, iOS, macOS, Web e Windows
- Configuracoes do app: `lib/firebase_options.dart`
- Configuracao do deploy: `firebase.json`

## Componentes em uso

- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Cloud Functions for Firebase

## Arquivos-chave

- `firestore.rules`
- `storage.rules`
- `firestore.indexes.json`
- `functions/index.js`
- `functions/.env.example`

## Fluxo recomendado de publicacao

1. Instalar dependencias em `functions/`.
2. Configurar variaveis de ambiente das functions.
3. Fazer deploy das functions.
4. Executar `syncMembershipAccessIndex` uma unica vez no ambiente real.
5. Publicar `firestore.rules` e `storage.rules`.
6. Validar os fluxos de tenant, equipe, WhatsApp, `n8n` e billing.

## Observacoes importantes

- As regras atuais ja estao endurecidas para um modelo multi-tenant mais seguro.
- As regras assumem IDs deterministas em `memberships` no formato `{tenant_id}_{user_id}`.
- O teste da Evolution API deve ser feito via function backend para evitar CORS no app web.
- O billing esta preparado no backend, mas depende da configuracao do provedor escolhido.

## Comandos uteis

```bash
flutter test
flutter analyze
cd functions && npm install
firebase deploy --only functions
firebase deploy --only firestore:rules,storage
```

## Referencias internas

- `functions/README.md`
- `docs/launch-readiness-v1.md`
- `docs/payment-providers-saas-brasil.md`
