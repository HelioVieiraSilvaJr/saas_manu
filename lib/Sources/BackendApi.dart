import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class BackendApi {
  BackendApi._();
  static final BackendApi instance = BackendApi._();

  String get _projectId => Firebase.app().options.projectId;

  String functionUrl(String functionName) {
    return 'https://us-central1-$_projectId.cloudfunctions.net/$functionName';
  }

  String n8nSaleWebhookUrl({required String tenantId, required String token}) {
    final base = functionUrl('receiveN8nSale');
    return Uri.parse(base)
        .replace(queryParameters: {'tenantId': tenantId, 'token': token})
        .toString();
  }

  Future<Map<String, dynamic>> notifyRestockCustomers({
    required String tenantId,
    required String productId,
  }) {
    return postAuthenticated(
      functionName: 'notifyRestockCustomers',
      body: {'tenantId': tenantId, 'productId': productId},
    );
  }

  Future<Map<String, dynamic>> provisionManagedWhatsApp({
    required String tenantId,
  }) {
    return postAuthenticated(
      functionName: 'provisionManagedWhatsApp',
      body: {'tenantId': tenantId},
    );
  }

  Future<Map<String, dynamic>> getManagedWhatsAppStatus({
    required String tenantId,
    bool includeQrCode = false,
  }) {
    return postAuthenticated(
      functionName: 'getManagedWhatsAppStatus',
      body: {'tenantId': tenantId, 'includeQrCode': includeQrCode},
    );
  }

  Future<Map<String, dynamic>> disconnectManagedWhatsApp({
    required String tenantId,
  }) {
    return postAuthenticated(
      functionName: 'disconnectManagedWhatsApp',
      body: {'tenantId': tenantId},
    );
  }

  Future<Map<String, dynamic>> registerTenantSelfService({
    required String tenantName,
    required String adminName,
    required String email,
    required String phone,
    required String password,
  }) {
    return postPublic(
      functionName: 'registerTenantSelfService',
      body: {
        'tenantName': tenantName,
        'adminName': adminName,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> completePasswordReset() {
    return postAuthenticated(
      functionName: 'completePasswordReset',
      body: const {},
    );
  }

  Future<Map<String, dynamic>> postAuthenticated({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final idToken = await user.getIdToken();
    final response = await http
        .post(
          Uri.parse(functionUrl(functionName)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postPublic({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .post(
          Uri.parse(functionUrl(functionName)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded['error'] ?? 'Erro ao chamar backend');
  }
}
