# Configuração do Firebase - SaaS Manu

## ✅ Configuração Concluída

A configuração do Firebase foi finalizada com sucesso! O projeto está conectado ao Firebase e pronto para usar os serviços.

## 📦 Dependências Instaladas

As seguintes dependências do Firebase foram adicionadas ao `pubspec.yaml`:

- **firebase_core** (^3.8.1): SDK principal do Firebase (obrigatório)
- **firebase_auth** (^5.3.4): Autenticação de usuários
- **cloud_firestore** (^5.5.2): Banco de dados NoSQL em tempo real
- **firebase_storage** (^12.3.7): Armazenamento de arquivos

## 🔧 Configuração Realizada

### 1. Projeto Firebase
- **Nome do Projeto**: saas-manu-project
- **Plataformas Configuradas**: Android, iOS, macOS, Web, Windows

### 2. Arquivos Gerados

#### Multiplataforma
- `lib/firebase_options.dart` - Configurações do Firebase para todas as plataformas

#### Android
- `android/app/google-services.json` - Configuração do Firebase para Android
- Plugin Google Services adicionado ao `build.gradle.kts`

#### iOS/macOS
- `ios/Runner/GoogleService-Info.plist` - Configuração do Firebase para iOS
- `macos/Runner/GoogleService-Info.plist` - Configuração do Firebase para macOS

### 3. Inicialização no Código
O Firebase foi inicializado no `lib/main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

## 🚀 Próximos Passos

### 1. Configurar Autenticação
```dart
import 'package:firebase_auth/firebase_auth.dart';

// Criar usuário
final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'usuario@exemplo.com',
  password: 'senha123',
);

// Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'usuario@exemplo.com',
  password: 'senha123',
);

// Logout
await FirebaseAuth.instance.signOut();

// Observar estado de autenticação
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    print('Usuário não autenticado');
  } else {
    print('Usuário autenticado: ${user.uid}');
  }
});
```

### 2. Usar Cloud Firestore
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Adicionar documento
await FirebaseFirestore.instance.collection('usuarios').add({
  'nome': 'João Silva',
  'email': 'joao@exemplo.com',
  'criadoEm': FieldValue.serverTimestamp(),
});

// Ler documentos
final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
for (var doc in snapshot.docs) {
  print('${doc.id} => ${doc.data()}');
}

// Stream de dados em tempo real
FirebaseFirestore.instance.collection('usuarios').snapshots().listen((snapshot) {
  for (var change in snapshot.docChanges) {
    print('${change.type}: ${change.doc.data()}');
  }
});
```

### 3. Usar Firebase Storage
```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// Upload de arquivo
final file = File('caminho/para/arquivo.jpg');
final ref = FirebaseStorage.instance.ref().child('imagens/perfil.jpg');
await ref.putFile(file);

// Obter URL de download
final url = await ref.getDownloadURL();
print('URL do arquivo: $url');
```

## 🔐 Configuração de Segurança

Não esqueça de configurar as regras de segurança no Firebase Console:

### Firestore Rules (Desenvolvimento)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules (Desenvolvimento)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Importante**: As regras acima são para desenvolvimento. Para produção, configure regras mais restritivas.

## 📱 Testando a Configuração

Para testar se o Firebase está funcionando:

```bash
# Executar no Android
flutter run -d android

# Executar no iOS
flutter run -d ios

# Executar no Web
flutter run -d chrome
```

## 🔗 Links Úteis

- [Firebase Console](https://console.firebase.google.com/)
- [Documentação Flutter + Firebase](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire](https://firebase.flutter.dev/)
- Projeto Firebase: [saas-manu-project](https://console.firebase.google.com/project/saas-manu-project)

## 🛠️ Comandos Úteis

```bash
# Atualizar configuração do Firebase
flutterfire configure

# Atualizar dependências
flutter pub upgrade

# Limpar build
flutter clean && flutter pub get
```

---

**Configuração realizada em**: 8 de março de 2026
