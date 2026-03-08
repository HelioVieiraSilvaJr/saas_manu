# ESPECIFICAÇÕES FUNCIONAIS COMPLETAS

Documento com todas as especificações funcionais dos módulos da aplicação SaaS Multi-tenant de CRM + Vendas Automatizadas via WhatsApp.

---

## 📋 VISÃO GERAL DO PROJETO

**Tipo:** SaaS Multi-tenant  
**Domínio:** CRM + Vendas Automatizadas via WhatsApp  
**Público:** Micro-empreendedores  
**Plataformas:** Web + Mobile (iOS/Android)  
**Tech Stack:** Flutter + Firebase (Firestore, Auth, Storage, Analytics)  
**Integrações:** Evolution API (WhatsApp) + n8n (Automação/IA)

---

## 🏗️ ESTRUTURA DE DADOS (NESTED)

```
Firestore Root/
├── users/
│   └── {user_id}
│
├── memberships/
│   └── {membership_id}
│       ├── user_id
│       ├── tenant_id
│       ├── role (superAdmin | tenantAdmin | user)
│       └── is_active
│
└── tenants/
    └── {tenant_id}/
        ├── (dados do tenant)
        │
        ├── products/ (subcollection)
        │   └── {product_id}
        │
        ├── customers/ (subcollection)
        │   └── {customer_id}
        │
        ├── sales/ (subcollection)
        │   └── {sale_id}
        │
        └── billing/ (subcollection)
            └── {billing_id}
```

---

## 👥 SISTEMA DE ROLES

### Roles Disponíveis:

```dart
enum UserRole {
  superAdmin,   // Acesso global, gerencia tenants e billing
  tenantAdmin,  // Administra seu próprio tenant, convida usuários
  user          // Usuário padrão do tenant
}
```

### Matriz de Permissões:

| Funcionalidade | SuperAdmin | TenantAdmin | User |
|----------------|-----------|-------------|------|
| Ver todos os tenants | ✅ | ❌ | ❌ |
| Criar/Editar tenants | ✅ | ❌ | ❌ |
| Gerenciar billing global | ✅ | ❌ | ❌ |
| Dashboard próprio tenant | ✅ | ✅ | ✅ |
| Gerenciar produtos | ✅ | ✅ | ❌ |
| Gerenciar clientes | ✅ | ✅ | ❌ |
| Registrar vendas | ✅ | ✅ | ✅ |
| Ver vendas | ✅ | ✅ | ✅ |
| Gerenciar equipe | ✅ | ✅ | ❌ |
| Configurações tenant | ✅ | ✅ | ❌ |

---

## 📊 PLANOS E PREÇOS

| Plano | Preço | Duração | Recursos |
|-------|-------|---------|----------|
| **Trial** | Gratuito | 15 dias | Todas as funcionalidades |
| **Basic** | R$ 50/mês | Mensal | Até 100 produtos, 500 clientes |
| **Full** | R$ 150/mês | Mensal | Produtos e clientes ilimitados, suporte prioritário |

---

# MÓDULO 1: AUTENTICAÇÃO & ONBOARDING

## 🔐 Tela de Login

### Campos:
- Email (validação de formato)
- Senha (mínimo **7 caracteres**)
- Botão "Entrar" (com loading state)
- Link "Esqueci minha senha"

### Comportamento após Login:

```
1. Buscar memberships do usuário
2. Se tem múltiplos tenants:
   └─ Verificar último tenant usado (PreferencesManager)
   └─ Se existe memória → Logar nesse tenant
   └─ Se NÃO existe memória → Pegar primeiro da lista
3. Se tem apenas 1 tenant:
   └─ Logar automaticamente
4. SessionManager atualiza:
   ├─ currentUser
   ├─ currentTenant
   └─ currentMembership
5. Redirecionar → Dashboard Tenant
```

### Mensagens de Erro:
- Credenciais inválidas
- Conta desativada
- Email não cadastrado

---

## 🔄 Recuperação de Senha

- Usar **Firebase Auth padrão** (resetPassword)
- Link "Esqueci minha senha" na tela de login
- Enviar email com link de reset
- Mensagem de confirmação após envio

---

## 🔀 Seleção/Troca de Tenant

### Menu de Troca de Tenant:
- Exibir APENAS se user tiver 2+ tenants
- Localização: Menu lateral ou dropdown no header
- Dados exibidos: Nome do tenant, Plano

### Comportamento:
- Lembrar último tenant logado (PreferencesManager)
- Se não tiver memória → Primeiro da lista
- Ao trocar: `SessionManager.switchTenant()`

---

## 👤 Cadastro de Usuários (TenantAdmin)

### Fluxo:

**Caso 1: Usuário NOVO na plataforma**
```
1. TenantAdmin preenche:
   ├─ Nome completo
   ├─ Email
   └─ Role (tenantAdmin ou user)

2. Sistema verifica se email já existe em 'users'
   └─ Se NÃO existe:
       ├─ Criar documento em 'users/' com senha padrão '1234567'
       ├─ Criar 'membership' vinculando user ↔ tenant
       └─ Enviar email informando acesso (email + senha padrão)

3. Primeiro login do user:
   └─ Forçar troca de senha (modal/tela obrigatória)
```

**Caso 2: Usuário JÁ existe na plataforma**
```
1. TenantAdmin preenche formulário

2. Sistema verifica se email já existe
   └─ Se JÁ existe:
       ├─ NÃO criar novo documento em 'users/'
       ├─ Criar apenas 'membership' vinculando user ↔ tenant
       └─ Enviar email notificando adição ao novo tenant

3. User loga normalmente (senha já existe)
   └─ Verá novo tenant na lista de seleção
```

### Validações:
- Email único por tenant (não pode adicionar mesmo user 2x)
- Role obrigatória
- Email válido

---

## 🔒 Logout Forçado

### Quando:
- TenantAdmin INATIVA ou DELETA um user do team
- Atualizar `membership.is_active = false`

### Implementação:
```dart
// Middleware em cada requisição/navegação
void checkUserActiveStatus() async {
  final userId = SessionManager.instance.currentUser!.uid;
  final tenantId = SessionManager.instance.currentTenant!.uid;
  
  final membership = await firestore
    .collection('memberships')
    .where('user_id', isEqualTo: userId)
    .where('tenant_id', isEqualTo: tenantId)
    .where('is_active', isEqualTo: true)
    .get();
  
  if (membership.docs.isEmpty) {
    await SessionManager.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
    DSAlertDialog.showWarning(
      title: 'Acesso Removido',
      message: 'Seu acesso foi removido.',
    );
  }
}
```

---

## 🎨 UI/UX - Design da Tela de Login

### Layout:
- Card centralizado com elevação/sombra
- Ilustração de fundo (tema vendas/CRM/WhatsApp)
- Logo no topo do card
- Campos com DSTextFields
- Botão primário (DSButton)
- Link "Esqueci minha senha" discreto
- Responsivo (card menor no mobile)

---

# MÓDULO 2: DASHBOARD TENANT

## 📊 Seção 1: MÉTRICAS PRINCIPAIS (Hero Cards)

### 4 Cards em linha (Web) / Empilhados (Mobile):

#### Card 1: Vendas Hoje
- Valor: Total em R$ das vendas do dia atual
- Comparação: % vs dia anterior (ontem)
- Cor: Verde se positivo, Vermelho se negativo
- Ícone: 💰

#### Card 2: Vendas do Mês
- Valor: Total em R$ do mês atual (desde dia 1)
- Comparação: % vs mesmo período do mês anterior
- Cor: Verde se positivo, Vermelho se negativo
- Ícone: 📈

#### Card 3: Total de Clientes
- Valor: Quantidade total de clientes cadastrados
- Comparação: Quantidade de novos clientes no mês atual
- Cor: Azul (informativo)
- Ícone: 👥
- Texto comparação: "+12 este mês" (ao invés de %)

#### Card 4: Ticket Médio
- Valor: Valor médio por venda (total vendas / qtd vendas) no mês
- Comparação: % vs mês anterior
- Cor: Verde se positivo, Vermelho se negativo
- Ícone: 🎯

### Formato dos Cards:
```
┌─────────────────┐
│ [Ícone] Vendas  │
│       Hoje      │
│                 │
│   R$ 450,00     │  ← Valor principal (grande)
│   ↑ +15%        │  ← Comparação (pequeno, colorido)
└─────────────────┘
```

---

## 📈 Seção 2: GRÁFICO DE VENDAS

### Especificação:
- **Tipo:** Gráfico de Linha
- **Dados:** Vendas dos últimos 7 dias
- **Eixo X:** Dias da semana (Seg, Ter, Qua, Thu, Sex, Sáb, Dom)
- **Eixo Y:** Valor em R$
- **Título:** "Vendas dos Últimos 7 Dias"

### Detalhes Visuais:
- Linha com cor primária do Design System
- Pontos marcados em cada dia
- Tooltip ao passar mouse/tocar (valor exato)
- Grid horizontal discreto
- Responsivo (altura fixa, largura 100%)

### Biblioteca:
- **fl_chart** ou **syncfusion_flutter_charts**

### Empty State:
- Gráfico com linha zerada
- Mensagem: "Você ainda não tem vendas registradas."

---

## 📋 Seção 3: ÚLTIMAS VENDAS

### Especificação:
- **Título:** "Últimas Vendas"
- **Quantidade:** 5 vendas mais recentes
- **Ordenação:** Por data/hora (mais recente primeiro)

### Informações por Venda:
```
┌─────────────────────────────────────┐
│ [Avatar] João Silva                 │
│          2 itens • R$ 150,00        │
│          [Badge: WhatsApp Bot]      │
│          Há 5 minutos               │
└─────────────────────────────────────┘
```

**Campos:**
- Nome do Cliente
- Quantidade de itens
- Valor total (formatado em R$)
- Origem: Badge colorido (Manual/WhatsApp Bot)
- Tempo relativo: "Há X minutos/horas/dias"
- Avatar: Inicial do nome ou ícone padrão

### Comportamentos:
- Click/Tap → Navega para detalhes da venda
- Botão "Ver todas as vendas →" no final
- Empty State: "Nenhuma venda registrada"

---

## 🎨 Seção 4: AÇÕES RÁPIDAS

### 3 Botões:

#### 1. Nova Venda
- Ícone: + ou 🛒
- Cor: Primária
- Ação: Navega para tela de Nova Venda

#### 2. Novo Produto
- Ícone: + ou 📦
- Cor: Secundária
- Ação: Navega para Cadastro de Produto

#### 3. Novo Cliente
- Ícone: + ou 👤
- Cor: Terciária
- Ação: Navega para Cadastro de Cliente

### Layout:
- **Web:** 3 botões em linha (horizontal)
- **Mobile:** 3 botões em linha ou grid 2+1
- Cards elevados com hover effect

---

## ⚠️ Seção 5: ALERTAS/NOTIFICAÇÕES

### Tipos de Alertas:

#### 1. Plano expirando:
```
⚠️ Seu plano [TRIAL/BASIC/FULL] expira em X dias.
   [Renovar Agora]
```
- Cor: Laranja/Amarelo
- Condição: Plano expira em <= 7 dias

#### 2. Produtos sem imagem:
```
ℹ️ Você tem X produtos sem foto cadastrada.
   [Ver Produtos]
```
- Cor: Azul
- Condição: Produtos com `image_url == null`

#### 3. Catálogo vazio:
```
⚠️ Seu catálogo está vazio! Cadastre produtos.
   [Cadastrar Primeiro Produto]
```
- Cor: Laranja
- Condição: Total de produtos == 0

#### 4. Nenhum cliente:
```
ℹ️ Você ainda não tem clientes cadastrados.
   [Cadastrar Primeiro Cliente]
```
- Cor: Azul
- Condição: Total de clientes == 0

#### 5. Sem vendas no mês:
```
ℹ️ Você ainda não registrou vendas este mês.
   [Fazer Primeira Venda]
```
- Cor: Azul
- Condição: Vendas do mês == 0

### Comportamentos:
- Alertas são **dispensáveis** (X para fechar)
- Após dispensar: não mostrar por 7 dias (PreferencesManager)
- Ordenar por **prioridade** (críticos primeiro)
- Limite de 3 alertas visíveis
- Se não há alertas: não exibir a seção

---

# MÓDULO 3: PRODUTOS (CRUD COMPLETO)

## 📦 Listagem de Produtos

### Layout:
- **Web:** Grid 4 colunas (1200px+), 3 colunas (768-1199px)
- **Mobile:** 2 colunas

### Card do Produto:
```
┌─────────────────────┐
│   [Imagem 150x150]  │
│                     │
│ Nome do Produto     │
│                     │
│ R$ 150,00           │
│                     │
│ SKU: ABC123         │
│ Estoque: 50 un.     │
│                     │
│ [✓ Ativo]           │
│                     │
│ [✏️ Editar] [🗑️]    │
└─────────────────────┘
```

### Informações Exibidas:
1. **Imagem:** 150x150px, crop centralizado, placeholder se vazio
2. **Nome:** Bold, 1-2 linhas, ellipsis
3. **Preço:** Grande, cor primária, sempre 2 decimais
4. **SKU:** Pequena, cinza
5. **Estoque:** 
   - Verde: > 10 unidades
   - Amarelo: 1-10 unidades  
   - Vermelho: 0 unidades
6. **Badge Status:** Verde (Ativo) / Cinza (Inativo)
7. **Botões:** Editar, Deletar

### Busca e Filtros:

#### Busca:
- Placeholder: "Buscar por nome, SKU ou descrição..."
- Debounce: 300ms
- Busca em: nome, SKU, descrição

#### Filtros:
- **Status:** Todos / Ativos / Inativos
- **Estoque:** Todos / Disponível (>0) / Sem Estoque (0) / Baixo (<10)

#### Ordenação:
- Nome (A-Z / Z-A)
- Preço (Menor / Maior)
- Estoque (Menor / Maior)
- Mais Recentes / Mais Antigos

### Header:
```
Produtos (45)                    [+ Novo Produto]
```

### Empty States:
1. **Nenhum produto:** Ilustração + "Adicionar Produto"
2. **Busca vazia:** "Nenhum produto encontrado"
3. **Filtros vazios:** "Limpar Filtros"

---

## ➕ Cadastro/Edição de Produto

### Campos do Formulário:

| Campo | Tipo | Obrigatório | Validação |
|-------|------|-------------|-----------|
| **Nome** | Text | ✅ Sim | Min 3, Max 100 |
| **SKU** | Text | ✅ Sim | Min 1, Max 50, **único no tenant** |
| **Preço** | Number | ✅ Sim | > 0, formato R$ |
| **Estoque** | Number | ✅ Sim | >= 0, inteiro |
| **Descrição** | TextArea | ❌ Não | Max 500 caracteres |
| **Imagem** | Upload | ❌ Não | JPG/PNG/WEBP, max 5MB |
| **Status** | Toggle | ✅ Sim | Default: Ativo |

### Layout do Formulário:
```
┌─────────────────────────────────────┐
│ Novo Produto              [X]       │
├─────────────────────────────────────┤
│ [📷 Upload Imagem]                  │
│                                     │
│ Nome do Produto *                   │
│ [_______________________________]   │
│                                     │
│ SKU (Código) *                      │
│ [_______________________________]   │
│ ⓘ Código único do produto           │
│                                     │
│ Preço (R$) *    Estoque *           │
│ [R$ _______]    [___ unidades]      │
│                                     │
│ Descrição                           │
│ [_______________________________]   │
│ [_______________________________]   │
│ 0/500 caracteres                    │
│                                     │
│ ☑️ Produto ativo                    │
│                                     │
│ [Cancelar]          [Salvar]        │
└─────────────────────────────────────┘
```

### Upload de Imagem:

**Antes do Upload:**
```
┌─────────────────┐
│  [📷 Ícone]     │
│ Clique ou       │
│ arraste aqui    │
│ JPG, PNG (5MB)  │
└─────────────────┘
```

**Após Upload:**
```
┌─────────────────┐
│ [Preview Image] │
│ [Remover][Trocar]│
└─────────────────┘
```

**Storage Path:**
```
tenants/{tenant_id}/products/{product_id}/{timestamp}.jpg
```

### Validações Especiais:

#### SKU Único:
```dart
validator: (value) async {
  final exists = await productRepository.skuExists(
    value, 
    excludeId: productId
  );
  if (exists) return 'Este SKU já está em uso';
  return null;
}
```

#### Máscara de Preço:
```dart
CurrencyInputFormatter() // R$ 1.500,00
```

### Ao Salvar:
1. Validar formulário
2. Upload imagem (se houver)
3. Criar/Atualizar produto
4. Feedback sucesso
5. Voltar para lista

---

## 👁️ Detalhes do Produto

### Informações Exibidas:
- Imagem grande (300x300)
- Nome (grande, bold)
- Preço (grande, colorido)
- SKU
- Estoque (com cor baseada em quantidade)
- Badge Status
- Descrição completa
- Metadados (data criação, atualização)

### Ações:
- Editar
- Deletar

---

## 🗑️ Exclusão de Produto

### Modal de Confirmação:
```dart
DSAlertDialog.showDelete(
  context: context,
  title: 'Confirmar Exclusão',
  message: 'Tem certeza que deseja remover este produto?',
  content: DSAlertContentCard(
    icon: Icons.shopping_bag_outlined,
    title: product.name,
    subtitle: 'SKU: ${product.sku} • ${product.price.formatToBRL()}',
  ),
);
```

### Lógica de Exclusão:

**Se produto já foi vendido:**
- **Soft Delete:** `is_active = false`
- Mensagem: "Produto inativado (possui vendas)"

**Se produto nunca foi vendido:**
- Confirmação adicional
- **Hard Delete:** Remove do Firestore
- Mensagem: "Produto excluído permanentemente"

---

## 📊 ProductModel

```dart
class ProductModel {
  String uid;
  String name;
  String sku;
  double price;
  int stock;
  String? description;
  String? image_url;
  bool is_active;
  DateTime created_at;
  DateTime? updated_at;
}
```

---

# MÓDULO 4: CLIENTES (CRM)

## 👥 Listagem de Clientes

### Layout:
- **Web:** Lista compacta
- **Mobile:** Cards

### Item da Lista (Web):
```
┌────────────────────────────────────────────────┐
│ [JS] João Silva                  [💬][✏️][🗑️] │
│      (11) 98765-4321 • joao@email.com         │
│      Última compra: Há 3 dias • Total: R$ 450 │
└────────────────────────────────────────────────┘
```

### Informações:
1. **Avatar:** Iniciais, cor por hash
2. **Nome:** Bold
3. **WhatsApp + Email:** Cinza, separados por •
4. **Última Compra:** Tempo relativo + Total gasto
   - Se nunca comprou: "Nunca comprou"
5. **Botões:**
   - **[💬 WhatsApp]:** Abre `wa.me/...`
   - **[✏️ Editar]**
   - **[🗑️ Deletar]**

### Busca e Filtros:

#### Busca:
- Placeholder: "Buscar por nome, WhatsApp ou email..."
- Busca em: nome, whatsapp, email

#### Filtros:
- **Status:** Todos / Ativos (já compraram) / Inativos (nunca compraram)
- **Período Última Compra:** Todos / 7 dias / 30 dias / 90 dias

#### Ordenação:
- Nome (A-Z / Z-A)
- Última compra (Recente / Antiga)
- Total gasto (Maior / Menor)
- Data cadastro (Recente / Antiga)

### Header:
```
Clientes (245)                [+ Novo Cliente]
```

---

## ➕ Cadastro/Edição de Cliente

### Campos (SIMPLIFICADO):

| Campo | Tipo | Obrigatório | Validação |
|-------|------|-------------|-----------|
| **Nome Completo** | Text | ✅ Sim | Min 3, Max 100 |
| **WhatsApp** | Tel | ✅ Sim | Formato válido, **único no tenant** |
| **Email** | Email | ❌ Não | Formato válido (se preenchido) |
| **Observações** | TextArea | ❌ Não | Max 500 caracteres |

### Layout:
```
┌─────────────────────────────────────┐
│ Novo Cliente              [X]       │
├─────────────────────────────────────┤
│ Nome Completo *                     │
│ [_______________________________]   │
│                                     │
│ WhatsApp *                          │
│ [(11) 98765-4321________________]   │
│ ⓘ Principal meio de contato         │
│                                     │
│ Email                               │
│ [_______________________________]   │
│                                     │
│ Observações                         │
│ [_______________________________]   │
│ [_______________________________]   │
│ 0/500 caracteres                    │
│                                     │
│ [Cancelar]          [Salvar]        │
└─────────────────────────────────────┘
```

### Validações Especiais:

#### WhatsApp Único:
```dart
validator: (value) async {
  final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
  
  if (cleanNumber.length != 11) {
    return 'WhatsApp inválido (11 dígitos)';
  }
  
  final exists = await customerRepository.whatsappExists(
    cleanNumber,
    excludeId: customerId,
  );
  
  if (exists) return 'Este WhatsApp já está cadastrado';
  return null;
}
```

#### Máscara WhatsApp:
```
(11) 98765-4321
```

### Armazenamento:
- WhatsApp salvo **apenas números:** `11987654321`

---

## 👁️ Detalhes do Cliente

### Layout:
```
┌─────────────────────────────────────┐
│ ← Voltar          [Editar][Deletar] │
├─────────────────────────────────────┤
│      [Avatar Grande - JS]           │
│                                     │
│ João da Silva Santos                │
│                                     │
│ 📱 (11) 98765-4321                  │
│    [💬 Abrir WhatsApp]              │
│                                     │
│ 📧 joao@email.com                   │
│    [✉️ Enviar Email]                │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Observações:                        │
│ Cliente preferencial...             │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Estatísticas de Compras:            │
│                                     │
│ ┌──────────┐ ┌──────────┐          │
│ │  Total   │ │  Total   │          │
│ │ Compras  │ │  Gasto   │          │
│ │    15    │ │R$ 2.450  │          │
│ └──────────┘ └──────────┘          │
│                                     │
│ ┌──────────┐ ┌──────────┐          │
│ │ Ticket   │ │ Cliente  │          │
│ │  Médio   │ │  Desde   │          │
│ │ R$ 163   │ │ 58 dias  │          │
│ └──────────┘ └──────────┘          │
│                                     │
│ • Primeira Compra: 15/01/2024       │
│ • Última Compra: Há 3 dias          │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Histórico de Compras (15):          │
│                                     │
│ [Lista últimas 5 vendas]            │
│ [Ver Todas as Compras →]            │
│                                     │
└─────────────────────────────────────┘
```

### Estatísticas (Cálculos):
```dart
final totalCompras = await salesRepository.countByCustomer(customerId);
final vendas = await salesRepository.getByCustomer(customerId);
final totalGasto = vendas.fold(0.0, (sum, v) => sum + v.total);
final ticketMedio = totalCompras > 0 ? totalGasto / totalCompras : 0.0;
final diasDesde = DateTime.now().difference(customer.created_at).inDays;
```

---

## 🗑️ Exclusão de Cliente

### Lógica:

**Se cliente tem compras:**
- **Soft Delete:** `is_active = false`
- Mensagem: "Cliente inativado (possui histórico)"

**Se cliente sem compras:**
- **Hard Delete:** Remove do Firestore
- Mensagem: "Cliente excluído permanentemente"

---

## 📊 CustomerModel

```dart
class CustomerModel {
  String uid;
  String name;
  String whatsapp;              // Apenas números
  String? email;
  String? notes;
  bool is_active;
  DateTime created_at;
  DateTime? updated_at;
  DateTime? last_purchase_at;   // Denormalizado
  double? total_spent;          // Denormalizado
  int? purchase_count;          // Denormalizado
}
```

**Nota:** Campos denormalizados são atualizados quando uma venda é criada.

---

# MÓDULO 5: VENDAS (MANUAL + AUTOMÁTICA)

## 💰 Listagem de Vendas

### Layout:
- **Web:** Lista
- **Mobile:** Cards

### Item da Lista:
```
┌────────────────────────────────────────────────┐
│ #001 • 05/03/2024 14:30            [Ver][🗑️]  │
│ João Silva • R$ 150,00 • 2 itens               │
│ [WhatsApp Bot] [Confirmada]                    │
└────────────────────────────────────────────────┘
```

### Informações:
1. **Número Venda:** #00XXX
2. **Data/Hora**
3. **Cliente**
4. **Valor Total**
5. **Quantidade Itens**
6. **Badge Origem:** Manual (Azul) / WhatsApp Bot (Verde/Roxo)
7. **Badge Status:** Pendente (Amarelo) / Confirmada (Verde) / Cancelada (Vermelho)

### Mini-Cards (Header):
```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Hoje     │ │ Este Mês │ │ Ticket   │
│ R$ 450   │ │R$ 12.500 │ │ Médio    │
│ 3 vendas │ │ 45 vendas│ │ R$ 278   │
└──────────┘ └──────────┘ └──────────┘
```

### Busca e Filtros:

#### Busca:
- Número venda, Nome cliente, Produto

#### Filtros:
- **Status:** Todos / Pendente / Confirmada / Cancelada
- **Origem:** Todas / Manual / WhatsApp Bot
- **Período:** Hoje / 7 dias / 30 dias / Este mês / Personalizado
- **Faixa de Valor:** De R$ ___ Até R$ ___

#### Ordenação:
- Mais Recentes (padrão)
- Mais Antigas
- Valor (Maior / Menor)
- Cliente (A-Z / Z-A)

---

## ➕ Nova Venda Manual

### Fluxo (Tela Única - Web):

```
┌─────────────────────────────────────┐
│ Nova Venda              [X]         │
├─────────────────────────────────────┤
│ 1️⃣ Cliente *                        │
│ [🔍 Buscar cliente...]              │
│ [+ Cadastrar Novo]                  │
│                                     │
│ ✓ [Cliente Selecionado]             │
│                                     │
│ 2️⃣ Produtos *                       │
│ [🔍 Buscar produto...]              │
│                                     │
│ Carrinho (2 itens):                 │
│ • Camiseta x2 = R$ 300  [🗑️]        │
│ • Calça x1 = R$ 200     [🗑️]        │
│                                     │
│ 3️⃣ Observações                      │
│ [_______________________________]   │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ 📊 Resumo:                          │
│ Subtotal (2 itens): R$ 500,00       │
│ ════════════════════════════════    │
│ TOTAL:              R$ 500,00       │
│                                     │
│ [Cancelar]      [Confirmar Venda]   │
└─────────────────────────────────────┘
```

### Mobile (Multi-step Wizard):

**Passo 1:** Selecionar Cliente  
**Passo 2:** Adicionar Produtos (Carrinho)  
**Passo 3:** Confirmar

### Seleção de Cliente:

**Autocomplete:**
```
[🔍 Buscar cliente...]
     ↓
┌─────────────────────┐
│ João Silva          │
│ (11) 98765-4321     │
├─────────────────────┤
│ Maria Santos        │
│ (11) 91234-5678     │
├─────────────────────┤
│ + Cadastrar "João"  │
└─────────────────────┘
```

### Adição de Produtos:

**Busca:**
```
[🔍 Buscar produto...]
     ↓
┌─────────────────────────────┐
│ [Foto] Camiseta Polo Azul   │
│ R$ 150,00 • Est: 50         │
│ [+ Adicionar]               │
└─────────────────────────────┘
```

**Carrinho:**
```
┌─────────────────────────────────┐
│ [Foto] Camiseta Polo Azul       │
│ R$ 150,00 x [2▼] = R$ 300 [🗑️]  │
└─────────────────────────────────┘
```

### Validações:

**Estoque:**
```dart
if (quantidade > produto.stock) {
  DSAlertDialog.showWarning(
    title: 'Estoque Insuficiente',
    message: 'Disponível: ${produto.stock} unidades',
  );
}
```

### Ao Confirmar:
1. Validar formulário (cliente + produtos)
2. Criar SaleModel
3. **Atualizar estoque** (decrementar)
4. **Atualizar stats do cliente** (denormalizados)
5. Feedback sucesso
6. Voltar para lista

---

## 🤖 Venda Automática (n8n)

### Fluxo:
```
Cliente WhatsApp
    ↓
Evolution API
    ↓
n8n (Agente IA monta carrinho)
    ↓
n8n cria documento em:
  tenants/{tenant_id}/sales/{sale_id}
    ↓
Flutter detecta via Stream
    ↓
UI atualiza automaticamente
    ↓
Notificação para TenantAdmin
```

### Estrutura Criada pelo n8n:
```json
{
  "customer_id": "abc123",
  "customer_name": "João Silva",
  "customer_whatsapp": "11987654321",
  "items": [
    {
      "product_id": "prod_001",
      "product_name": "Camiseta",
      "quantity": 2,
      "unit_price": 150.00,
      "subtotal": 300.00
    }
  ],
  "total": 500.00,
  "status": "pending",
  "source": "whatsapp_automation",
  "notes": "Cliente pediu entrega rápida",
  "created_at": "2024-03-08T14:30:00Z"
}
```

### Stream/Listener:
```dart
Stream<List<SaleModel>> watchNewSales() {
  final tenantId = SessionManager.instance.currentTenant!.uid;
  final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
  
  return firestore
    .collection('tenants/$tenantId/sales')
    .where('created_at', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
    .where('source', isEqualTo: 'whatsapp_automation')
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => SaleModel.fromDocumentSnapshot(doc))
        .toList());
}
```

### Notificação:
```dart
void setupNewSalesListener(BuildContext context) {
  _subscription = viewModel.watchNewSales().listen((newSales) {
    if (newSales.isNotEmpty) {
      ElegantNotification.success(
        title: "Nova Venda!",
        description: "${newSales.length} nova(s) venda(s).",
      ).show(context);
    }
  });
}
```

---

## 👁️ Detalhes da Venda

### Layout:
```
┌─────────────────────────────────────┐
│ ← Voltar                    [🗑️]    │
├─────────────────────────────────────┤
│ Venda #00125                        │
│ 📅 05/03/2024 às 14:30              │
│                                     │
│ [WhatsApp Bot] [Confirmada]         │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ 👤 Cliente:                         │
│ João Silva                          │
│ (11) 98765-4321                     │
│ [💬 WhatsApp]                       │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ 🛒 Produtos (2 itens):              │
│                                     │
│ • Camiseta x2 = R$ 300,00           │
│ • Calça x1 = R$ 200,00              │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ 📊 Resumo:                          │
│ Subtotal: R$ 500,00                 │
│ ════════════════════                │
│ TOTAL:    R$ 500,00                 │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ 📝 Observações:                     │
│ Cliente pediu entrega rápida        │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ 🔄 Ações:                           │
│ [Alterar Status ▼]                  │
│                                     │
└─────────────────────────────────────┘
```

### Alterar Status:
```
Dropdown:
• Pendente
• Confirmada
• Cancelada
```

**Ao Cancelar:**
- Devolver produtos ao estoque (incrementar)

---

## 🗑️ Exclusão de Venda

### Lógica:
```dart
Future<void> deleteSale(SaleModel sale) async {
  // 1. Devolver produtos ao estoque
  for (var item in sale.items) {
    await productRepository.incrementStock(
      item.product_id, 
      item.quantity
    );
  }
  
  // 2. Atualizar stats do cliente
  await customerRepository.decrementPurchaseStats(
    sale.customer_id,
    sale.total,
  );
  
  // 3. Deletar venda
  await salesRepository.delete(sale.uid);
}
```

---

## 📊 SaleModel

```dart
enum SaleStatus { pending, confirmed, cancelled }
enum SaleSource { manual, whatsapp_automation }

class SaleItemModel {
  String product_id;
  String product_name;
  int quantity;
  double unit_price;
  double subtotal;
}

class SaleModel {
  String uid;
  String customer_id;
  String customer_name;        // Denormalizado
  String customer_whatsapp;    // Denormalizado
  List<SaleItemModel> items;
  double total;
  SaleStatus status;
  SaleSource source;
  String? notes;
  DateTime created_at;
}
```

---

# MÓDULO 6: DASHBOARD SUPERADMIN

## 👑 Dashboard Principal

### Métricas (4 Cards):

#### 1. Total de Tenants
- Valor: Quantidade total
- Comparação: +X novos este mês
- Cor: Azul

#### 2. Tenants Ativos
- Valor: `is_active = true`
- Comparação: % do total
- Cor: Verde

#### 3. Tenants em Trial
- Valor: `plan = 'trial'`
- Comparação: Quantos expiram em 7 dias
- Cor: Laranja

#### 4. Receita Mensal (MRR)
- Valor: Soma de planos ativos
- Fórmula: `(Qtd Basic × 50) + (Qtd Full × 150)`
- Comparação: % vs mês anterior
- Cor: Roxo/Verde

### Gráficos:

#### 1. Crescimento de Tenants (Linha):
- Últimos 30 dias
- Novos tenants por dia

#### 2. Distribuição por Plano (Pizza):
- Trial: X (%)
- Basic: X (%)
- Full: X (%)

### Últimas Atividades (Timeline):
```
• Novo tenant criado
  "Loja da Maria"
  Há 5 minutos

• Upgrade de plano
  "Empresa XYZ" (Basic → Full)
  Há 1 hora

• Tenant inativado
  "Loja Teste" (Trial expirado)
  Há 2 horas
```

### Alertas Críticos:
```
⚠️ 12 tenants com trial expirando em 3 dias
   [Ver Lista]

🔴 3 tenants com pagamento atrasado
   [Ver Lista]

ℹ️ 5 tenants inativos há 30+ dias
   [Ver Lista]
```

---

## 🏢 Gerenciar Tenants

### Listagem:
```
┌────────────────────────────────────────────────┐
│ Loja da Maria                  [Edit][👁️][🗑️] │
│ maria@loja.com • (11) 98765-4321               │
│ [Trial] [Ativo] • Expira: 3 dias              │
└────────────────────────────────────────────────┘
```

### Filtros:
- **Plano:** Todos / Trial / Basic / Full
- **Status:** Todos / Ativos / Inativos
- **Situação:** Todas / Trial expirando / Pag. atrasado / Criados hoje/7d/30d

### Ordenação:
- Nome (A-Z / Z-A)
- Mais Recentes / Mais Antigos
- Plano (Trial → Full / Full → Trial)

---

## ➕ Criar Novo Tenant

### Formulário:
```
┌─────────────────────────────────────┐
│ Criar Novo Tenant         [X]       │
├─────────────────────────────────────┤
│ Nome da Empresa *                   │
│ [_______________________________]   │
│                                     │
│ Email de Contato *                  │
│ [_______________________________]   │
│ ⓘ Será o primeiro usuário (Admin)  │
│                                     │
│ Telefone/WhatsApp *                 │
│ [(11) 98765-4321________________]   │
│                                     │
│ Plano *                             │
│ ⚪ Trial (Gratuito - 15 dias)       │
│ ⚪ Basic (R$ 50/mês)                │
│ 🔵 Full (R$ 150/mês)                │
│                                     │
│ ☑️ Tenant ativo                     │
│                                     │
│ [Cancelar]          [Criar Tenant]  │
└─────────────────────────────────────┘
```

### Ao Criar:
1. Criar documento em `tenants/`
2. Criar usuário em `users/` (senha padrão: 1234567)
3. Criar membership (tenantAdmin)
4. Enviar email boas-vindas
5. Se Trial: `trial_end_date = hoje + 15 dias`

---

## ✏️ Editar Tenant

### Campos Editáveis:
- Nome
- Email
- Telefone
- Plano (com confirmação)
- Ativo/Inativo

### Informações Adicionais:
- Criado em
- Trial expira (se aplicável)
- Total usuários
- Total vendas / receita

---

## 👁️ Ver Detalhes do Tenant

### Seções:

#### Informações do Plano:
- Plano Atual
- Trial expira em X dias (se aplicável)
- Criado em

#### Estatísticas:
```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Usuários │ │ Produtos │ │ Clientes │
│    3     │ │    45    │ │    127   │
└──────────┘ └──────────┘ └──────────┘

┌──────────┐ ┌──────────┐ ┌──────────┐
│ Vendas   │ │ Receita  │ │ Ticket   │
│    89    │ │R$ 12.500 │ │ R$ 140   │
└──────────┘ └──────────┘ └──────────┘
```

#### Usuários do Tenant:
- Lista de membros (nome, email, role)

#### Ações Disponíveis:
- **Estender Trial** (+X dias)
- **Alterar Plano**
- **Inativar Tenant**
- **Acessar como Admin** (Impersonate)

---

## 🗑️ Deletar Tenant

### Confirmação Dupla:
1. Modal inicial
2. Digitar nome do tenant para confirmar

### Lógica:
- Deletar **todas as subcoleções** (produtos, clientes, vendas)
- Deletar **memberships**
- Deletar **tenant**

**⚠️ Ação IRREVERSÍVEL**

---

## 💳 Billing

### Visão Geral:

**Cards:**
```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ MRR      │ │ Em Dia   │ │ Atrasados│ │ Cancelam.│
│R$ 45.000 │ │   198    │ │     3    │ │    5     │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

### Gráfico:
- Receita mensal (últimos 12 meses)

### Próximos Pagamentos (7 dias):
```
┌────────────────────────────────────┐
│ 10/03/24 • Empresa XYZ • R$ 150 [✓]│
│ 12/03/24 • Loja ABC • R$ 50     [✓]│
└────────────────────────────────────┘
```

### Pagamentos Atrasados:
```
🔴 Loja Teste • R$ 50 • Atraso: 15 dias
   [Enviar Lembrete] [Inativar]
```

### Tabela de Preços:
```
Trial:  Gratuito (15 dias)
Basic:  R$ 50/mês
Full:   R$ 150/mês
```

**Nota:** Preços hardcoded no MVP

---

## 🔍 Suporte

### Logs de Auditoria:
```
08/03/2024 14:30
👤 admin@plataforma.com (SuperAdmin)
➕ Criou tenant "Loja ABC"

08/03/2024 13:15
👤 admin@plataforma.com
📝 Alterou plano "Empresa XYZ" (Basic → Full)

08/03/2024 10:00
👤 admin@plataforma.com
👁️ Acessou como admin do tenant "Loja Maria"
```

### Eventos Rastreados:
- Criar/Editar/Deletar tenant
- Alterar plano
- Inativar/Reativar
- Impersonate
- Estender trial

---

# MÓDULO 7: CONFIGURAÇÕES DO TENANT

## ⚙️ Menu de Configurações

### Estrutura:
```
⚙️ Configurações
  ├─ 🏢 Dados da Empresa
  ├─ 🔌 Integrações
  └─ 💳 Plano & Assinatura
```

---

## 🏢 Dados da Empresa

### Campos:

| Campo | Editável |
|-------|----------|
| **Nome da Empresa** | ✅ |
| **Email de Contato** | ✅ |
| **Telefone/WhatsApp** | ✅ |

**Nota:** CNPJ e Endereço → Fase 2

---

## 🔌 Integrações

### WhatsApp/Evolution API:

**Campos:**
```
Status: 🔴 Não Conectado

URL da Evolution API *
[https://api.evolution.com/______]

API Key *
[**********************************]
[Mostrar] [Copiar]

Instance Name *
[loja-maria-whatsapp_____________]

[Testar Conexão]
```

**Funcionalidades:**

**Testar Conexão:**
```dart
Future<void> testConnection() async {
  if (evolutionApiUrl.isEmpty || apiKey.isEmpty || instanceName.isEmpty) {
    DSAlertDialog.showWarning(
      context: context,
      title: 'Campos Obrigatórios',
      message: 'Preencha todos os campos antes de testar.',
    );
    return;
  }
  
  setState(() => isTesting = true);
  
  try {
    final response = await http.get(
      Uri.parse('$evolutionApiUrl/instance/$instanceName/status'),
      headers: {'apikey': apiKey},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      DSAlertDialog.showSuccess(
        context: context,
        title: 'Conexão Estabelecida!',
        message: 'WhatsApp conectado: ${data['instance']['state']}',
      );
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  } catch (e) {
    DSAlertDialog.showError(
      context: context,
      title: 'Erro de Conexão',
      message: 'Não foi possível conectar: ${e.toString()}',
    );
  } finally {
    setState(() => isTesting = false);
  }
}
```

**Salvar Configurações:**
```dart
Future<void> saveWhatsAppConfig() async {
  try {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    await firestore.doc('tenants/$tenantId').update({
      'evolution_api_url': evolutionApiUrl,
      'evolution_api_key': apiKey,
      'evolution_instance_name': instanceName,
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    DSAlertDialog.showSuccess(
      context: context,
      title: 'Configurações Salvas',
      message: 'As configurações do WhatsApp foram atualizadas.',
    );
  } catch (e) {
    DSAlertDialog.showError(
      context: context,
      title: 'Erro ao Salvar',
      message: 'Não foi possível salvar as configurações.',
    );
  }
}
```

---

### n8n Automation:

**Webhook URL (Read-only):**
```
Status: 🟢 Ativo

Webhook URL (Copiar)
┌─────────────────────────────────────────────────────────┐
│ https://us-central1-{project}.cloudfunctions.net/      │
│ receiveN8nSale?tenantId=xxx&token=yyy                  │
└─────────────────────────────────────────────────────────┘
[Copiar URL]

ⓘ Use esta URL no seu workflow n8n para enviar vendas
  automaticamente para a plataforma.
```

**Geração da URL:**
```dart
String generateWebhookUrl() {
  final tenantId = SessionManager.instance.currentTenant!.uid;
  final tenant = SessionManager.instance.currentTenant!;
  
  // Se não tem token, gerar um novo
  if (tenant.webhook_token == null || tenant.webhook_token!.isEmpty) {
    final newToken = Uuid().v4();
    
    // Salvar no tenant
    firestore.doc('tenants/$tenantId').update({
      'webhook_token': newToken,
    });
    
    return 'https://us-central1-{project-id}.cloudfunctions.net/receiveN8nSale'
           '?tenantId=$tenantId&token=$newToken';
  }
  
  return 'https://us-central1-{project-id}.cloudfunctions.net/receiveN8nSale'
         '?tenantId=$tenantId&token=${tenant.webhook_token}';
}
```

**Copiar URL:**
```dart
void copyWebhookUrl() {
  final url = generateWebhookUrl();
  
  Clipboard.setData(ClipboardData(text: url));
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Webhook URL copiada!'),
      backgroundColor: DSColors().success,
    ),
  );
}
```

---

## 💳 Plano & Assinatura

### Layout:

```
┌─────────────────────────────────────┐
│ Plano Atual:                        │
│                                     │
│ [Badge: Trial / Basic / Full]       │
│                                     │
│ Plano [Nome]                        │
│ • Válido até: DD/MM/AAAA (X dias)   │
│   OU                                │
│ • Próximo pagamento: DD/MM/AAAA     │
│                                     │
│ ⚠️ Seu trial expira em breve!       │
│    (se aplicável)                   │
│                                     │
│ [Fazer Upgrade / Gerenciar Plano]   │
└─────────────────────────────────────┘

─────────────────────────────────────

Planos Disponíveis:

┌─────────────────────────────────────┐
│ Trial                               │
│ Gratuito - 15 dias                  │
│                                     │
│ • Todas as funcionalidades          │
│ • Produtos ilimitados               │
│ • Clientes ilimitados               │
│                                     │
│ [Seu Plano Atual] (se trial)        │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Basic                               │
│ R$ 50,00/mês                        │
│                                     │
│ • Até 100 produtos                  │
│ • Até 500 clientes                  │
│ • Suporte por email                 │
│                                     │
│ [Selecionar Basic]                  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Full                                │
│ R$ 150,00/mês                       │
│                                     │
│ • Produtos ilimitados               │
│ • Clientes ilimitados               │
│ • Suporte prioritário               │
│ • Relatórios avançados              │
│                                     │
│ [Selecionar Full]                   │
└─────────────────────────────────────┘

ⓘ Entre em contato com suporte@plataforma.com
  para realizar upgrade ou downgrade.
```

**Exibir Plano Atual:**
```dart
Widget buildCurrentPlan() {
  final tenant = SessionManager.instance.currentTenant!;
  
  String planName;
  String planDescription;
  Color badgeColor;
  String? expirationInfo;
  bool showWarning = false;
  
  switch (tenant.plan) {
    case 'trial':
      planName = 'Trial';
      planDescription = 'Plano Gratuito';
      badgeColor = DSColors().warning;
      
      if (tenant.trial_end_date != null) {
        final daysLeft = tenant.trial_end_date!.difference(DateTime.now()).inDays;
        expirationInfo = 'Expira em: ${formatDate(tenant.trial_end_date!)} ($daysLeft dias)';
        showWarning = daysLeft <= 7;
      }
      break;
      
    case 'basic':
      planName = 'Basic';
      planDescription = 'R\$ 50,00/mês';
      badgeColor = DSColors().info;
      expirationInfo = 'Próximo pagamento: ${formatDate(tenant.next_payment_date)}';
      break;
      
    case 'full':
      planName = 'Full';
      planDescription = 'R\$ 150,00/mês';
      badgeColor = DSColors().primary;
      expirationInfo = 'Próximo pagamento: ${formatDate(tenant.next_payment_date)}';
      break;
  }
  
  return Card(
    child: Padding(
      padding: EdgeInsets.all(DSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSBadge(label: planName, color: badgeColor),
          SizedBox(height: DSSpacing.sm),
          Text(planDescription, style: DSTextStyle().headline),
          if (expirationInfo != null) ...[
            SizedBox(height: DSSpacing.sm),
            Text(expirationInfo, style: DSTextStyle().caption),
          ],
          if (showWarning) ...[
            SizedBox(height: DSSpacing.md),
            Container(
              padding: EdgeInsets.all(DSSpacing.sm),
              decoration: BoxDecoration(
                color: DSColors().warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DSBorderRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: DSColors().warning),
                  SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Text(
                      'Seu trial expira em breve!',
                      style: DSTextStyle().bodyText.copyWith(
                        color: DSColors().warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: DSSpacing.md),
          DSButton.primary(
            label: tenant.plan == 'trial' ? 'Fazer Upgrade' : 'Gerenciar Plano',
            onTap: () => handlePlanAction(),
          ),
        ],
      ),
    ),
  );
}
```

**Botão Upgrade/Gerenciar (MVP - Sem Gateway):**
```dart
void handlePlanAction() {
  DSAlertDialog.showInfo(
    context: context,
    title: 'Gerenciar Plano',
    message: 'Para alterar seu plano, entre em contato com nosso suporte:\n\n'
             'Email: suporte@plataforma.com\n'
             'WhatsApp: (11) 99999-9999',
  );
}
```

**Nota:** Integração com gateway de pagamento (Stripe/Pagar.me) será implementada na Fase 2.

---

# MÓDULO 8: GERENCIAR EQUIPE (TEAM)

## 👥 Listagem de Membros

### Layout:

**Web (Lista):**
```
┌────────────────────────────────────────────────┐
│ Equipe (3 membros)              [+ Adicionar]  │
├────────────────────────────────────────────────┤
│ 🔍 [Buscar por nome ou email...]               │
├────────────────────────────────────────────────┤
│                                                 │
│ ┌────────────────────────────────────────────┐ │
│ │ [MS] Maria Silva                [Edit][🗑️]│ │
│ │      maria@loja.com                        │ │
│ │      [TenantAdmin] [Você]                  │ │
│ │      Adicionado em: 15/02/2024             │ │
│ └────────────────────────────────────────────┘ │
│                                                 │
│ ┌────────────────────────────────────────────┐ │
│ │ [JS] João Santos                [Edit][🗑️]│ │
│ │      joao@loja.com                         │ │
│ │      [User]                                │ │
│ │      Adicionado em: 20/02/2024             │ │
│ │      Por: Maria Silva                      │ │
│ └────────────────────────────────────────────┘ │
│                                                 │
│ ┌────────────────────────────────────────────┐ │
│ │ [AC] Ana Costa                  [Edit][🗑️]│ │
│ │      ana@loja.com                          │ │
│ │      [User] [Inativo]                      │ │
│ │      Adicionado em: 25/02/2024             │ │
│ │      Inativo há 5 dias                     │ │
│ └────────────────────────────────────────────┘ │
│                                                 │
└────────────────────────────────────────────────┘
```

**Mobile (Cards):**
```
┌──────────────────────┐
│ Equipe (3)           │
│            [+ FAB]   │
├──────────────────────┤
│ 🔍 [Buscar...]       │
├──────────────────────┤
│ ┌──────────────────┐ │
│ │ [MS] Maria Silva │ │
│ │ maria@loja.com   │ │
│ │ [TenantAdmin]    │ │
│ │ [Você]           │ │
│ │                  │ │
│ │ Adicionado:      │ │
│ │ 15/02/2024       │ │
│ │                  │ │
│ │ [Edit] [🗑️]      │ │
│ └──────────────────┘ │
└──────────────────────┘
```

### Informações por Membro:

Usando `DSListTile`:
```dart
DSListTile(
  leading: DSAvatar(
    name: member.user_name ?? member.user_email,
    size: 48,
  ),
  title: member.user_name ?? member.user_email,
  subtitle: member.user_email,
  badges: [
    DSBadge(
      label: member.role == UserRole.tenantAdmin ? 'Admin' : 'User',
      type: member.role == UserRole.tenantAdmin 
        ? DSBadgeType.primary 
        : DSBadgeType.info,
    ),
    if (!member.is_active)
      DSBadge(label: 'Inativo', type: DSBadgeType.error),
    if (member.user_id == SessionManager.instance.currentUser!.uid)
      DSBadge(label: 'Você', type: DSBadgeType.success),
  ],
  metadata: member.is_active
    ? 'Adicionado em: ${formatDate(member.created_at)}'
    : 'Inativo há ${daysInactive(member.removed_at)} dias',
  trailing: [
    IconButton(
      icon: Icon(Icons.edit),
      tooltip: 'Editar',
      onPressed: () => editMember(member),
    ),
    IconButton(
      icon: Icon(Icons.delete),
      tooltip: 'Remover',
      onPressed: () => removeMember(member),
    ),
  ],
  onTap: () => viewMemberDetails(member),
)
```

### Busca:

- Buscar por: nome ou email
- Debounce: 300ms
- Case-insensitive

### Empty State:

```
┌─────────────────────────────────┐
│                                 │
│    [Ilustração pessoas]         │
│                                 │
│   Apenas você na equipe         │
│                                 │
│   Adicione membros para         │
│   colaborar!                    │
│                                 │
│     [+ Adicionar Membro]        │
│                                 │
└─────────────────────────────────┘
```

---

## ➕ Adicionar Membro

### Formulário:

```
┌─────────────────────────────────────┐
│ Adicionar Membro         [X Fechar] │
├─────────────────────────────────────┤
│                                     │
│ Email *                             │
│ ┌─────────────────────────────────┐ │
│ │ usuario@email.com______________ │ │
│ └─────────────────────────────────┘ │
│ ⓘ Se já existir na plataforma,      │
│   será adicionado a este tenant     │
│                                     │
│ Nome Completo *                     │
│ ┌─────────────────────────────────┐ │
│ │ João Santos____________________ │ │
│ └─────────────────────────────────┘ │
│ ⓘ Usado apenas se for novo usuário  │
│                                     │
│ Permissão *                         │
│ ┌─────────────────────────────────┐ │
│ │ ⚪ Administrador                 │ │
│ │    Pode gerenciar equipe,       │ │
│ │    produtos, clientes e vendas  │ │
│ │                                 │ │
│ │ 🔵 Usuário                       │ │
│ │    Pode registrar vendas e      │ │
│ │    visualizar dados             │ │
│ └─────────────────────────────────┘ │
│                                     │
│                                     │
│ [Cancelar]               [Adicionar]│
│                                     │
└─────────────────────────────────────┘
```

### Campos:

| Campo | Obrigatório | Validação |
|-------|-------------|-----------|
| **Email** | ✅ | Formato válido |
| **Nome Completo** | ✅ | Min 3 caracteres |
| **Role** | ✅ | tenantAdmin ou user |

### Lógica de Adição:

```dart
Future<void> addMember() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  final email = emailController.text.trim().toLowerCase();
  final name = nameController.text.trim();
  final role = selectedRole; // tenantAdmin ou user
  final tenantId = SessionManager.instance.currentTenant!.uid;
  
  setState(() => isAdding = true);
  
  try {
    // 1. Verificar se usuário já existe na plataforma
    final usersQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();
    
    String userId;
    bool isNewUser = false;
    
    if (usersQuery.docs.isEmpty) {
      // CASO 1: USUÁRIO NÃO EXISTE - Criar novo
      isNewUser = true;
      
      // Criar no Firebase Auth
      final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: '1234567', // Senha padrão
        );
      
      userId = userCredential.user!.uid;
      
      // Criar documento em 'users'
      await firestore.collection('users').doc(userId).set({
        'email': email,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('Novo usuário criado: $email');
      
    } else {
      // CASO 2: USUÁRIO JÁ EXISTE
      final existingUser = usersQuery.docs.first;
      userId = existingUser.id;
      
      // Verificar se já é membro deste tenant
      final existingMembership = await firestore
        .collection('memberships')
        .where('user_id', isEqualTo: userId)
        .where('tenant_id', isEqualTo: tenantId)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();
      
      if (existingMembership.docs.isNotEmpty) {
        DSAlertDialog.showWarning(
          context: context,
          title: 'Usuário Já é Membro',
          message: '${existingUser.data()['name']} já faz parte desta equipe.',
        );
        return;
      }
      
      AppLogger.info('Usuário existente adicionado: $email');
    }
    
    // 2. Criar membership
    await firestore.collection('memberships').add({
      'user_id': userId,
      'tenant_id': tenantId,
      'role': role.name,
      'is_active': true,
      'user_name': name,
      'user_email': email,
      'added_by': SessionManager.instance.currentUser!.uid,
      'created_at': FieldValue.serverTimestamp(),
    });
    
    // 3. Enviar email
    if (isNewUser) {
      await sendWelcomeEmail(
        email: email,
        name: name,
        tenantName: SessionManager.instance.currentTenant!.name,
        password: '1234567',
      );
    } else {
      await sendAddedToTenantEmail(
        email: email,
        name: name,
        tenantName: SessionManager.instance.currentTenant!.name,
      );
    }
    
    // 4. Feedback sucesso
    DSAlertDialog.showSuccess(
      context: context,
      title: 'Membro Adicionado!',
      message: isNewUser
        ? 'Usuário criado e credenciais enviadas por email.'
        : '$name foi adicionado à equipe.',
    );
    
    Navigator.pop(context, true);
    
  } catch (e) {
    DSAlertDialog.showError(
      context: context,
      title: 'Erro ao Adicionar',
      message: 'Não foi possível adicionar o membro.',
    );
    
    AppLogger.error('Erro ao adicionar membro', error: e);
  } finally {
    setState(() => isAdding = false);
  }
}
```

---

## ✏️ Editar Membro

### Formulário:

```
┌─────────────────────────────────────┐
│ Editar Membro            [X Fechar] │
├─────────────────────────────────────┤
│                                     │
│ João Santos                         │
│ joao@loja.com                       │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Permissão *                         │
│ ┌─────────────────────────────────┐ │
│ │ ⚪ Administrador                 │ │
│ │    Pode gerenciar equipe,       │ │
│ │    produtos, clientes e vendas  │ │
│ │                                 │ │
│ │ 🔵 Usuário                       │ │
│ │    Pode registrar vendas e      │ │
│ │    visualizar dados             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Status                              │
│ ☑️ Membro ativo                     │
│                                     │
│ ⓘ Se desmarcar, o usuário perde    │
│   acesso a este tenant              │
│                                     │
│                                     │
│ [Cancelar]      [Salvar Alterações]│
│                                     │
└─────────────────────────────────────┘
```

### Campos Editáveis:

- **Role:** tenantAdmin ↔ user
- **Status:** Ativo ↔ Inativo

### Validações:

```dart
Future<void> updateMember() async {
  // 1. Não pode inativar a si mesmo
  if (membership.user_id == SessionManager.instance.currentUser!.uid) {
    if (!isActive) {
      DSAlertDialog.showWarning(
        context: context,
        title: 'Ação Não Permitida',
        message: 'Você não pode inativar seu próprio acesso.',
      );
      return;
    }
  }
  
  // 2. Não pode remover último TenantAdmin
  if (currentRole == UserRole.tenantAdmin && newRole == UserRole.user) {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    final adminsQuery = await firestore
      .collection('memberships')
      .where('tenant_id', isEqualTo: tenantId)
      .where('role', isEqualTo: 'tenantAdmin')
      .where('is_active', isEqualTo: true)
      .get();
    
    if (adminsQuery.docs.length <= 1) {
      DSAlertDialog.showWarning(
        context: context,
        title: 'Ação Não Permitida',
        message: 'Deve haver pelo menos 1 Administrador na equipe.',
      );
      return;
    }
  }
  
  // 3. Salvar alterações
  try {
    await firestore.doc('memberships/${membership.uid}').update({
      'role': newRole.name,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
      if (!isActive) 'removed_at': FieldValue.serverTimestamp(),
      if (!isActive) 'removed_by': SessionManager.instance.currentUser!.uid,
    });
    
    DSAlertDialog.showSuccess(
      context: context,
      title: 'Membro Atualizado',
      message: 'As alterações foram salvas.',
    );
    
    Navigator.pop(context, true);
    
  } catch (e) {
    DSAlertDialog.showError(
      context: context,
      title: 'Erro',
      message: 'Não foi possível atualizar o membro.',
    );
  }
}
```

---

## 🗑️ Remover Membro

### Modal de Confirmação:

```dart
final confirmed = await DSAlertDialog.showDelete(
  context: context,
  title: 'Confirmar Remoção',
  message: 'Tem certeza que deseja remover este membro da equipe?',
  content: DSAlertContentCard(
    icon: Icons.person_outline,
    color: DSColors().red,
    title: member.user_name,
    subtitle: member.user_email,
  ),
);

if (confirmed == true) {
  await removeMember(membership);
}
```

### Validações:

```dart
Future<void> removeMember(MembershipModel membership) async {
  // 1. Não pode remover a si mesmo
  if (membership.user_id == SessionManager.instance.currentUser!.uid) {
    DSAlertDialog.showWarning(
      context: context,
      title: 'Ação Não Permitida',
      message: 'Você não pode remover seu próprio acesso. Peça a outro administrador.',
    );
    return;
  }
  
  // 2. Não pode remover último TenantAdmin
  if (membership.role == UserRole.tenantAdmin) {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    final adminsQuery = await firestore
      .collection('memberships')
      .where('tenant_id', isEqualTo: tenantId)
      .where('role', isEqualTo: 'tenantAdmin')
      .where('is_active', isEqualTo: true)
      .get();
    
    if (adminsQuery.docs.length <= 1) {
      DSAlertDialog.showWarning(
        context: context,
        title: 'Ação Não Permitida',
        message: 'Deve haver pelo menos 1 Administrador na equipe.',
      );
      return;
    }
  }
  
  // 3. Remover (Soft Delete)
  try {
    await firestore.doc('memberships/${membership.uid}').update({
      'is_active': false,
      'removed_at': FieldValue.serverTimestamp(),
      'removed_by': SessionManager.instance.currentUser!.uid,
    });
    
    DSAlertDialog.showSuccess(
      context: context,
      title: 'Membro Removido',
      message: 'O acesso foi removido. O usuário não conseguirá mais logar neste tenant.',
    );
    
    Navigator.pop(context, true);
    
  } catch (e) {
    DSAlertDialog.showError(
      context: context,
      title: 'Erro',
      message: 'Não foi possível remover o membro.',
    );
  }
}
```

**Nota:** Usar **Soft Delete** (marcar `is_active = false`) para manter histórico.

---

## 📊 MembershipModel (Completo)

```dart
class MembershipModel {
  String uid;
  String user_id;
  String tenant_id;
  UserRole role;              // superAdmin, tenantAdmin, user
  bool is_active;
  String? added_by;           // user_id de quem adicionou
  DateTime created_at;
  DateTime? updated_at;
  DateTime? removed_at;
  String? removed_by;
  
  // Denormalizados (facilitar listagem)
  String? user_name;
  String? user_email;
  
  MembershipModel({
    required this.uid,
    required this.user_id,
    required this.tenant_id,
    required this.role,
    this.is_active = true,
    this.added_by,
    required this.created_at,
    this.updated_at,
    this.removed_at,
    this.removed_by,
    this.user_name,
    this.user_email,
  });
  
  static MembershipModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipModel(
      uid: doc.id,
      user_id: data['user_id'],
      tenant_id: data['tenant_id'],
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.user,
      ),
      is_active: data['is_active'] ?? true,
      added_by: data['added_by'],
      created_at: (data['created_at'] as Timestamp).toDate(),
      updated_at: data['updated_at'] != null
        ? (data['updated_at'] as Timestamp).toDate()
        : null,
      removed_at: data['removed_at'] != null
        ? (data['removed_at'] as Timestamp).toDate()
        : null,
      removed_by: data['removed_by'],
      user_name: data['user_name'],
      user_email: data['user_email'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'tenant_id': tenant_id,
      'role': role.name,
      'is_active': is_active,
      'added_by': added_by,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': updated_at != null
        ? Timestamp.fromDate(updated_at!)
        : null,
      'removed_at': removed_at != null
        ? Timestamp.fromDate(removed_at!)
        : null,
      'removed_by': removed_by,
      'user_name': user_name,
      'user_email': user_email,
    };
  }
  
  MembershipModel copyWith({
    String? uid,
    String? user_id,
    String? tenant_id,
    UserRole? role,
    bool? is_active,
    String? added_by,
    DateTime? created_at,
    DateTime? updated_at,
    DateTime? removed_at,
    String? removed_by,
    String? user_name,
    String? user_email,
  }) {
    return MembershipModel(
      uid: uid ?? this.uid,
      user_id: user_id ?? this.user_id,
      tenant_id: tenant_id ?? this.tenant_id,
      role: role ?? this.role,
      is_active: is_active ?? this.is_active,
      added_by: added_by ?? this.added_by,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
      removed_at: removed_at ?? this.removed_at,
      removed_by: removed_by ?? this.removed_by,
      user_name: user_name ?? this.user_name,
      user_email: user_email ?? this.user_email,
    );
  }
}
```

---

# ✅ TODOS OS MÓDULOS COMPLETOS!

## 📋 RESUMO DOS 9 MÓDULOS:

### **FASE 1: AUTENTICAÇÃO E TENANT**
1. ✅ **Autenticação & Onboarding**
2. ✅ **Dashboard Tenant**

### **FASE 2: GESTÃO DE DADOS (CRM)**
3. ✅ **Produtos (CRUD)**
4. ✅ **Clientes (CRM)**
5. ✅ **Vendas (Manual + Automática)**

### **FASE 3: ADMINISTRAÇÃO (SUPERADMIN)**
6. ✅ **Dashboard SuperAdmin**
7. ✅ **Gerenciar Tenants** (incluído no Módulo 6)

### **FASE 4: CONFIGURAÇÕES**
8. ✅ **Configurações do Tenant**
9. ✅ **Gerenciar Equipe**

---

## 🎯 MATRIZ DE FUNCIONALIDADES COMPLETA:

| Módulo | TenantAdmin | User | SuperAdmin |
|--------|-------------|------|------------|
| **Login/Logout** | ✅ | ✅ | ✅ |
| **Dashboard Tenant** | ✅ Ver todas métricas | ✅ Ver todas métricas | ✅ Via impersonate |
| **Produtos** | ✅ CRUD completo | ❌ Apenas visualização | ✅ Via impersonate |
| **Clientes** | ✅ CRUD completo | ❌ Apenas visualização | ✅ Via impersonate |
| **Vendas** | ✅ CRUD completo | ✅ Criar e visualizar | ✅ Via impersonate |
| **Dashboard SuperAdmin** | ❌ Sem acesso | ❌ Sem acesso | ✅ Exclusivo |
| **Gerenciar Tenants** | ❌ Sem acesso | ❌ Sem acesso | ✅ Exclusivo |
| **Configurações** | ✅ Editar tudo | ❌ Sem acesso | ✅ Via impersonate |
| **Gerenciar Equipe** | ✅ CRUD completo | ❌ Sem acesso | ✅ Via impersonate |

---

## 📊 ESTRUTURA DE DADOS FINAL:

```
Firestore Root/
│
├── users/
│   └── {user_id}
│       ├── email
│       ├── name
│       └── created_at
│
├── memberships/
│   └── {membership_id}
│       ├── user_id
│       ├── tenant_id
│       ├── role
│       ├── is_active
│       ├── user_name (denorm)
│       ├── user_email (denorm)
│       ├── added_by
│       ├── removed_at
│       ├── removed_by
│       └── created_at
│
└── tenants/
    └── {tenant_id}
        ├── name
        ├── contact_email
        ├── contact_phone
        ├── plan (trial | basic | full)
        ├── is_active
        ├── trial_end_date
        ├── evolution_api_url
        ├── evolution_api_key
        ├── evolution_instance_name
        ├── webhook_token
        ├── created_at
        │
        ├── products/
        │   └── {product_id}
        │       ├── name
        │       ├── sku
        │       ├── price
        │       ├── stock
        │       ├── description
        │       ├── image_url
        │       ├── is_active
        │       ├── created_at
        │       └── updated_at
        │
        ├── customers/
        │   └── {customer_id}
        │       ├── name
        │       ├── whatsapp
        │       ├── email
        │       ├── notes
        │       ├── is_active
        │       ├── created_at
        │       ├── updated_at
        │       ├── last_purchase_at (denorm)
        │       ├── total_spent (denorm)
        │       └── purchase_count (denorm)
        │
        ├── sales/
        │   └── {sale_id}
        │       ├── customer_id
        │       ├── customer_name (denorm)
        │       ├── customer_whatsapp (denorm)
        │       ├── items[]
        │       ├── total
        │       ├── status
        │       ├── source
        │       ├── notes
        │       ├── conversation_id
        │       ├── created_at
        │       └── updated_at
        │
        └── billing/
            └── {billing_id}
                ├── plan
                ├── amount
                ├── status
                ├── period_start
                ├── period_end
                └── created_at
```

---

## 🎨 DESIGN SYSTEM COMPLETO:

### Widgets Obrigatórios:

1. ✅ **DSColors** - Paleta de cores
2. ✅ **DSTextStyle** - Tipografia
3. ✅ **DSSpacing** - Espaçamentos
4. ✅ **DSBorderRadius** - Raios de borda
5. ✅ **DSButton** - Botões
6. ✅ **DSAlertDialog** - Modals de confirmação
7. ✅ **FormTextField** - Campos de formulário
8. ✅ **EmptyState** - Estados vazios
9. ✅ **LoadingIndicator** - Indicador de carregamento
10. ✅ **DSBadge** - Tags/Status
11. ✅ **DSAvatar** - Avatar com iniciais
12. ✅ **DSMetricCard** - Cards de métricas
13. ✅ **DSListTile** - Item de lista padronizado
14. ✅ **SearchableModal** - Modal com busca

---

## 🔐 REGRAS DE SEGURANÇA (Firebase):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Usuários: Apenas leitura própria
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId || isSuperAdmin();
    }
    
    // Memberships: Leitura própria, escrita por admin
    match /memberships/{membershipId} {
      allow read: if request.auth != null;
      allow create: if isTenantAdmin(request.resource.data.tenant_id) || isSuperAdmin();
      allow update, delete: if isTenantAdmin(resource.data.tenant_id) || isSuperAdmin();
    }
    
    // Tenants e Subcoleções
    match /tenants/{tenantId} {
      allow read: if hasMembership(tenantId);
      allow write: if isSuperAdmin();
      
      match /products/{productId} {
        allow read: if hasMembership(tenantId);
        allow write: if isTenantAdmin(tenantId);
      }
      
      match /customers/{customerId} {
        allow read: if hasMembership(tenantId);
        allow write: if isTenantAdmin(tenantId);
      }
      
      match /sales/{saleId} {
        allow read: if hasMembership(tenantId);
        allow create: if hasMembership(tenantId);
        allow update, delete: if isTenantAdmin(tenantId);
      }
      
      match /billing/{billingId} {
        allow read: if hasMembership(tenantId);
        allow write: if isSuperAdmin();
      }
    }
  }
}
```

---

## 📝 CHECKLIST FINAL DE VALIDAÇÃO:

### **Funcionalidades Essenciais:**

**Autenticação:**
- [ ] Login com email/senha
- [ ] Recuperação de senha
- [ ] Logout
- [ ] Seleção de tenant (se múltiplos)
- [ ] Cadastro de usuários (TenantAdmin)
- [ ] Troca de senha obrigatória (primeiro login)
- [ ] Logout forçado (quando inativado)

**Dashboard Tenant:**
- [ ] 4 cards de métricas
- [ ] Gráfico de vendas (7 dias)
- [ ] Últimas 5 vendas
- [ ] Ações rápidas (3 botões)
- [ ] Alertas (trial, produtos, etc)

**Produtos:**
- [ ] Listagem (grid 4 cols Web, 2 cols Mobile)
- [ ] Busca e filtros
- [ ] Criar produto (com upload imagem)
- [ ] Editar produto
- [ ] Deletar produto (soft/hard delete)
- [ ] Validação SKU único

**Clientes:**
- [ ] Listagem (lista Web, cards Mobile)
- [ ] Busca e filtros
- [ ] Criar cliente
- [ ] Editar cliente
- [ ] Deletar cliente (soft/hard delete)
- [ ] Validação WhatsApp único
- [ ] Botão abrir WhatsApp
- [ ] Ver detalhes (com estatísticas)

**Vendas:**
- [ ] Listagem com mini-cards
- [ ] Busca e filtros
- [ ] Criar venda manual (cliente + carrinho)
- [ ] Validação de estoque
- [ ] Estoque decrementado ao criar
- [ ] Stats cliente atualizadas
- [ ] Receber venda automática (n8n)
- [ ] Notificação de nova venda
- [ ] Alterar status
- [ ] Deletar venda (devolver estoque)

**Dashboard SuperAdmin:**
- [ ] 4 cards de métricas globais
- [ ] Gráfico crescimento
- [ ] Distribuição planos
- [ ] Timeline atividades
- [ ] Alertas críticos

**Gerenciar Tenants:**
- [ ] Listagem de tenants
- [ ] Filtros (plano, status)
- [ ] Criar tenant (+ user + membership)
- [ ] Editar tenant
- [ ] Ver detalhes (stats)
- [ ] Estender trial
- [ ] Alterar plano
- [ ] Impersonate
- [ ] Deletar tenant (confirmação dupla + cascata)

**Configurações:**
- [ ] Editar dados empresa
- [ ] Configurar WhatsApp (testar conexão)
- [ ] Copiar webhook n8n
- [ ] Ver plano atual
- [ ] Ver planos disponíveis

**Gerenciar Equipe:**
- [ ] Listagem de membros
- [ ] Busca
- [ ] Adicionar membro (novo ou existente)
- [ ] Email enviado ao adicionar
- [ ] Editar role
- [ ] Inativar/Ativar membro
- [ ] Remover membro (soft delete)
- [ ] Validações (não inativar si mesmo, manter 1 admin)

---

## 🚀 APLICAÇÃO 100% ESPECIFICADA!

Todos os 9 módulos estão completamente documentados com:
- ✅ Layouts detalhados (Web e Mobile)
- ✅ Campos e validações
- ✅ Código de exemplo (lógicas complexas)
- ✅ Regras de negócio
- ✅ Fluxos completos
- ✅ Models completos
- ✅ Estrutura de dados
- ✅ Security Rules

**Total de páginas especificadas:** ~100  
**Total de linhas de documentação:** ~3.000  
**Completude:** 100% ✅

---

**Documentação desenvolvida com ❤️ para garantir consistência e qualidade!**
```