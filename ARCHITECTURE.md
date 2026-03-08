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

**REGRA CRÍTICA:** Todos os documentos do Firestore devem incluir `tenant_id`, **EXCETO:**
- `users` - Usuários podem pertencer a múltiplos tenants
- `tenants` - É a coleção raiz de organizações
- `memberships` - Relaciona users ↔ tenants

### Estrutura de Coleções Firestore

```
users/                          # Usuários do sistema
  └── {user_id}
      ├── email
      ├── name
      └── created_at

tenants/                        # Organizações/Empresas
  └── {tenant_id}
      ├── name
      ├── plan (trial | basic | full)
      ├── is_active
      └── created_at

memberships/                    # Relação user ↔ tenant
  └── {membership_id}
      ├── user_id
      ├── tenant_id
      ├── role (superAdmin | tenantAdmin | user)
      ├── is_active
      └── created_at

products/                       # Produtos do micro-empreendedor
  └── {product_id}
      ├── tenant_id            ⚠️ OBRIGATÓRIO
      ├── name
      ├── description
      ├── price
      ├── image_url
      └── is_active

customers/                      # Clientes (CRM)
  └── {customer_id}
      ├── tenant_id            ⚠️ OBRIGATÓRIO
      ├── name
      ├── phone
      ├── whatsapp
      └── created_at

sales/                          # Vendas realizadas
  └── {sale_id}
      ├── tenant_id            ⚠️ OBRIGATÓRIO
      ├── customer_id
      ├── product_ids[]
      ├── total
      ├── status
      ├── created_at
      └── source (manual | whatsapp_automation)

conversations/                  # Histórico WhatsApp
  └── {conversation_id}
      ├── tenant_id            ⚠️ OBRIGATÓRIO
      ├── customer_id
      ├── messages[]
      ├── status
      └── last_message_at

billing/                        # Faturamento e assinaturas
  └── {billing_id}
      ├── tenant_id            ⚠️ OBRIGATÓRIO
      ├── plan
      ├── amount
      ├── status
      ├── period_start
      └── period_end
```

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

### Repository Pattern (Atualizado)

**IMPORTANTE:** Repositories devem **automaticamente** filtrar por `tenant_id`:

```dart
class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Buscar todos os produtos do tenant atual
  Future<List<ProductModel>> getAll() async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    final snapshot = await _firestore
      .collection('products')
      .where('tenant_id', isEqualTo: tenantId)
      .where('is_active', isEqualTo: true)
      .get();
    
    return snapshot.docs
      .map((doc) => ProductModel.fromDocumentSnapshot(doc))
      .toList();
  }
  
  // Criar produto (injeta tenant_id automaticamente)
  Future<void> create(ProductModel product) async {
    final tenantId = SessionManager.instance.currentTenant!.uid;
    
    final data = product.toMap();
    data['tenant_id'] = tenantId; // ⚠️ Garantir tenant_id
    
    await _firestore.collection('products').add(data);
  }
}
```

**Exceção - SuperAdmin:**
SuperAdmin pode acessar dados cross-tenant quando necessário (ex: dashboard global).

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

```dart
class ProductModel {
  String uid;
  String tenant_id;
  String name;
  // ... outros campos

  // Factory para Firestore
  static ProductModel fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      uid: doc.id,
      tenant_id: data['tenant_id'],
      name: data['name'],
      // ...
    );
  }
  
  // Serialização
  Map<String, dynamic> toMap() {
    return {
      'tenant_id': tenant_id,
      'name': name,
      // ...
    };
  }
  
  // Instância vazia
  static ProductModel newModel() {
    return ProductModel(
      uid: '', 
      tenant_id: '',
      name: '',
      // ...
    );
  }
  
  // Cópia
  ProductModel.copy(ProductModel original)
      : uid = original.uid,
        tenant_id = original.tenant_id,
        name = original.name;
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

3. **Criar Repository com filtro por tenant_id:**
   ```dart
   class NovaFeatureRepository {
     Future<List<Model>> getAll() async {
       final tenantId = SessionManager.instance.currentTenant!.uid;
       return firestore
         .collection('collection_name')
         .where('tenant_id', isEqualTo: tenantId)
         .get();
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
