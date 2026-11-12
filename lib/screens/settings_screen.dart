import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_detector_sheet.dart';

class SettingsScreen extends StatelessWidget {
  final FinanceStore store;
  const SettingsScreen({super.key, required this.store});

  static Future<void> show(BuildContext context, FinanceStore store) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(store: store),
      ),
    );
  }

  static Widget buildHeaderButton(BuildContext context, FinanceStore store) {
    return IconButton(
      tooltip: 'Ajustes',
      onPressed: () => show(context, store),
      icon: Icon(
        Icons.settings_outlined,
        size: 21,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final settings = store.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
        children: [
          const _SectionTitle('CUENTA'),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: context.palette.accentFill,
                    child: Text(
                      settings.userName.isNotEmpty
                          ? settings.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    settings.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    settings.userEmail.isEmpty
                        ? 'Configurar perfil y PIN'
                        : settings.userEmail,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => _showEditProfileDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.logout_rounded,
                    color: context.palette.expense,
                    size: 19,
                  ),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: context.palette.expense,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => store.lockOrLogoutSession(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionTitle('CATEGORÍAS Y TIPO DE CAMBIO'),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.category_outlined,
                    color: context.palette.accent,
                    size: 20,
                  ),
                  title: const Text(
                    'Administrar categorías',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    '${store.expenseCategories.length} gastos • ${store.incomeCategories.length} ingresos',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _CategoriesManagementPage(store: store),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.contactless_rounded,
                    color: context.palette.accent,
                    size: 20,
                  ),
                  title: const Text(
                    'Google Wallet y SMS Bancarios',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    store.hasNotificationListenerAccess
                        ? 'Detector activo • ${store.settings.autoRegisterDetectedPayments ? 'Débito automático' : 'Confirmación manual'}'
                        : 'Configurar permisos de detección',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => PaymentDetectorPage.show(context, store),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.currency_exchange_rounded,
                    color: context.palette.income,
                    size: 20,
                  ),
                  title: const Text(
                    'Tipo de cambio (Tarjetas Dúo)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: const Text(
                    'Conversión USD (\$) a Quetzales (Q)',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.incomeSoftBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Q${settings.usdToGtqRate.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: context.palette.income,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  onTap: () => _showExchangeRateDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionTitle('PREFERENCIAS'),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 19),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Moneda',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'GTQ', label: Text('Q')),
                          ButtonSegment(value: 'USD', label: Text('\$')),
                          ButtonSegment(value: 'EUR', label: Text('€')),
                        ],
                        selected: {
                          ['GTQ', 'USD', 'EUR'].contains(
                                settings.primaryCurrency,
                              )
                              ? settings.primaryCurrency
                              : 'GTQ',
                        },
                        onSelectionChanged: (s) {
                          store.updateSettings(
                            settings.copyWith(primaryCurrency: s.first),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language_outlined, size: 19),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Idioma',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'es', label: Text('ES')),
                          ButtonSegment(value: 'en', label: Text('EN')),
                        ],
                        selected: {settings.language},
                        onSelectionChanged: (s) {
                          store.updateSettings(
                            settings.copyWith(language: s.first),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  dense: true,
                  secondary: Icon(
                    settings.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 19,
                  ),
                  title: const Text(
                    'Tema oscuro',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  value: settings.isDarkMode,
                  onChanged: (v) {
                    store.updateSettings(settings.copyWith(isDarkMode: v));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionTitle('DATOS'),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.upload_file_outlined, size: 19),
                  title: const Text(
                    'Exportar respaldo (JSON)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.download_outlined, size: 19),
                  title: const Text(
                    'Importar respaldo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onTap: () => _showImportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: context.palette.expense,
                    size: 19,
                  ),
                  title: Text(
                    'Restablecer datos',
                    style: TextStyle(
                      color: context.palette.expense,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => _confirmResetData(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final s = store.settings;
    final nameCtrl = TextEditingController(text: s.userName);
    final emailCtrl = TextEditingController(text: s.userEmail);
    final pinCtrl = TextEditingController(text: s.pinCode ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perfil', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo (Opcional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN de acceso (Opcional)',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final pin = pinCtrl.text.trim();
              store.updateSettings(
                s.copyWith(
                  userName: nameCtrl.text.trim().isEmpty
                      ? 'Mi Cuenta'
                      : nameCtrl.text.trim(),
                  userEmail: emailCtrl.text.trim(),
                  pinCode: pin.isEmpty ? null : pin,
                  clearPin: pin.isEmpty,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showExchangeRateDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: store.settings.usdToGtqRate.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tipo de Cambio (USD → GTQ)',
          style: TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Convierte automáticamente los gastos en dólares de tus tarjetas Dúo.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quetzales por \$1 USD',
                prefixText: 'Q ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                store.updateSettings(
                  store.settings.copyWith(usdToGtqRate: val),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final json = store.exportBackupJson();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Respaldo', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Respaldo copiado al portapapeles.'),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 15),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar Respaldo', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Pega aquí el respaldo JSON...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await store.importBackupJson(ctrl.text.trim());
              if (!context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Datos importados.' : 'JSON inválido.',
                  ),
                ),
              );
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '¿Restablecer datos?',
          style: TextStyle(fontSize: 16),
        ),
        content: const Text(
          'Se borrarán todas tus cuentas, movimientos, límites y pagos recurrentes.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expenseSolid,
            ),
            onPressed: () {
              store.clearAllUserData();
              Navigator.pop(ctx);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _CategoriesManagementPage extends StatefulWidget {
  final FinanceStore store;
  const _CategoriesManagementPage({required this.store});

  @override
  State<_CategoriesManagementPage> createState() =>
      _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<_CategoriesManagementPage> {
  CategoryKind _selectedTab = CategoryKind.expense;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final list = _selectedTab == CategoryKind.expense
            ? widget.store.expenseCategories
            : widget.store.incomeCategories;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Categorías'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.palette.accentFill,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _showNewCategoryDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Nueva'),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<CategoryKind>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: CategoryKind.expense,
                      label: Text('Gastos'),
                    ),
                    ButtonSegment(
                      value: CategoryKind.income,
                      label: Text('Ingresos'),
                    ),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (s) =>
                      setState(() => _selectedTab = s.first),
                ),
              ),
              const SizedBox(height: 12),
              for (final cat in list)
                RepaintBoundary(child: _buildCategoryCard(context, cat)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel cat) {
    final solidColor = Color(cat.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: solidColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cat.emoji,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _showAddSubcategoryDialog(context, cat),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Subcategoría'),
                  ),
                  if (cat.isCustom)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => widget.store.deleteCategory(cat.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: context.palette.expense,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cat.subcategories
                    .map(
                      (sub) => InputChip(
                        label: Text(
                          sub,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onDeleted: cat.subcategories.length > 1
                            ? () => widget.store.removeSubcategory(cat.id, sub)
                            : null,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, CategoryModel cat) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Nueva subcategoría en ${cat.name}',
          style: const TextStyle(fontSize: 15),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                widget.store.addSubcategory(cat.id, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showNewCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final subsCtrl = TextEditingController();
    CategoryKind kind = _selectedTab;
    String emoji = '🏷️';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(
            'Nueva Categoría',
            style: TextStyle(fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<CategoryKind>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: CategoryKind.expense,
                        label: Text('Gasto'),
                      ),
                      ButtonSegment(
                        value: CategoryKind.income,
                        label: Text('Ingreso'),
                      ),
                    ],
                    selected: {kind},
                    onSelectionChanged: (s) => setState(() => kind = s.first),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subcategorías (separadas por coma)',
                    hintText: 'Ej. General, Mensual',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: ['🏷️', '🏠', '✈️', '📚', '💼', '🎉', '🛠️'].map((
                    e,
                  ) {
                    return ChoiceChip(
                      label: Text(e),
                      selected: emoji == e,
                      onSelected: (_) => setState(() => emoji = e),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final subs = subsCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                widget.store.saveCategory(
                  name: name,
                  emoji: emoji,
                  kind: kind,
                  subcategories: subs.isEmpty ? ['General'] : subs,
                  colorValue: AppTheme.accountSolidColors[1],
                );
                Navigator.pop(ctx);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
