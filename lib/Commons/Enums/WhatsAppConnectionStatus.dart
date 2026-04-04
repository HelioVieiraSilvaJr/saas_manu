/// Estado atual da conexao do canal WhatsApp do tenant.
enum WhatsAppConnectionStatus {
  unconfigured,
  provisioning,
  awaitingQrScan,
  connecting,
  connected,
  disconnected,
  error;

  String get label {
    switch (this) {
      case WhatsAppConnectionStatus.unconfigured:
        return 'Nao configurado';
      case WhatsAppConnectionStatus.provisioning:
        return 'Preparando';
      case WhatsAppConnectionStatus.awaitingQrScan:
        return 'Aguardando QR Code';
      case WhatsAppConnectionStatus.connecting:
        return 'Conectando';
      case WhatsAppConnectionStatus.connected:
        return 'Conectado';
      case WhatsAppConnectionStatus.disconnected:
        return 'Desconectado';
      case WhatsAppConnectionStatus.error:
        return 'Com erro';
    }
  }

  static WhatsAppConnectionStatus fromString(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'provisioning':
        return WhatsAppConnectionStatus.provisioning;
      case 'awaiting_qr_scan':
      case 'awaiting-qr-scan':
      case 'qr':
      case 'qrcode':
        return WhatsAppConnectionStatus.awaitingQrScan;
      case 'connecting':
        return WhatsAppConnectionStatus.connecting;
      case 'connected':
      case 'open':
        return WhatsAppConnectionStatus.connected;
      case 'disconnected':
      case 'close':
      case 'closed':
        return WhatsAppConnectionStatus.disconnected;
      case 'error':
      case 'failed':
        return WhatsAppConnectionStatus.error;
      default:
        return WhatsAppConnectionStatus.unconfigured;
    }
  }
}
