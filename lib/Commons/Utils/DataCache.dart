import 'dart:async';

/// Cache in-memory genérico com TTL.
///
/// Mantém dados carregados entre navegações de tela,
/// evitando re-downloads desnecessários do Firestore.
///
/// Uso:
/// ```dart
/// static final cache = DataCache<SaleModel>(ttl: Duration(minutes: 5));
/// ```
class DataCache<T> {
  final Duration _ttl;

  List<T> _data = [];
  DateTime? _lastFetchAt;
  final StreamController<List<T>> _controller =
      StreamController<List<T>>.broadcast();

  DataCache({Duration ttl = const Duration(minutes: 5)}) : _ttl = ttl;

  /// Retorna true se o cache tem dados dentro do TTL.
  bool get isFresh =>
      _data.isNotEmpty &&
      _lastFetchAt != null &&
      DateTime.now().difference(_lastFetchAt!) < _ttl;

  /// Retorna true se o cache tem qualquer dado (mesmo expirado).
  bool get hasData => _data.isNotEmpty;

  /// Dados cacheados (cópia defensiva).
  List<T> get data => List<T>.from(_data);

  /// Stream reativo — emite sempre que o cache é atualizado.
  Stream<List<T>> get stream => _controller.stream;

  /// Substitui todo o cache por novos dados.
  void set(List<T> items) {
    _data = List<T>.from(items);
    _lastFetchAt = DateTime.now();
    _notify();
  }

  /// Atualiza um item existente no cache (por predicate).
  void updateWhere(bool Function(T) test, T newItem) {
    final idx = _data.indexWhere(test);
    if (idx != -1) {
      _data[idx] = newItem;
      _notify();
    }
  }

  /// Remove itens que satisfaçam o predicate.
  void removeWhere(bool Function(T) test) {
    _data.removeWhere(test);
    _notify();
  }

  /// Adiciona um item (no início por padrão).
  void add(T item, {bool prepend = true}) {
    if (prepend) {
      _data.insert(0, item);
    } else {
      _data.add(item);
    }
    _notify();
  }

  /// Invalida o TTL sem apagar dados.
  /// Próximo acesso fará fetch, mas dados antigos ficam disponíveis enquanto isso.
  void invalidate() => _lastFetchAt = null;

  /// Limpa tudo (logout, troca de tenant).
  void clear() {
    _data.clear();
    _lastFetchAt = null;
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(List<T>.from(_data));
    }
  }

  void dispose() {
    _controller.close();
  }
}
