import 'package:flutter/material.dart';
import '../models/budget_limit_model.dart';
import '../models/category_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'settings_screen.dart';

class BudgetsScreen extends StatelessWidget {
  final FinanceStore store;
  const BudgetsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.primaryCurrency;
    final budgets = store.budgets;

    return Scaffold(
      appBar: AppBar(
        leading: SettingsScreen.buildHeaderButton(context, store),
        titleSpacing: 0,
        title: const Text('Límites Mensuales'),
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
              onPressed: () => _showBudgetForm(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nuevo'),
            ),
          ),
        ],
      ),
      body: budgets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.palette.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.track_changes_rounded,
                        size: 26,
                        color: context.palette.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sin límites configurados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define un presupuesto mensual por categoría o subcategoría para ver cuánto llevas y si te pasaste.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.palette.accentFill,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _showBudgetForm(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Crear límite'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
              itemCount: budgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => RepaintBoundary(
                child: _buildBudgetCard(context, budgets[index], currency),
              ),
            ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    BudgetLimitModel budget,
    String currency,
  ) {
    final spent = store.calculateBudgetSpent(budget);
    final limit = budget.monthlyLimit;
    final exceeded = spent > limit;
    final remaining = limit - spent;
    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final cat = store.getCategoryById(budget.categoryId);

    final palette = context.palette;
    final statusColor = exceeded
        ? palette.expense
        : ratio >= 0.85
        ? palette.warning
        : palette.income;

    final statusBg = exceeded
        ? palette.expenseSoftBg
        : ratio >= 0.85
        ? palette.warningSoftBg
        : palette.incomeSoftBg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(budget.colorValue).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    budget.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        cat == null
                            ? 'Todos los gastos'
                            : '${cat.name}${budget.subcategory != null ? ' • ${budget.subcategory}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exceeded ? 'Excedido' : 'En rango',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _showBudgetForm(context, existing: budget),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.edit_outlined, size: 17),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => store.deleteBudgetLimit(budget.id),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.delete_outline,
                      size: 17,
                      color: palette.expense,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: palette.track,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricCol(
                    context,
                    'Gastado',
                    CurrencyFormatter.format(spent, currency: currency),
                    statusColor,
                  ),
                ),
                Expanded(
                  child: _metricCol(
                    context,
                    'Límite',
                    CurrencyFormatter.format(limit, currency: currency),
                    null,
                  ),
                ),
                Expanded(
                  child: _metricCol(
                    context,
                    exceeded ? 'Exceso' : 'Restante',
                    CurrencyFormatter.format(
                      remaining.abs(),
                      currency: currency,
                    ),
                    exceeded ? palette.expense : palette.income,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(
    BuildContext context,
    String label,
    String value,
    Color? color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: context.palette.textMuted,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showBudgetForm(BuildContext context, {BudgetLimitModel? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _BudgetFormPage(store: store, existing: existing),
      ),
    );
  }
}

class _BudgetFormPage extends StatefulWidget {
  final FinanceStore store;
  final BudgetLimitModel? existing;
  const _BudgetFormPage({required this.store, this.existing});

  @override
  State<_BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<_BudgetFormPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _limitCtrl;
  String? _selectedCatId;
  String? _selectedSub;
  late int _selectedColor;
  late String _selectedEmoji;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _limitCtrl = TextEditingController(
      text: e != null ? e.monthlyLimit.toStringAsFixed(2) : '',
    );
    _selectedCatId = e?.categoryId;
    _selectedSub = e?.subcategory;
    _selectedColor = e?.colorValue ?? AppTheme.accountSolidColors[1];
    _selectedEmoji = e?.emoji ?? '🎯';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CategoryModel? currentCat;
    if (_selectedCatId != null) {
      currentCat = widget.store.getCategoryById(_selectedCatId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Nuevo Límite' : 'Editar Límite',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del límite *',
                      hintText: 'Ej. Salidas del mes, Restaurantes...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _limitCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'Monto mensual (${widget.store.settings.primaryCurrency}) *',
                      hintText: '1000.00',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Categoría',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('📊 Todos los gastos'),
                selected: _selectedCatId == null,
                selectedColor: context.palette.accentFill,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  color: _selectedCatId == null ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCatId = null;
                    _selectedSub = null;
                  });
                },
              ),
              ...widget.store.expenseCategories.map((c) {
                final selected = _selectedCatId == c.id;
                return ChoiceChip(
                  label: Text('${c.emoji} ${c.name}'),
                  selected: selected,
                  selectedColor: Color(c.colorValue),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCatId = c.id;
                      _selectedSub = null;
                    });
                  },
                );
              }),
            ],
          ),
          if (currentCat != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Subcategoría',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text('Todo ${currentCat.name}'),
                  selected: _selectedSub == null,
                  selectedColor: Color(currentCat.colorValue),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    color: _selectedSub == null ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedSub = null),
                ),
                ...currentCat.subcategories.map((sub) {
                  final selected = _selectedSub == sub;
                  return ChoiceChip(
                    label: Text(sub),
                    selected: selected,
                    selectedColor: Color(currentCat!.colorValue),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedSub = sub),
                  );
                }),
              ],
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.accentFill,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _save,
            child: const Text(
              'Guardar límite',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_limitCtrl.text.trim()) ?? 0.0;
    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre y un monto mayor a 0.'),
        ),
      );
      return;
    }

    widget.store.saveBudgetLimit(
      id: widget.existing?.id,
      name: name,
      monthlyLimit: amount,
      categoryId: _selectedCatId,
      subcategory: _selectedSub,
      colorValue: _selectedColor,
      emoji: _selectedEmoji,
    );
    Navigator.pop(context);
  }
}
