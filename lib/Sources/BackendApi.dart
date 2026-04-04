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
    String? webhookUrl,
  }) {
    return postAuthenticated(
      functionName: 'provisionManagedWhatsApp',
      body: {
        'tenantId': tenantId,
        if (webhookUrl != null && webhookUrl.isNotEmpty)
          'webhookUrl': webhookUrl,
      },
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

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw Exception(decoded['error'] ?? 'Erro ao chamar backend');
  }
}
