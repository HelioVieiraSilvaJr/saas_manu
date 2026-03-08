# Guia de Arquitetura e Padrões

Este documento descreve os padrões de arquitetura e organização do projeto: um SaaS Multi-tenant de CRM + Vendas Automatizadas via WhatsApp, desenvolvido em Flutter com suporte para plataformas Web e Mobile.

---

## 📁 Estrutura de Pastas

```
lib/
├── main.dart                    # Entry point principal
├── main_development.dart        # Entry point para ambiente de desenvolvimento
├── main_homolog.dart            # Entry point para ambiente de homologação
├── main_production.dart         # Entry point para ambiente de produção
├── firebase_options.dart        # Configurações do Firebase
├── Commons/                     # Componentes reutilizáveis
│   ├── Enums/                   # Enumerações do projeto
│   ├── Extensions/              # Extensions de tipos (String, Int, etc.)
│   ├── Models/                  # Modelos de dados
│   ├── PDFModels/               # Modelos para geração de PDFs
│   ├── Utils/                   # Utilitários gerais
│   └── Widgets/                 # Widgets reutilizáveis
│       └── DesignSystem/        # Arquivos e componentes de DesignSystem
├── Scenes/                      # Telas/Features do aplicativo
└── Sources/                     # Fontes de dados e gerenciamento
    ├── Coordinators/            # Coordenadores de navegação
    ├── Network.dart             # Configuração de rede
    ├── SessionManager.dart      # Gerenciamento de sessão
    └── PreferencesManager.dart  # Persistência local
```

---

## 🏢 Multi-Tenancy

Este é um SaaS Multi-tenant onde cada organização (tenant) possui seus próprios dados isolados.

### Isolamento de Dados

**ARQUITETURA ESCOLHIDA: NESTED COLLECTIONS (Subcoleções)**

Usamos **subcoleções** dentro de cada tenant para isolamento natural de dados. Esta abordagem oferece:
- ✅ Isolamento automático por tenant (sem WHERE clause)
- ✅ Security Rules mais simples e seguras
- ✅ Queries mais rápidas (path direto)
- ✅ Sem impacto no limite de 1MB por documento (subcoleções são independentes)

**Coleções Globais (não pertencem a tenant):**
- `users/` - Usuários podem pertencer a múltiplos tenants
- `tenants/` - Coleção raiz de organizações
- `memberships/` - Relaciona users ↔ tenants

### Estrutura de Coleções Firestore (NESTED)

```
Firestore Root/
│
├── users/                          # Usuários do sistema
│   └── {user_id}
│       ├── email
│       ├── name
│       └── created_at
│
├── memberships/                    # Relação user ↔ tenant
│   └── {membership_id}
│       ├── user_id
│       ├── tenant_id
│       ├── role (superAdmin | tenantAdmin | user)
│       ├── is_active
│       ├── user_name (denormalizado)
│       ├── user_email (denormalizado)
│       └── created_at
│
└── tenants/                        # Organizações/Empresas
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
        ├── products/               # SUBCOLEÇÃO (dados do tenant)
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
        ├── customers/              # SUBCOLEÇÃO (dados do tenant)
        │   └── {customer_id}
        │       ├── name
        │       ├── whatsapp
        │       ├── email
        │       ├── notes
        │       ├── is_active
        │       ├── created_at
        │       ├── updated_at
        │       ├── last_purchase_at (denormalizado)
        │       ├── total_spent (denormalizado)
        │       └── purchase_count (denormalizado)
        │
        ├── sales/                  # SUBCOLEÇÃO (dados do tenant)
        │   └── {sale_id}
        │       ├── customer_id
        │       ├── customer_name (denormalizado)
        │       ├── customer_whatsapp (denormalizado)
        │       ├── items[]
        │       │   ├── product_id
        │       │   ├── product_name
        │       │   ├── quantity
        │       │   ├── unit_price
        │       │   └── subtotal
        │       ├── total
        │       ├── status (pending | confirmed | cancelled)
        │       ├── source (manual | whatsapp_automation)
        │       ├── notes
        │       ├── conversation_id
        │       ├── created_at
        │       └── updated_at
        │
        ├── conversations/          # SUBCOLEÇÃO (dados do tenant)
        │   └── {conversation_id}
        │       ├── customer_id
        │       ├── customer_name
        │       ├── customer_whatsapp
        │       ├── messages[]
        │       ├── status
        │       ├── last_message_at
        │       └── created_at
        │
        └── billing/                # SUBCOLEÇÃO (dados do tenant)
            └── {billing_id}
                ├── plan
                ├── amount
                ├── status
                ├── period_start
                ├── period_end
                └── created_at
```

**IMPORTANTE:** Como usamos subcoleções, **NÃO há campo `tenant_id`** dentro dos documentos de `products`, `customers`, `sales`, etc. O isolamento vem do **path** da coleção.

### SessionManager (Atualizado)

Singleton para gerenciamento de sessão multi-tenant:

```dart
class SessionManager {
  static SessionManager instance = SessionManager._();
  
  UserModel? currentUser;           // Usuário logado
  TenantModel? currentTenant;       // Tenant ativo
  MembershipModel? currentMembership; // Membership atual (role + tenant)
  
  // Verificar sessão ativa
  bool hasSession() => currentUser != null;
  
  // Trocar de tenant (quando user pertence a múltiplos)
  Future<void> switchTenant(String tenantId) async {
    // Carregar tenant e membership
    // Atualizar currentTenant e currentMembership
  }
  
  // Encerrar sessão
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    currentUser = null;
    currentTenant = null;
    currentMembership = null;
    // Limpar caches...
  }
}
```

### Repository Pattern (NESTED Collections)

**IMPORTANTE:** Repositories usam o **path completo** com tenant_id, sem necessidade de cláusula WHERE:

```dart
class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Buscar todos os produtos do tenant atual
  Future<List<ProductModel>> getAll() async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    // Path direto: tenants/{tenant_id}/products
    final snapshot = await _firestore
      .collection('tenants/$tenantId/products')
      .where('is_active', isEqualTo: true)
      .orderBy('created_at', descending: true)
      .get();
    
    return snapshot.docs
      .map((doc) => ProductModel.fromDocumentSnapshot(doc))
      .toList();
  }
  
  // Buscar produto por ID
  Future<ProductModel?> getById(String productId) async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    final doc = await _firestore
      .doc('tenants/$tenantId/products/$productId')
      .get();
    
    if (!doc.exists) return null;
    return ProductModel.fromDocumentSnapshot(doc);
  }
  
  // Criar produto (tenant_id está no path)
  Future<String> create(ProductModel product) async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    final docRef = await _firestore
      .collection('tenants/$tenantId/products')
      .add(product.toMap());
    
    return docRef.id;
  }
  
  // Atualizar produto
  Future<void> update(ProductModel product) async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    await _firestore
      .doc('tenants/$tenantId/products/${product.uid}')
      .update(product.toMap());
  }
  
  // Deletar produto
  Future<void> delete(String productId) async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    await _firestore
      .doc('tenants/$tenantId/products/$productId')
      .delete();
  }
  
  // Stream para mudanças em tempo real
  Stream<List<ProductModel>> watchAll() {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    return _firestore
      .collection('tenants/$tenantId/products')
      .where('is_active', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductModel.fromDocumentSnapshot(doc))
          .toList());
  }
}
```

**Vantagens da Estrutura NESTED:**
1. ✅ Isolamento automático (path já contém tenant_id)
2. ✅ Queries mais simples (sem WHERE tenant_id)
3. ✅ Security Rules mais diretas
4. ✅ Melhor performance (índice menor)

**Exemplo de Security Rules:**
```javascript
match /tenants/{tenantId}/products/{productId} {
  allow read, write: if request.auth != null && 
    exists(/databases/$(database)/documents/memberships/$(getMembership(request.auth.uid, tenantId)));
}
```

**Exceção - SuperAdmin:**
SuperAdmin pode acessar dados cross-tenant usando `collectionGroup`:

```dart
// SuperAdmin: Buscar produtos de TODOS os tenants
Future<List<ProductModel>> getAllProductsGlobal() async {
  if (!SessionManager.instance.isSuperAdmin) {
    throw Exception('Acesso negado');
  }
  
  final snapshot = await _firestore
    .collectionGroup('products')
    .get();
  
  return snapshot.docs
    .map((doc) => ProductModel.fromDocumentSnapshot(doc))
    .toList();
}
```

---

## 🔐 Sistema de Roles e Permissões

### Enum de Roles

```dart
enum UserRole {
  superAdmin,   // Acesso global, gerencia tenants e billing
  tenantAdmin,  // Administra seu próprio tenant, convida usuários
  user          // Usuário padrão do tenant
}
```

### MembershipModel

Representa a relação usuário ↔ tenant com role:

```dart
class MembershipModel {
  String uid;
  String user_id;
  String tenant_id;
  UserRole role;
  DateTime created_at;
  bool is_active;
  
  // Factory para Firestore
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
      created_at: (data['created_at'] as Timestamp).toDate(),
      is_active: data['is_active'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'tenant_id': tenant_id,
      'role': role.name,
      'created_at': Timestamp.fromDate(created_at),
      'is_active': is_active,
    };
  }
}
```

### Verificação de Permissões

Extension no SessionManager para facilitar verificações:

```dart
extension SessionPermissions on SessionManager {
  bool get isSuperAdmin => 
    currentMembership?.role == UserRole.superAdmin;
  
  bool get isTenantAdmin => 
    currentMembership?.role == UserRole.tenantAdmin;
  
  bool get isUser => 
    currentMembership?.role == UserRole.user;
  
  // Verificar se pode gerenciar tenant
  bool canManageTenant() => isSuperAdmin || isTenantAdmin;
  
  // Verificar se pode gerenciar billing
  bool canManageBilling() => isSuperAdmin;
  
  // Verificar se pode convidar usuários
  bool canInviteUsers() => isSuperAdmin || isTenantAdmin;
}
```

### Guards (Middleware de Navegação)

Criar guards para proteger rotas:

```dart
// SuperAdminGuard - Apenas SuperAdmin
class SuperAdminGuard {
  static bool canAccess() {
    return SessionManager.instance.isSuperAdmin;
  }
}

// TenantAdminGuard - TenantAdmin ou superior
class TenantAdminGuard {
  static bool canAccess() {
    return SessionManager.instance.canManageTenant();
  }
}

// AuthGuard - Qualquer usuário autenticado
class AuthGuard {
  static bool canAccess() {
    return SessionManager.instance.hasSession();
  }
}

// Uso em Coordinators
void navigateToTenantSettings(BuildContext context) {
  if (!TenantAdminGuard.canAccess()) {
    DSAlertDialog.showWarning(
      context: context,
      title: 'Acesso Negado',
      message: 'Você não tem permissão para acessar esta área.',
    );
    return;
  }
  
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => TenantSettingsPage(),
  ));
}
```

---

## 🏗️ Arquitetura - MVP (Model-View-Presenter)

O projeto utiliza uma variação do padrão **MVP** com elementos de **MVVM**, organizando cada feature/cena em componentes com responsabilidades bem definidas.

### Componentes de uma Scene (Feature)

```
Scenes/
└── [NomeDaFeature]/
    ├── [NomeDaFeature]Page.dart         # Widget principal (View)
    ├── [NomeDaFeature]Presenter.dart    # Presenter (Lógica de UI)
    ├── [NomeDaFeature]ViewModel.dart    # ViewModel (Lógica de negócio)
    ├── [NomeDaFeature]Repository.dart   # Repository (Acesso a dados)
    ├── [NomeDaFeature]Service.dart      # Service (APIs externas) [OPCIONAL]
    ├── [NomeDaFeature]Coordinator.dart  # Coordinator (Navegação) [OPCIONAL]
    ├── Mobile/                          # Views Mobile específicas
    │   └── [NomeDaFeature]MobileView.dart
    ├── Web/                             # Views Web específicas
    │   └── [NomeDaFeature]WebView.dart
    └── Widgets/                         # Sub Widgets específicos da Feature
```

### Responsabilidades

| Componente | Responsabilidade |
|------------|------------------|
| **Page** | Widget principal que inicializa o Presenter e renderiza a View responsiva |
| **Presenter** | Gerencia estado da UI (Riverpod), binds com callbacks do ViewModel |
| **ViewModel** | Contém lógica de negócio, validações, transformações de dados |
| **Repository** | Provê dados diretamente do Firestore, filtra por tenant_id |
| **Service** | Faz chamadas à APIs externas e integrações (n8n, WhatsApp) |
| **Coordinator** | Gerencia a navegação entre telas da feature |
| **MobileView / WebView** | Views específicas para cada plataforma |

---

## 📦 Models do Negócio

### Core Models (Multi-Tenancy)

#### UserModel
```dart
class UserModel {
  String uid;
  String email;
  String name;
  String? photo_url;
  DateTime created_at;
  
  static UserModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
  static UserModel newModel() { ... }
  UserModel.copy(UserModel original) { ... }
}
```

#### TenantModel
```dart
class TenantModel {
  String uid;
  String name;
  String plan; // 'trial' | 'basic' | 'full'
  bool is_active;
  DateTime created_at;
  DateTime? trial_end_date;
  
  static TenantModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
  static TenantModel newModel() { ... }
  TenantModel.copy(TenantModel original) { ... }
}
```

#### MembershipModel
```dart
class MembershipModel {
  String uid;
  String user_id;
  String tenant_id;
  UserRole role;
  DateTime created_at;
  bool is_active;
  
  static MembershipModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

#### BillingModel
```dart
class BillingModel {
  String uid;
  String tenant_id;
  String plan;
  double amount;
  String status; // 'pending' | 'paid' | 'overdue'
  DateTime period_start;
  DateTime period_end;
  DateTime? paid_at;
  
  static BillingModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

---

### CRM Models

#### ProductModel
```dart
class ProductModel {
  String uid;
  String tenant_id;        // ⚠️ OBRIGATÓRIO
  String name;
  String description;
  double price;
  String? image_url;
  bool is_active;
  DateTime created_at;
  
  static ProductModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
  static ProductModel newModel() { ... }
  ProductModel.copy(ProductModel original) { ... }
}
```

#### CustomerModel
```dart
class CustomerModel {
  String uid;
  String tenant_id;        // ⚠️ OBRIGATÓRIO
  String name;
  String phone;
  String whatsapp;
  String? email;
  DateTime created_at;
  DateTime? last_interaction;
  
  static CustomerModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
  static CustomerModel newModel() { ... }
  CustomerModel.copy(CustomerModel original) { ... }
}
```

#### SaleModel
```dart
class SaleModel {
  String uid;
  String tenant_id;        // ⚠️ OBRIGATÓRIO
  String customer_id;
  List<String> product_ids;
  double total;
  String status; // 'pending' | 'confirmed' | 'cancelled'
  String source; // 'manual' | 'whatsapp_automation'
  DateTime created_at;
  
  static SaleModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
  static SaleModel newModel() { ... }
  SaleModel.copy(SaleModel original) { ... }
}
```

#### ConversationModel
```dart
class ConversationModel {
  String uid;
  String tenant_id;        // ⚠️ OBRIGATÓRIO
  String customer_id;
  List<MessageModel> messages;
  String status; // 'active' | 'closed'
  DateTime created_at;
  DateTime? last_message_at;
  
  static ConversationModel fromDocumentSnapshot(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toMap() { ... }
}

class MessageModel {
  String content;
  String sender; // 'customer' | 'bot' | 'agent'
  DateTime timestamp;
}
```

---

## 🔌 Integrações Externas

### n8n Automation (Agente de IA + WhatsApp)

O sistema utiliza **n8n** como plataforma de automação para atendimento via WhatsApp com agente de IA.

#### Fluxo de Vendas Automatizadas

```
1. Cliente envia mensagem no WhatsApp
   ↓
2. n8n recebe webhook do WhatsApp Business API
   ↓
3. Agente de IA (OpenAI/Claude) processa mensagem
   ↓
4. Agente apresenta catálogo de produtos (busca no Firestore)
   ↓
5. Cliente monta carrinho e confirma pedido
   ↓
6. n8n cria registro de venda DIRETAMENTE no Firestore
   (collection: sales, com tenant_id)
   ↓
7. Plataforma Flutter DETECTA nova venda via Stream
   ↓
8. UI atualiza automaticamente + Notifica TenantAdmin
```

#### Implementação - Stream/Listener

**SalesRepository:**
```dart
class SalesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream para observar vendas em real-time
  Stream<List<SaleModel>> watchSales() {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    return _firestore
      .collection('sales')
      .where('tenant_id', isEqualTo: tenantId)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SaleModel.fromDocumentSnapshot(doc))
          .toList());
  }
  
  // Escutar apenas novas vendas (últimos 5 minutos)
  Stream<List<SaleModel>> watchNewSales() {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
    
    return _firestore
      .collection('sales')
      .where('tenant_id', isEqualTo: tenantId)
      .where('created_at', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SaleModel.fromDocumentSnapshot(doc))
          .toList());
  }
}
```

**SalesViewModel:**
```dart
class SalesViewModel {
  final SalesRepository repository = SalesRepository();
  
  Stream<List<SaleModel>> watchSales() => repository.watchSales();
  
  Stream<List<SaleModel>> watchNewSales() => repository.watchNewSales();
}
```

**SalesPresenter:**
```dart
class SalesPresenter extends ChangeNotifier {
  final SalesViewModel viewModel = SalesViewModel();
  
  // Stream para a View
  Stream<List<SaleModel>> get salesStream => viewModel.watchSales();
  
  // Listener para notificar novas vendas
  StreamSubscription? _newSalesSubscription;
  
  void setupNewSalesListener(BuildContext context) {
    _newSalesSubscription = viewModel.watchNewSales().listen((newSales) {
      if (newSales.isNotEmpty) {
        // Mostrar notificação elegante
        ElegantNotification.success(
          title: "Nova Venda!",
          description: "Você tem ${newSales.length} nova(s) venda(s).",
        ).show(context);
      }
    });
  }
  
  @override
  void dispose() {
    _newSalesSubscription?.cancel();
    super.dispose();
  }
}
```

**SalesMobileView:**
```dart
class SalesMobileView extends StatelessWidget {
  final SalesPresenter presenter;
  
  @override
  Widget build(BuildContext context) {
    // Iniciar listener de novas vendas
    presenter.setupNewSalesListener(context);
    
    return StreamBuilder<List<SaleModel>>(
      stream: presenter.salesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingIndicator();
        }
        
        if (snapshot.hasError) {
          return ErrorState(message: 'Erro ao carregar vendas');
        }
        
        final sales = snapshot.data ?? [];
        
        if (sales.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Nenhuma venda registrada',
            message: 'As vendas aparecerão aqui automaticamente.',
          );
        }
        
        return ListView.builder(
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return SaleCard(sale: sale);
          },
        );
      },
    );
  }
}
```

#### WhatsApp Business API Integration

Service para integração (se necessário enviar mensagens da plataforma):

```dart
class WhatsAppService {
  final String baseUrl = 'https://api.whatsapp.com/v1';
  
  Future<void> sendMessage(String phone, String message) async {
    // Implementar chamada à API do WhatsApp Business
  }
  
  Future<void> notifyNewSale(SaleModel sale) async {
    // Notificar cliente sobre confirmação de pedido
  }
}
```

---

## 🛣️ Navegação

### Estrutura de Rotas Multi-Tenant

```
/login                          # Autenticação
/select-tenant                  # Seletor de tenant (se user pertence a múltiplos)

/super-admin/                   # Dashboard SuperAdmin
  ├── /tenants                  # Gerenciar tenants
  ├── /billing                  # Gerenciar planos e pagamentos
  └── /support                  # Suporte administrativo

/tenant/[tenant_id]/            # Dashboard do Tenant
  ├── /dashboard                # Home do tenant
  ├── /products                 # Catálogo de produtos
  ├── /customers                # CRM - Clientes
  ├── /sales                    # Vendas (real-time via Stream)
  ├── /conversations            # Histórico WhatsApp
  ├── /settings                 # Configurações do tenant
  └── /team                     # Gerenciar usuários (TenantAdmin only)
```

### Navegação por Plataforma

**Mobile (iOS/Android):**
- Usar navegação **Push/Pop** nativa do Flutter
- Stack navigation pattern
- Transições nativas de cada plataforma

```dart
// Push para nova tela
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProductDetailPage(product)),
);

// Pop (voltar)
Navigator.pop(context);

// Pop com resultado
Navigator.pop(context, result);
```

**Web:**
- Pode usar rotas nomeadas ou tabs
- Deep linking habilitado
- URLs amigáveis

```dart
Navigator.pushNamed(context, '/tenant/${tenantId}/products');
```

### Coordinators

Coordinators abstraem a lógica de navegação por plataforma:

```dart
class ProductCoordinator {
  // Navegar para detalhes do produto
  void navigateToDetail(BuildContext context, ProductModel product) {
    if (kIsWeb) {
      // Web: usar rota nomeada
      Navigator.pushNamed(
        context, 
        '/tenant/${SessionManager.instance.currentTenant!.uid}/product/${product.uid}'
      );
    } else {
      // Mobile: push direto
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product)),
      );
    }
  }
  
  // Navegar para criar produto
  void navigateToCreate(BuildContext context) {
    // Verificar permissão
    if (!SessionManager.instance.canManageTenant()) {
      DSAlertDialog.showWarning(
        context: context,
        title: 'Acesso Negado',
        message: 'Você não tem permissão para criar produtos.',
      );
      return;
    }
    
    if (kIsWeb) {
      Navigator.pushNamed(context, '/tenant/${SessionManager.instance.currentTenant!.uid}/product/new');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductFormPage()),
      );
    }
  }
  
  // Voltar para lista
  void navigateBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }
}
```

---

## 📱 Responsividade

O projeto utiliza o componente `ScreenResponsive` para renderizar views diferentes conforme a largura da tela:

```dart
// Exemplo de uso no Page
class ProductListPage extends StatelessWidget {
  final presenter = ProductListPresenter();
  
  @override
  Widget build(BuildContext context) {
    presenter.context = context;
    return ScreenResponsive(
      mobile: ProductListMobileView(presenter),
      web: ProductListWebView(presenter),
    );
  }
}
```

**Breakpoints:**
- `>= 1000px` → Web
- `< 1000px` → Mobile

---

## 🔄 Gerenciamento de Estado

O projeto utiliza **Riverpod** para gerenciamento de estado reativo.

---

## 🎨 Design System

**IMPORTANTE:** O Design System será criado após **pesquisa de mercado** em:
- CRMs similares (HubSpot, Pipedrive, RD Station)
- Plataformas de atendimento IA/WhatsApp (Zenvia, Blip, TakeBlip)

Identificar melhores práticas de **UX** e padrões **UI modernos e elegantes**.

### Componentes do Design System

- **DSColors** - Paleta completa (primary, secondary, semantic, neutral)
- **DSTextStyle** - Typography system
- **DSSpacing** - Sistema de espaçamento (paddings, margins)
- **DSBorderRadius** - Raios de borda padronizados
- **DSShadows** - Elevações e sombras
- **DSAnimations** - Transições e animações

### DSColors
Cores padronizadas do projeto:
```dart
DSColors().primaryColor      // Cor principal
DSColors().secundaryColor    // Cor secundária
DSColors().tint              // Cor de destaques para ícones
DSColors().highlights        // Cor de destaque principal
DSColors().background        // Cor de fundo
DSColors().white             // Branco
DSColors().red               // Vermelho (erros)
DSColors().green             // Verde (sucesso)
```

### DSTextStyle
Estilos de texto padronizados:
```dart
DSTextStyle().headline       // Títulos
DSTextStyle().textField      // Campos de texto
DSTextStyle().menuItem       // Itens de menu
```

### DSButtons
Botões padronizados:
```dart
DSButton().primary(icon: Icons, label: 'Texto', onTap: () {})
DSButton().secundary(icon: Icons, label: 'Salvar', onTap: () {})
```

---

### DSBadge (Tags/Status)

Localização: `Commons/Widgets/DesignSystem/DSBadge.dart`

Badge para exibir status, tags ou labels coloridas.

**Exemplo:**
```dart
DSBadge(
  label: 'Ativo',
  type: DSBadgeType.success,
)

DSBadge(
  label: 'Pendente',
  type: DSBadgeType.warning,
)

DSBadge(
  label: 'WhatsApp Bot',
  type: DSBadgeType.info,
  icon: Icons.chat,
)
```

**Tipos disponíveis:**
```dart
enum DSBadgeType {
  success,    // Verde (Ativo, Confirmado)
  warning,    // Amarelo/Laranja (Pendente, Trial)
  error,      // Vermelho (Cancelado, Inativo)
  info,       // Azul (Manual, Info)
  primary,    // Cor primária (WhatsApp Bot, Premium)
}
```

**Parâmetros:**
- `label` (String) - Texto do badge
- `type` (DSBadgeType) - Tipo/cor do badge
- `icon` (IconData?) - Ícone opcional
- `size` (DSBadgeSize) - Tamanho (small, medium, large)

---

### DSAvatar (Avatar com Iniciais)

Localização: `Commons/Widgets/DesignSystem/DSAvatar.dart`

Avatar circular com iniciais geradas automaticamente a partir do nome.

**Exemplo:**
```dart
DSAvatar(
  name: 'João Silva',
  size: 48,
)

DSAvatar(
  name: 'Maria Santos',
  size: 80,
  imageUrl: 'https://...',  // Se tiver foto
)
```

**Funcionalidades:**
- Gera iniciais automaticamente (primeiras letras)
- Cor de fundo gerada por hash do nome (consistente)
- Suporta foto opcional (se `imageUrl` fornecido)
- Texto branco sobre fundo colorido

**Parâmetros:**
- `name` (String) - Nome completo
- `size` (double) - Tamanho do avatar (48, 64, 80, etc)
- `imageUrl` (String?) - URL da foto (opcional)
- `fontSize` (double?) - Tamanho da fonte das iniciais (auto se null)

**Implementação:**
```dart
class DSAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  final double? fontSize;
  
  DSAvatar({
    required this.name,
    required this.size,
    this.imageUrl,
    this.fontSize,
  });
  
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getColorFromName(name),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
        ? Text(
            _getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? size / 2.5,
              fontWeight: FontWeight.bold,
            ),
          )
        : null,
    );
  }
  
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }
  
  Color _getColorFromName(String name) {
    final colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFFF59E0B), // Amber
      Color(0xFF10B981), // Green
      Color(0xFF3B82F6), // Blue
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}
```

---

### DSMetricCard (Cards de Métricas)

Localização: `Commons/Widgets/DesignSystem/DSMetricCard.dart`

Card para exibir métricas/estatísticas com valor principal e comparação.

**Exemplo:**
```dart
DSMetricCard(
  title: 'Vendas Hoje',
  value: 'R\$ 450,00',
  comparison: '+15%',
  trend: TrendType.up,
  icon: Icons.attach_money,
)

DSMetricCard(
  title: 'Total Clientes',
  value: '245',
  comparison: '+12 este mês',
  trend: TrendType.neutral,
  icon: Icons.people,
)
```

**Estrutura:**
```
┌─────────────────┐
│ [Icon] Título   │
│                 │
│   VALOR GRANDE  │
│   ↑ +15%        │
└─────────────────┘
```

**Parâmetros:**
- `title` (String) - Título do card
- `value` (String) - Valor principal (grande)
- `comparison` (String?) - Texto de comparação (ex: "+15%", "+12 clientes")
- `trend` (TrendType?) - Tendência (up/down/neutral)
- `icon` (IconData?) - Ícone opcional
- `color` (Color?) - Cor do card (padrão: branco)

```dart
enum TrendType {
  up,       // ↑ Verde
  down,     // ↓ Vermelho
  neutral,  // - Cinza
}
```

---

### DSListTile (Item de Lista Padronizado)

Localização: `Commons/Widgets/DesignSystem/DSListTile.dart`

Item de lista consistente usado em todas as listagens.

**Exemplo:**
```dart
DSListTile(
  leading: DSAvatar(name: 'João Silva', size: 48),
  title: 'João Silva',
  subtitle: '(11) 98765-4321 • joao@email.com',
  trailing: [
    IconButton(
      icon: Icon(Icons.edit),
      onPressed: () => editCustomer(),
    ),
    IconButton(
      icon: Icon(Icons.delete),
      onPressed: () => deleteCustomer(),
    ),
  ],
  badges: [
    DSBadge(label: 'VIP', type: DSBadgeType.primary),
  ],
  onTap: () => navigateToDetails(),
)
```

**Estrutura:**
```
┌──────────────────────────────────────┐
│ [Avatar] Título           [Buttons]  │
│          Subtitle                    │
│          [Badges]                    │
└──────────────────────────────────────┘
```

**Parâmetros:**
- `leading` (Widget?) - Widget à esquerda (geralmente avatar)
- `title` (String) - Título principal
- `subtitle` (String?) - Subtítulo (opcional)
- `trailing` (List<Widget>?) - Botões/ações à direita
- `badges` (List<DSBadge>?) - Lista de badges
- `metadata` (String?) - Informação adicional (ex: "Há 3 dias")
- `onTap` (VoidCallback?) - Ação ao clicar

---

## 🎨 Padrões de UI/UX

### Botões de Ação em Listagens

**IMPORTANTE:** Padronizar botões de ação para consistência em todos os módulos.

#### **Web (Desktop):**
Usar **apenas ícones** com tooltip ao hover:

```dart
IconButton(
  icon: Icon(Icons.edit),
  tooltip: 'Editar',
  onPressed: () => editItem(),
)

IconButton(
  icon: Icon(Icons.delete),
  tooltip: 'Deletar',
  onPressed: () => deleteItem(),
)
```

**Benefícios:**
- Interface mais limpa
- Mais espaço para conteúdo
- Visual moderno

#### **Mobile:**
Usar **ícone + texto** para melhor acessibilidade:

```dart
TextButton.icon(
  icon: Icon(Icons.edit),
  label: Text('Editar'),
  onPressed: () => editItem(),
)

TextButton.icon(
  icon: Icon(Icons.delete),
  label: Text('Deletar'),
  onPressed: () => deleteItem(),
)
```

**Benefícios:**
- Mais claro em telas touch
- Melhor acessibilidade
- Menos erros de toque

#### **Padrão por Módulo:**

| Módulo | Botões (Web) | Botões (Mobile) |
|--------|--------------|-----------------|
| **Produtos** | [✏️] [🗑️] | [✏️ Editar] [🗑️ Deletar] |
| **Clientes** | [💬] [✏️] [🗑️] | [💬 WhatsApp] [✏️ Editar] [🗑️ Deletar] |
| **Vendas** | [👁️] [🗑️] | [👁️ Ver] [🗑️ Deletar] |
| **Equipe** | [✏️] [🗑️] | [✏️ Editar] [🗑️ Deletar] |
| **Tenants** | [✏️] [👁️] [🗑️] | [✏️ Editar] [👁️ Ver] [🗑️ Deletar] |

### Placeholders de Busca

**Padrão consistente:**

**Opção A - Simples (Recomendado):**
```
"Buscar produtos..."
"Buscar clientes..."
"Buscar vendas..."
"Buscar membros..."
```

**Opção B - Detalhado:**
```
"Buscar por nome, SKU ou descrição..."
"Buscar por nome, telefone ou email..."
"Buscar por número, cliente ou produto..."
```

**Escolha:** Usar Opção A para simplicidade visual, adicionar hint text com campos no campo de ajuda.

### Empty States

Estrutura consistente em todos os módulos:

```dart
EmptyState(
  icon: Icons.icon_name,
  title: 'Título do Empty State',
  message: 'Mensagem explicativa curta.',
  actionLabel: 'Ação Principal',
  onAction: () => performAction(),
)
```

**Layout:**
```
┌─────────────────┐
│                 │
│  [Ilustração]   │
│                 │
│     Título      │
│                 │
│   Mensagem      │
│   descritiva    │
│                 │
│  [Botão Ação]   │
│                 │
└─────────────────┘
```

**Variações por Contexto:**
1. **Vazio Inicial:** "Nenhum X cadastrado" + CTA "Adicionar Primeiro X"
2. **Busca Vazia:** "Nenhum X encontrado" + CTA "Limpar Busca"
3. **Filtros Vazios:** "Nenhum X com esses filtros" + CTA "Limpar Filtros"

---

## 🧩 Biblioteca de Widgets Reutilizáveis

**REGRA IMPORTANTE:** Sempre que criar um widget comum/reutilizável, **adicionar nesta seção** com:
- Descrição do componente
- Exemplo de uso
- Parâmetros disponíveis

**Nunca usar valores hardcoded** - sempre referenciar o Design System.

---

### DSAlertDialog (Modais de Confirmação)

**IMPORTANTE:** Sempre utilize `DSAlertDialog` para criar alertas e modais de confirmação. Não use `AlertDialog` diretamente.

Localização: `Commons/Widgets/DesignSystem/DSAlertDialog.dart`

**Tipos disponíveis:**
- `DSAlertType.delete` - Exclusão (vermelho)
- `DSAlertType.warning` - Aviso (amarelo/laranja)
- `DSAlertType.success` - Sucesso (verde)
- `DSAlertType.info` - Informação (azul)
- `DSAlertType.confirm` - Confirmação genérica (cor primária)

**Exemplos de uso:**
```dart
// Alerta de exclusão com preview
final confirmed = await DSAlertDialog.showDelete(
  context: context,
  title: 'Confirmar exclusão',
  message: 'Deseja remover este produto?',
  content: DSAlertContentCard(
    icon: Icons.shopping_bag_outlined,
    color: DSColors().red,
    title: product.name,
    subtitle: product.price.formatToBRL(),
  ),
);
if (confirmed == true) {
  await viewModel.deleteProduct(product);
}

// Alerta de sucesso
await DSAlertDialog.showSuccess(
  context: context,
  title: 'Produto salvo!',
  message: 'O produto foi cadastrado com sucesso.',
);

// Alerta informativo (apenas OK)
await DSAlertDialog.showInfo(
  context: context,
  title: 'Atenção',
  message: 'Esta funcionalidade estará disponível em breve.',
);
```

---

### FormTextField (Campos de Formulário)

Localização: `Commons/Widgets/DesignSystem/FormTextField.dart`

Campo de texto padronizado com validação.

**Exemplo:**
```dart
FormTextField(
  label: 'Nome do Produto',
  controller: nameController,
  validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
  keyboardType: TextInputType.text,
)
```

---

### SearchableModal (Modal com Busca)

Localização: `Commons/Widgets/DesignSystem/SearchableModal.dart`

Modal com lista pesquisável.

**Exemplo:**
```dart
final selected = await SearchableModal.show<ProductModel>(
  context: context,
  title: 'Selecionar Produto',
  items: products,
  itemBuilder: (product) => ListTile(
    title: Text(product.name),
    subtitle: Text(product.price.formatToBRL()),
  ),
  searchFilter: (product, query) => 
    product.name.toLowerCase().contains(query.toLowerCase()),
);
```

---

### EmptyState (Estado Vazio)

Localização: `Commons/Widgets/DesignSystem/EmptyState.dart`

Widget para exibir quando não há dados.

**Exemplo:**
```dart
EmptyState(
  icon: Icons.shopping_cart_outlined,
  title: 'Nenhum produto cadastrado',
  message: 'Comece adicionando seu primeiro produto.',
  actionLabel: 'Adicionar Produto',
  onAction: () => navigateToAddProduct(),
)
```

---

### LoadingIndicator

Localização: `Commons/Widgets/DesignSystem/LoadingIndicator.dart`

Indicador de carregamento padronizado.

**Exemplo:**
```dart
if (isLoading) {
  return LoadingIndicator();
}
```

---

**⚠️ LEMBRE-SE:** Ao criar novos widgets comuns, adicione-os aqui com exemplo de uso!

---

## 📦 Models

Os Models seguem o padrão com:
- Factory constructor `fromDocumentSnapshot` para Firestore
- Método `toMap()` para serialização
- Método estático `newModel()` para criar instâncias vazias
- Construtor de cópia `Model.copy(original)`

**IMPORTANTE:** Models de subcoleções (products, customers, sales) **NÃO têm campo `tenant_id`** pois o isolamento vem do path.

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
  
  ProductModel({
    required this.uid,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    this.description,
    this.image_url,
    this.is_active = true,
    required this.created_at,
    this.updated_at,
  });

  // Factory para Firestore
  static ProductModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      uid: doc.id,
      name: data['name'],
      sku: data['sku'],
      price: (data['price'] as num).toDouble(),
      stock: data['stock'] as int,
      description: data['description'],
      image_url: data['image_url'],
      is_active: data['is_active'] ?? true,
      created_at: (data['created_at'] as Timestamp).toDate(),
      updated_at: data['updated_at'] != null
        ? (data['updated_at'] as Timestamp).toDate()
        : null,
    );
  }
  
  // Serialização
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'price': price,
      'stock': stock,
      'description': description,
      'image_url': image_url,
      'is_active': is_active,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': updated_at != null 
        ? Timestamp.fromDate(updated_at!)
        : null,
    };
  }
  
  // Instância vazia
  static ProductModel newModel() {
    return ProductModel(
      uid: '', 
      name: '',
      sku: '',
      price: 0.0,
      stock: 0,
      is_active: true,
      created_at: DateTime.now(),
    );
  }
  
  // Cópia com alterações
  ProductModel copyWith({
    String? uid,
    String? name,
    String? sku,
    double? price,
    int? stock,
    String? description,
    String? image_url,
    bool? is_active,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return ProductModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      image_url: image_url ?? this.image_url,
      is_active: is_active ?? this.is_active,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
```

---

## 🔧 Extensions

Extensions são organizadas no padrão `[Tipo]+Extensions.dart`:

- `String+Extensions.dart` - Formatações (CPF, CNPJ, moeda, telefone)
- `Int+Extensions.dart` - Utilitários para inteiros
- `Double+Extensions.dart` - Utilitários para doubles
- `Bool+Extensions.dart` - Utilitários para booleanos

```dart
// Exemplo de uso
"12345678901".formatCpfCnpj()  // "123.456.789-01"
"1000".formatToBRL()           // "R$ 10,00"
```

---

## 🔒 Segurança e Autenticação

### Requisitos de Senha

**SENHA MÍNIMA: 7 caracteres**

```dart
// Validação de senha
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Senha é obrigatória';
  }
  if (value.length < 7) {
    return 'Senha deve ter no mínimo 7 caracteres';
  }
  return null;
}
```

**Senha Padrão para Novos Usuários:**
Quando TenantAdmin cria um novo usuário, a senha padrão é `1234567` (7 dígitos).

**Troca Obrigatória no Primeiro Login:**
```dart
// Verificar se é primeiro login
if (user.metadata.creationTime == user.metadata.lastSignInTime) {
  // Forçar troca de senha
  navigateToChangePassword(force: true);
}
```

### Firebase Security Rules (Estrutura NESTED)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper: Verificar se user tem membership ativo no tenant
    function hasMembership(tenantId) {
      return exists(/databases/$(database)/documents/memberships/$(getUserMembership(request.auth.uid, tenantId)));
    }
    
    function getUserMembership(userId, tenantId) {
      return get(/databases/$(database)/documents/memberships/$(userId + '_' + tenantId)).id;
    }
    
    function isTenantAdmin(tenantId) {
      let membership = get(/databases/$(database)/documents/memberships/$(getUserMembership(request.auth.uid, tenantId)));
      return membership.data.role in ['tenantAdmin', 'superAdmin'] && membership.data.is_active == true;
    }
    
    function isSuperAdmin() {
      let memberships = get(/databases/$(database)/documents/memberships).data;
      return memberships.role == 'superAdmin' && memberships.is_active == true;
    }
    
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
    
    // Tenants: SuperAdmin total, TenantAdmin leitura
    match /tenants/{tenantId} {
      allow read: if hasMembership(tenantId);
      allow write: if isSuperAdmin();
      
      // Produtos: Apenas membros com permissão
      match /products/{productId} {
        allow read: if hasMembership(tenantId);
        allow write: if isTenantAdmin(tenantId);
      }
      
      // Clientes: Apenas membros com permissão
      match /customers/{customerId} {
        allow read: if hasMembership(tenantId);
        allow write: if isTenantAdmin(tenantId);
      }
      
      // Vendas: Todos podem criar, admin gerencia
      match /sales/{saleId} {
        allow read: if hasMembership(tenantId);
        allow create: if hasMembership(tenantId);
        allow update, delete: if isTenantAdmin(tenantId);
      }
      
      // Conversas: Leitura para todos, escrita restrita
      match /conversations/{conversationId} {
        allow read: if hasMembership(tenantId);
        allow write: if isTenantAdmin(tenantId);
      }
      
      // Billing: Apenas SuperAdmin
      match /billing/{billingId} {
        allow read: if hasMembership(tenantId);
        allow write: if isSuperAdmin();
      }
    }
  }
}
```

### Logout Forçado

Quando TenantAdmin remove ou inativa um usuário, forçar logout:

```dart
// Middleware em cada navegação/requisição
Future<void> checkMembershipStatus() async {
  if (!SessionManager.instance.hasSession()) return;
  
  final userId = SessionManager.instance.currentUser!.uid;
  final tenantId = SessionManager.instance.currentTenant!.uid;
  
  final membership = await _firestore
    .collection('memberships')
    .where('user_id', isEqualTo: userId)
    .where('tenant_id', isEqualTo: tenantId)
    .where('is_active', isEqualTo: true)
    .limit(1)
    .get();
  
  if (membership.docs.isEmpty) {
    await SessionManager.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
    DSAlertDialog.showWarning(
      title: 'Acesso Removido',
      message: 'Seu acesso a este tenant foi removido.',
    );
  }
}
```

---

## 📊 Estratégia de Denormalização

### Por que Denormalizar?

Em uma arquitetura NoSQL (Firestore), denormalizar dados evita **joins complexos** e melhora performance em listagens.

### Campos Denormalizados por Model

#### **CustomerModel:**
```dart
DateTime? last_purchase_at;   // Última compra
double? total_spent;          // Total gasto (soma de vendas)
int? purchase_count;          // Quantidade de compras
```

**Quando Atualizar:**
- Ao criar uma venda → Incrementar `purchase_count`, somar em `total_spent`, atualizar `last_purchase_at`
- Ao deletar uma venda → Decrementar `purchase_count`, subtrair de `total_spent`, recalcular `last_purchase_at`
- Ao cancelar uma venda → Mesmo que deletar

#### **SaleModel:**
```dart
String customer_name;         // Nome do cliente
String customer_whatsapp;     // WhatsApp do cliente
```

**Quando Atualizar:**
- Ao criar venda → Copiar de `CustomerModel`
- Se cliente mudar nome/whatsapp → **NÃO** atualizar vendas antigas (manter histórico)

#### **MembershipModel:**
```dart
String? user_name;            // Nome do usuário
String? user_email;           // Email do usuário
```

**Quando Atualizar:**
- Ao criar membership → Copiar de `UserModel`
- Se user mudar nome/email → Atualizar **todos os memberships** desse user

### Helper para Atualizar Denormalizações

```dart
class CustomerDenormalizationHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Atualizar estatísticas do cliente após nova venda
  Future<void> updateAfterSale(String tenantId, String customerId, double saleAmount) async {
    final customerRef = _firestore.doc('tenants/$tenantId/customers/$customerId');
    
    await _firestore.runTransaction((transaction) async {
      final customerDoc = await transaction.get(customerRef);
      
      if (!customerDoc.exists) return;
      
      final currentCount = customerDoc.data()?['purchase_count'] ?? 0;
      final currentTotal = (customerDoc.data()?['total_spent'] ?? 0.0) as double;
      
      transaction.update(customerRef, {
        'purchase_count': currentCount + 1,
        'total_spent': currentTotal + saleAmount,
        'last_purchase_at': FieldValue.serverTimestamp(),
      });
    });
  }
  
  // Atualizar estatísticas do cliente após deletar venda
  Future<void> updateAfterDeleteSale(String tenantId, String customerId, double saleAmount) async {
    final customerRef = _firestore.doc('tenants/$tenantId/customers/$customerId');
    
    await _firestore.runTransaction((transaction) async {
      final customerDoc = await transaction.get(customerRef);
      
      if (!customerDoc.exists) return;
      
      final currentCount = customerDoc.data()?['purchase_count'] ?? 0;
      final currentTotal = (customerDoc.data()?['total_spent'] ?? 0.0) as double;
      
      // Recalcular última compra
      final sales = await _firestore
        .collection('tenants/$tenantId/sales')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();
      
      final lastPurchaseAt = sales.docs.isNotEmpty
        ? sales.docs.first.data()['created_at']
        : null;
      
      transaction.update(customerRef, {
        'purchase_count': max(0, currentCount - 1),
        'total_spent': max(0.0, currentTotal - saleAmount),
        'last_purchase_at': lastPurchaseAt,
      });
    });
  }
}
```

### Quando NÃO Denormalizar

❌ **Não denormalizar:**
- Dados que mudam frequentemente (ex: estoque de produto)
- Dados que precisam estar sempre sincronizados
- Dados pequenos que podem ser buscados rapidamente

✅ **Denormalizar:**
- Dados usados em listagens (evitar lookups)
- Dados raramente alterados (ex: nome de cliente em venda)
- Estatísticas/agregações (evitar cálculos em tempo real)

---

## 🔐 Sessão e Autenticação

### SessionManager
Singleton para gerenciamento de sessão:
```dart
SessionManager.instance.currentUser       // Usuário atual
SessionManager.instance.currentTenant     // Tenant ativo
SessionManager.instance.currentMembership // Membership atual
SessionManager.instance.hasSession()      // Verifica se há sessão ativa
SessionManager.instance.switchTenant(id)  // Trocar de tenant
SessionManager.instance.signOut()         // Encerra sessão, limpa caches
```

### PreferencesManager
Persistência de dados locais usando SharedPreferences.

---

## 🌍 Ambientes

O projeto suporta múltiplos ambientes configurados em `main.dart`:

```dart
/// Ambiente de execução do aplicativo
enum Environment { 
  production, 
  homologation,
  development 
}

class AppConfig {
  static const String versionApp = '1.0.0';
  static const String baseUrl = 'https://api-xxxxx.a.run.app';
  static Environment environment = Environment.development;
}
```

**Entry points por ambiente:**
- `main_development.dart` → Ambiente de desenvolvimento
- `main_homolog.dart` → Ambiente de homologação
- `main_production.dart` → Ambiente de produção

---

## 📝 Sistema de Logging

O projeto possui um sistema de logging centralizado em `Sources/AppLogger.dart`:

```dart
// Níveis disponíveis
AppLogger.debug('Informação de debug');
AppLogger.info('Evento importante');
AppLogger.warning('Atenção necessária');
AppLogger.error('Erro ocorreu', error: e, stackTrace: stack);
```

**Características:**
- Logs são automaticamente desabilitados em produção
- Timestamps incluídos em cada mensagem
- Suporte a stack traces para erros

---

## ✅ Checklist para Nova Feature

1. **Criar estrutura de pastas:**
   ```
   Scenes/[NovaFeature]/
   ├── [NovaFeature]Page.dart
   ├── [NovaFeature]Presenter.dart
   ├── [NovaFeature]ViewModel.dart
   ├── [NovaFeature]Repository.dart
   ├── [NovaFeature]Service.dart (se necessário)
   ├── [NovaFeature]Coordinator.dart (se necessário)
   ├── Mobile/[NovaFeature]MobileView.dart
   └── Web/[NovaFeature]WebView.dart
   ```

2. **Criar Page com ScreenResponsive:**
   ```dart
   class NovaFeaturePage extends StatelessWidget {
     final presenter = NovaFeaturePresenter();
     
     @override
     Widget build(BuildContext context) {
       presenter.context = context;
       return ScreenResponsive(
         mobile: NovaFeatureMobileView(presenter),
         web: NovaFeatureWebView(presenter)
       );
     }
   }
   ```

3. **Criar Repository com path NESTED (subcoleção):**
   ```dart
   class NovaFeatureRepository {
     final FirebaseFirestore _firestore = FirebaseFirestore.instance;
     
     Future<List<Model>> getAll() async {
       final tenantId = SessionManager.instance.currentTenant!.uid;
       
       // Path direto: tenants/{tenant_id}/collection_name
       return _firestore
         .collection('tenants/$tenantId/collection_name')
         .get()
         .then((snapshot) => snapshot.docs
             .map((doc) => Model.fromDocumentSnapshot(doc))
             .toList());
     }
     
     Future<void> create(Model model) async {
       final tenantId = SessionManager.instance.currentTenant!.uid;
       
       await _firestore
         .collection('tenants/$tenantId/collection_name')
         .add(model.toMap());
     }
   }
   ```

4. **Usar Design System para UI:**
   - Cores: `DSColors()`
   - Textos: `DSTextStyle()`
   - Widgets: `FormTextField`, `SearchableModal`, `DSAlertDialog`, etc.

---

## 📝 Convenções de Código

### Nomenclatura
- **Classes:** PascalCase (`LoginPresenter`, `ProductModel`)
- **Arquivos:** PascalCase (`LoginPage.dart`, `ProductModel.dart`)
- **Variáveis:** camelCase (`isLoading`, `currentUser`)
- **Constantes:** SCREAMING_SNAKE_CASE (`BASE_URL`, `ENVIRONMENT`)

### Comentários
Usar `// MARK:` para seções dentro de classes:
```dart
class LoginPresenter {
  // MARK: Properties
  
  // MARK: BindEvents
  
  // MARK: Handlers

  // MARK: Methods

  // MARK: Setups
}
```

### Imports
Ordenar imports:
1. Dart/Flutter packages
2. Packages externos
3. Imports locais do projeto

---

## 🚀 Build e Deploy

```bash
# Build para desenvolvimento
flutter build web --release -t lib/main_development.dart --base-href "/"
firebase deploy --only hosting:development

# Build para produção
flutter build web --release -t lib/main_production.dart --base-href "/"
firebase deploy --only hosting:production
```

---

## 📚 Bibliotecas Principais

| Biblioteca | Uso |
|------------|-----|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Backend Firebase |
| `riverpod` | Gerenciamento de estado reativo |
| `pdf`, `printing` | Geração de PDFs |
| `elegant_notification` | Notificações elegantes |
| `intl` | Formatação de datas e números |

---
