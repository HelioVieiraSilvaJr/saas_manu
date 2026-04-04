import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Commons/Models/TenantModel.dart';
import '../../Commons/Utils/AppLogger.dart';
import '../../Sources/BackendApi.dart';
import '../../Sources/SessionManager.dart';

/// Repository para configurações do Tenant — Módulo 8.
///
/// Gerencia dados da empresa, integrações WhatsApp/Evolution e webhook.
class TenantSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _tenantDoc(String tenantId) =>
      _firestore.collection('tenants').doc(tenantId);

  // MARK: - Dados da Empresa

  /// Atualiza os dados da empresa (nome, email, telefone).
  Future<bool> updateCompanyData({
    required String tenantId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      await _tenantDoc(tenantId).update({
        'name': name,
        'contact_email': email,
        'contact_phone': phone,
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Dados da empresa atualizados: $tenantId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar dados da empresa', error: e);
      return false;
    }
  }

  // MARK: - Integrações WhatsApp

  /// Salva as configurações da Evolution API.
  Future<bool> saveWhatsAppConfig({
    required String tenantId,
    required String evolutionApiUrl,
    required String apiKey,
    required String instanceName,
  }) async {
    try {
      await _tenantDoc(tenantId).update({
        'evolution_api_url': evolutionApiUrl,
        'evolution_api_key': apiKey,
        'evolution_instance_name': instanceName,
        'updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Config WhatsApp salvas: $tenantId');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao salvar config WhatsApp', error: e);
      return false;
    }
  }

  /// Testa conexão com a Evolution API.
  /// Retorna mapa com {success, message, state?}.
  Future<Map<String, dynamic>> testWhatsAppConnection({
    required String tenantId,
    required String evolutionApiUrl,
    required String apiKey,
    required String instanceName,
  }) async {
    try {
      final response = await BackendApi.instance.postAuthenticated(
        functionName: 'testEvolutionConnection',
        body: {
          'tenantId': tenantId,
          'evolutionApiUrl': evolutionApiUrl,
          'apiKey': apiKey,
          'instanceName': instanceName,
        },
      );

      return response;
    } catch (e) {
      AppLogger.error('Erro ao testar conexão WhatsApp', error: e);
      return {
        'success': false,
        'message': 'Não foi possível conectar: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> provisionManagedWhatsApp({
    required String tenantId,
    String? webhookUrl,
  }) async {
    try {
      return await BackendApi.instance.provisionManagedWhatsApp(
        tenantId: tenantId,
        webhookUrl: webhookUrl,
      );
    } catch (e) {
      AppLogger.error('Erro ao provisionar WhatsApp gerenciado', error: e);
      return {
        'ok': false,
        'success': false,
        'message': 'Nao foi possivel provisionar o WhatsApp: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getManagedWhatsAppStatus({
    required String tenantId,
    bool includeQrCode = false,
  }) async {
    try {
      return await BackendApi.instance.getManagedWhatsAppStatus(
        tenantId: tenantId,
        includeQrCode: includeQrCode,
      );
    } catch (e) {
      AppLogger.error(
        'Erro ao consultar status do WhatsApp gerenciado',
        error: e,
      );
      return {
        'ok': false,
        'success': false,
        'message': 'Nao foi possivel consultar o status: ${e.toString()}',
      };
    }
  }

  // MARK: - Webhook

  /// Salva/gera o webhook token e retorna a URL completa.
  Future<String?> generateWebhookToken(String tenantId) async {
    try {
      final tenant = SessionManager.instance.currentTenant;
      String token;

      if (tenant?.webhookToken != null && tenant!.webhookToken!.isNotEmpty) {
        token = tenant.webhookToken!;
      } else {
        // Gerar token simples (UUID-like)
        token = _generateToken();
        await _tenantDoc(tenantId).update({
          'webhook_token': token,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      return token;
    } catch (e) {
      AppLogger.error('Erro ao gerar webhook token', error: e);
      return null;
    }
  }

  /// Gera um token seguro simples.
  String _generateToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hash = now.toRadixString(36);
    return 'wh_${hash}_${DateTime.now().microsecond.toRadixString(36)}';
  }

  // MARK: - Reload Tenant

  /// Recarrega o tenant atual do Firestore.
  Future<TenantModel?> reloadTenant(String tenantId) async {
    try {
      final doc = await _tenantDoc(tenantId).get();
      if (doc.exists) {
        return TenantModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erro ao recarregar tenant', error: e);
      return null;
    }
  }
}
