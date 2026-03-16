import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Coordinator de navegação do módulo de Escalações (Atendimentos).
class EscalationsCoordinator {
  final BuildContext context;

  EscalationsCoordinator(this.context);

  void navigateToList() {
    Navigator.pushNamed(context, '/escalations');
  }

  /// Abre WhatsApp para o cliente.
  void openWhatsApp(String whatsapp) {
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/55$cleanNumber');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void navigateBack([dynamic result]) {
    Navigator.pop(context, result);
  }
}
