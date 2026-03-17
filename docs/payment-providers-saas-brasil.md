# Meios de Pagamento para SaaS

Analise pratica para um SaaS brasileiro com cobranca recorrente, PIX, webhook e facilidade de integracao.

## Criterios usados

- facilidade de integracao para v1
- qualidade de API e webhooks
- suporte a PIX
- suporte a recorrencia/assinaturas
- adequacao para SaaS B2B de ticket baixo e medio
- previsibilidade operacional

## Opcoes mais aderentes

### Asaas

- Muito forte para operacao SaaS no Brasil.
- Boa combinacao de PIX, boleto, cartao e recorrencia.
- API costuma ser simples para v1 e webhook e bem direto.
- Bom encaixe para cobranca mensal de tenant e acao rapida de go-live.
- Ponto de atencao: confirmar custos atuais de transacao e disponibilidade dos recursos de assinatura no seu plano comercial.

### Iugu

- Tradicional em SaaS e recorrencia no Brasil.
- Boa aderencia a assinatura, retries, faturas e webhooks.
- Encaixa bem quando o foco principal e billing recorrente com menos friccao de produto.
- Ponto de atencao: UX operacional e custos precisam ser comparados com Asaas caso a caso.

### Stripe

- Melhor plataforma se houver ambicao internacional ou stack mais sofisticada de billing.
- Excelente documentacao, SDKs, webhooks e maturidade para assinatura, cupons, dunning e fiscalizacao de eventos.
- Para operacao brasileira, o encaixe melhora muito quando o negocio depende mais de cartao/assinatura global do que de PIX puro.
- Ponto de atencao: para PIX e operacao 100% Brasil, pode nao ser a rota mais enxuta para um v1 local.

### Pagar.me / Stone

- Boa opcao para operacoes brasileiras com cartao e PIX.
- Ecossistema forte e aderente a empresas que ja querem crescer em adquirencia nacional.
- Pode fazer sentido se voce quiser mais musculatura financeira desde cedo.
- Ponto de atencao: integracao e onboarding comercial podem ser um pouco menos leves do que Asaas para um MVP rapido.

### Mercado Pago

- Marca muito conhecida e operacao simples em varios cenarios.
- Bom para cobranca avulsa e PIX.
- Pode ajudar na rapidez inicial dependendo do perfil do negocio.
- Ponto de atencao: para billing SaaS recorrente mais robusto, normalmente nao e a primeira escolha.

### Efi / Gerencianet

- Muito lembrada para PIX e boleto.
- Boa alternativa quando o foco inicial e recebimento nacional com fluxo transacional simples.
- Pode combinar bem com automacoes via `n8n`.
- Ponto de atencao: para assinatura SaaS completa, compare com cuidado contra Asaas e Iugu.

## Recomendacao objetiva

### Melhor rota para v1 rapida no Brasil

- `Asaas` como primeira opcao.
- `Iugu` como segunda opcao.

Motivo: costumam equilibrar melhor velocidade de integracao, recorrencia, PIX e operacao SaaS.

### Melhor rota se houver plano internacional

- `Stripe`, eventualmente com complemento local de PIX se o modelo exigir.

## Estrategia tecnica sugerida para este projeto

- Manter o app falando apenas com `functions/createPixCheckout`.
- Conectar o provedor escolhido em um orquestrador pequeno, ou direto nas Functions em uma segunda fase.
- Padronizar webhooks do provedor para chamar `functions/paymentWebhook`.
- Persistir sempre:
  - `provider`
  - `transaction_id`
  - `status`
  - `paid_at`
  - `plan`
  - `plan_tier`

## Custos

As taxas variam por volume, negociacao comercial, meio de pagamento e prazo de recebimento. Para decisao final, recomendo comparar:

- taxa no PIX
- taxa no cartao recorrente
- custo por boleto, se houver
- prazo de repasse
- custo de chargeback e contestacao
- custo de antifraude, se separado
- facilidade para cancelar, trocar plano e reprocessar cobranca

Sem proposta comercial atualizada na mao, o criterio mais seguro para a v1 e priorizar facilidade de integracao e confiabilidade operacional, nao apenas a menor taxa nominal.
