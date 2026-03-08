import 'package:shared_preferences/shared_preferences.dart';
import '../Commons/Utils/AppLogger.dart';

/// Wrapper para SharedPreferences - persistência local.
class PreferencesManager {
  PreferencesManager._();
  static PreferencesManager instance = PreferencesManager._();

  SharedPreferences? _prefs;

  // MARK: - Keys

  static const String _keyLastTenantId = 'last_tenant_id';
  static const String _keyDismissedAlerts = 'dismissed_alerts';

  // MARK: - Init

  /// Inicializa SharedPreferences. Chamar no main() antes de usar.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('PreferencesManager inicializado');
  }

  // MARK: - Last Tenant

  /// Recupera o último tenant_id usado.
  Future<String?> getLastTenantId() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(_keyLastTenantId);
  }

  /// Salva o último tenant_id usado.
  Future<void> setLastTenantId(String tenantId) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyLastTenantId, tenantId);
  }

  // MARK: - Dismissed Alerts

  /// Verifica se um alerta foi dispensado (dentro do período de 7 dias).
  Future<bool> isAlertDismissed(String alertKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final dismissedAt = _prefs!.getString('${_keyDismissedAlerts}_$alertKey');
    if (dismissedAt == null) return false;

    final dismissedDate = DateTime.tryParse(dismissedAt);
    if (dismissedDate == null) return false;

    // Re-exibir após 7 dias
    return DateTime.now().difference(dismissedDate).inDays < 7;
  }

  /// Salva que um alerta foi dispensado.
  Future<void> dismissAlert(String alertKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      '${_keyDismissedAlerts}_$alertKey',
      DateTime.now().toIso8601String(),
    );
  }

  // MARK: - Generic

  /// Salvar string genérica.
  Future<void> setString(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(key, value);
  }

  /// Recuperar string genérica.
  Future<String?> getString(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(key);
  }

  /// Salvar bool genérica.
  Future<void> setBool(String key, bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(key, value);
  }

  /// Recuperar bool genérica.
  Future<bool?> getBool(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(key);
  }

  /// Limpar todas as preferências.
  Future<void> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
    AppLogger.info('PreferencesManager limpo');
  }
}
