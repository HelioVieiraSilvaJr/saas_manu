import 'package:intl/intl.dart';

/// Extensions para String - formatações diversas.
extension StringExtensions on String {
  /// Formata número para BRL: "1500.50" → "R$ 1.500,50"
  String formatToBRL() {
    final value = double.tryParse(replaceAll(',', '.')) ?? 0.0;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }

  /// Formata telefone para exibição: "11987654321" → "(11) 98765-4321"
  String formatWhatsApp() {
    final digits = replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return this;
  }

  /// Formata CPF: "12345678901" → "123.456.789-01"
  String formatCPF() {
    final digits = replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return this;
  }

  /// Formata CNPJ: "12345678000195" → "12.345.678/0001-95"
  String formatCNPJ() {
    final digits = replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 14) {
      return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
    }
    return this;
  }

  /// Remove máscara, mantendo apenas dígitos.
  String get digitsOnly => replaceAll(RegExp(r'[^\d]'), '');

  /// Valida formato de email.
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// Capitaliza primeira letra de cada palavra.
  String get capitalizeWords {
    return split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}

/// Extensions para double - formatações de valores monetários.
extension DoubleExtensions on double {
  /// Formata para BRL: 1500.50 → "R$ 1.500,50"
  String formatToBRL() {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(this);
  }

  /// Formata como percentual: 0.155 → "15,5%"
  String formatPercent({int decimalDigits = 1}) {
    final formatter = NumberFormat.percentPattern('pt_BR');
    formatter.minimumFractionDigits = decimalDigits;
    formatter.maximumFractionDigits = decimalDigits;
    return formatter.format(this);
  }
}

/// Extensions para int - formatações.
extension IntExtensions on int {
  /// Formata para BRL: 1500 → "R$ 1.500,00"
  String formatToBRL() {
    return toDouble().formatToBRL();
  }
}

/// Extensions para DateTime - formatações e utilidades.
extension DateTimeExtensions on DateTime {
  /// Formata para exibição curta: "08/03/2026"
  String formatShort() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Formata para exibição completa: "08 de março de 2026"
  String formatFull() {
    return DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(this);
  }

  /// Formata data e hora: "08/03/2026 14:30"
  String formatDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  /// Retorna "Há X minutos/horas/dias"
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
    if (diff.inDays < 30) return 'Há ${diff.inDays ~/ 7} semanas';
    if (diff.inDays < 365) return 'Há ${diff.inDays ~/ 30} meses';
    return 'Há ${diff.inDays ~/ 365} anos';
  }
}
