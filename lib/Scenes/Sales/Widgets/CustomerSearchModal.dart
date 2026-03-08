import 'package:flutter/material.dart';
import '../../../Commons/Extensions/String+Extensions.dart';
import '../../../Commons/Models/CustomerModel.dart';
import '../../../Commons/Widgets/DesignSystem/DSAvatar.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Modal de busca de clientes para seleção.
class CustomerSearchModal {
  CustomerSearchModal._();

  /// Exibe o modal de busca de clientes.
  static Future<CustomerModel?> show({
    required BuildContext context,
    required List<CustomerModel> customers,
    VoidCallback? onCreateNew,
  }) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return _CustomerSearchContent(
            customers: customers,
            scrollController: scrollController,
            onCreateNew: onCreateNew,
          );
        },
      ),
    );
  }
}

class _CustomerSearchContent extends StatefulWidget {
  final List<CustomerModel> customers;
  final ScrollController scrollController;
  final VoidCallback? onCreateNew;

  const _CustomerSearchContent({
    required this.customers,
    required this.scrollController,
    this.onCreateNew,
  });

  @override
  State<_CustomerSearchContent> createState() => _CustomerSearchContentState();
}

class _CustomerSearchContentState extends State<_CustomerSearchContent> {
  final _searchController = TextEditingController();
  List<CustomerModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.customers;
      } else {
        final q = query.toLowerCase();
        _filtered = widget.customers
            .where(
              (c) => c.name.toLowerCase().contains(q) || c.whatsapp.contains(q),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DSSpacing.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: DSSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(DSSpacing.base),
            child: Text('Selecionar Cliente', style: textStyles.headline3),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.base),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.base,
                  vertical: DSSpacing.sm,
                ),
              ),
            ),
          ),
          // Create new
          if (widget.onCreateNew != null)
            ListTile(
              leading: Icon(Icons.person_add, color: colors.primaryColor),
              title: Text(
                '+ Cadastrar Novo Cliente',
                style: textStyles.labelMedium.copyWith(
                  color: colors.primaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onCreateNew?.call();
              },
            ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final customer = _filtered[index];
                return ListTile(
                  leading: DSAvatar(name: customer.name, size: 40),
                  title: Text(customer.name),
                  subtitle: Text(customer.whatsapp.formatWhatsApp()),
                  onTap: () => Navigator.pop(context, customer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
