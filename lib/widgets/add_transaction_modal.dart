import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'accounts_management_modal.dart';

class AddTransactionModal {
  static Future<void> show(
    BuildContext context,
    FinanceStore store, {
    String? preselectedAccountId,
    TransactionType initialType = TransactionType.expense,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AddTransactionPage(
          store: store,
          preselectedAccountId: preselectedAccountId,
          initialType: initialType,
        ),
      ),
    );
  }
}

class _AddTransactionPage extends StatefulWidget {
  final FinanceStore store;
  final String? preselectedAccountId;
  final TransactionType initialType;

  const _AddTransactionPage({
    required this.store,
    this.preselectedAccountId,
    required this.initialType,
  });

  @override
  State<_AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<_AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  String? _selectedAccountId;
  String? _targetAccountId;
  String _selectedCurrency = 'GTQ';
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  int _installmentsCount = 1;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedCurrency = widget.store.settings.primaryCurrency;
    _initAccountSelection();
    _syncCategoriesForType();
  }

  void _initAccountSelection() {
    if (widget.store.accounts.isEmpty) {
      _selectedAccountId = null;
      _targetAccountId = null;
      return;
    }
    final defaultAcc =
        widget.store.getAccountById(widget.preselectedAccountId) ??
        widget.store.defaultAccount ??
        widget.store.accounts.first;
    _selectedAccountId = defaultAcc.id;

    if (widget.store.accounts.length > 1) {
      _targetAccountId = widget.store.accounts
          .firstWhere((a) => a.id != _selectedAccountId)
          .id;
    }
  }

  void _syncCategoriesForType() {
    final cats = _type == TransactionType.income
        ? widget.store.incomeCategories
        : widget.store.expenseCategories;
    if (cats.isNotEmpty) {
      _selectedCategoryId = cats.first.id;
      _selectedSubcategory = cats.first.subcategories.isNotEmpty
          ? cats.first.subcategories.first
          : 'General';
    } else {
      _selectedCategoryId = null;
      _selectedSubcategory = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        if (widget.store.accounts.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Nuevo Movimiento')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 44,
                      color: context.palette.accent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Primero crea una cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Necesitas tener al menos una cuenta para registrar movimientos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.palette.accentFill,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await AccountsManagementModal.showAccountForm(
                          context,
                          widget.store,
                        );
                        setState(_initAccountSelection);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_selectedAccountId == null ||
            widget.store.getAccountById(_selectedAccountId) == null) {
          _initAccountSelection();
        }

        final selectedAccount = widget.store.getAccountById(_selectedAccountId);
        final isCreditCard = selectedAccount?.type == AccountType.credit;
        final supportsDualCurrency =
            isCreditCard && (selectedAccount?.isDualCurrency ?? false);

        if (!supportsDualCurrency &&
            _selectedCurrency != widget.store.settings.primaryCurrency) {
          _selectedCurrency = widget.store.settings.primaryCurrency;
        }

        final categories = _type == TransactionType.income
            ? widget.store.incomeCategories
            : widget.store.expenseCategories;

        CategoryModel? currentCategory;
        if (_selectedCategoryId != null && categories.isNotEmpty) {
          currentCategory =
              widget.store.getCategoryById(_selectedCategoryId) ??
              categories.first;
          _selectedCategoryId = currentCategory.id;
        }

        if (currentCategory != null &&
            (_selectedSubcategory == null ||
                !currentCategory.subcategories.contains(
                  _selectedSubcategory,
                ))) {
          _selectedSubcategory = currentCategory.subcategories.isNotEmpty
              ? currentCategory.subcategories.first
              : 'General';
        }

        final rate = widget.store.settings.usdToGtqRate;
        final cashbackPct =
            (selectedAccount != null &&
                _type == TransactionType.expense &&
                currentCategory != null)
            ? selectedAccount.resolveCashbackPercent(
                categoryId: currentCategory.id,
                subcategory: _selectedSubcategory ?? '',
              )
            : 0.0;

        final palette = context.palette;
        final accentColor = _type == TransactionType.income
            ? palette.income
            : _type == TransactionType.expense
            ? palette.expense
            : palette.accent;
        final accentFillColor = _type == TransactionType.income
            ? AppTheme.incomeSolid
            : _type == TransactionType.expense
            ? AppTheme.expenseSolid
            : palette.accentFill;

        return Scaffold(
          appBar: AppBar(title: const Text('Nuevo Movimiento')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionType>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Gasto'),
                      ),
                      const ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Ingreso'),
                      ),
                      if (widget.store.accounts.length > 1)
                        const ButtonSegment(
                          value: TransactionType.transfer,
                          label: Text('Transferir'),
                        ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (set) {
                      setState(() {
                        _type = set.first;
                        _syncCategoriesForType();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Monto ($_selectedCurrency)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            if (supportsDualCurrency)
                              SegmentedButton<String>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(value: 'GTQ', label: Text('Q')),
                                  ButtonSegment(
                                    value: 'USD',
                                    label: Text('\$'),
                                  ),
                                ],
                                selected: {_selectedCurrency},
                                onSelectionChanged: (s) =>
                                    setState(() => _selectedCurrency = s.first),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: _selectedCurrency == 'USD'
                                ? '\$ '
                                : 'Q ',
                            prefixStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0) {
                              return 'Ingresa un monto mayor a 0';
                            }
                            return null;
                          },
                        ),
                        // Isolated live calculation banner so typing never rebuilds the form
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _amountController,
                          builder: (context, value, _) {
                            final typedAmount =
                                double.tryParse(value.text.trim()) ?? 0.0;
                            final convertedInGtq = _selectedCurrency == 'USD'
                                ? typedAmount * rate
                                : typedAmount;
                            final cashbackAmount = cashbackPct > 0
                                ? convertedInGtq * (cashbackPct / 100.0)
                                : 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (supportsDualCurrency &&
                                    _selectedCurrency == 'USD') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Conversión Dúo (TC Q${rate.toStringAsFixed(2)}): se cargarán ${CurrencyFormatter.format(convertedInGtq, currency: 'GTQ')}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.accent,
                                    ),
                                  ),
                                ],
                                if (cashbackPct > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.incomeSoftBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      convertedInGtq > 0
                                          ? 'Cashback automático (${cashbackPct.toStringAsFixed(cashbackPct % 1 == 0 ? 0 : 1)}%): -${CurrencyFormatter.format(cashbackAmount, currency: widget.store.settings.primaryCurrency)} • Cargo neto: ${CurrencyFormatter.format(convertedInGtq - cashbackAmount, currency: widget.store.settings.primaryCurrency)}'
                                          : 'Cashback aplicable en esta categoría: ${cashbackPct.toStringAsFixed(cashbackPct % 1 == 0 ? 0 : 1)}%',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette.income,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Text(
                  _type == TransactionType.transfer
                      ? 'Cuenta de origen'
                      : 'Cuenta o tarjeta',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                RepaintBoundary(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.store.accounts.map((acc) {
                      final selected = acc.id == _selectedAccountId;
                      return ChoiceChip(
                        label: Text('${acc.emoji} ${acc.name}'),
                        selected: selected,
                        selectedColor: Color(acc.colorValue),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedAccountId = acc.id;
                            if (_targetAccountId == acc.id &&
                                widget.store.accounts.length > 1) {
                              _targetAccountId = widget.store.accounts
                                  .firstWhere((a) => a.id != acc.id)
                                  .id;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                if (_type == TransactionType.transfer &&
                    widget.store.accounts.length > 1) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Cuenta de destino',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.store.accounts
                        .where((a) => a.id != _selectedAccountId)
                        .map((acc) {
                          final selected = acc.id == _targetAccountId;
                          return ChoiceChip(
                            label: Text('${acc.emoji} ${acc.name}'),
                            selected: selected,
                            selectedColor: Color(acc.colorValue),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setState(() => _targetAccountId = acc.id),
                          );
                        })
                        .toList(),
                  ),
                ],

                if (isCreditCard && _type == TransactionType.expense) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Cuotas',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RepaintBoundary(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [1, 2, 3, 6, 10, 12, 18, 24, 36].map((months) {
                        final selected = _installmentsCount == months;
                        return ChoiceChip(
                          label: Text(months == 1 ? 'Contado' : '${months}m'),
                          selected: selected,
                          selectedColor: palette.accentFill,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              setState(() => _installmentsCount = months),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_installmentsCount > 1)
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _amountController,
                      builder: (context, value, _) {
                        final typedAmount =
                            double.tryParse(value.text.trim()) ?? 0.0;
                        final convertedInGtq = _selectedCurrency == 'USD'
                            ? typedAmount * rate
                            : typedAmount;
                        if (convertedInGtq <= 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Cuota: ${CurrencyFormatter.format(convertedInGtq / _installmentsCount, currency: widget.store.settings.primaryCurrency)}/mes por $_installmentsCount meses',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: palette.accent,
                            ),
                          ),
                        );
                      },
                    ),
                ],

                if (_type != TransactionType.transfer &&
                    currentCategory != null) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Categoría',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RepaintBoundary(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.map((cat) {
                        final selected = cat.id == currentCategory!.id;
                        return ChoiceChip(
                          label: Text('${cat.emoji} ${cat.name}'),
                          selected: selected,
                          selectedColor: Color(cat.colorValue),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _selectedSubcategory =
                                  cat.subcategories.isNotEmpty
                                  ? cat.subcategories.first
                                  : 'General';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Subcategoría',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RepaintBoundary(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: currentCategory.subcategories.map((sub) {
                        final selected = _selectedSubcategory == sub;
                        return ChoiceChip(
                          label: Text(sub),
                          selected: selected,
                          selectedColor: Color(currentCategory!.colorValue),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedSubcategory = sub),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Nota (Opcional)',
                  ),
                ),

                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentFillColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _submit(currentCategory),
                  child: Text(
                    _type == TransactionType.income
                        ? 'Guardar ingreso'
                        : _type == TransactionType.expense
                        ? 'Guardar gasto'
                        : 'Confirmar transferencia',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit(CategoryModel? category) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) return;

    final originalAmount =
        double.tryParse(_amountController.text.trim()) ?? 0.0;

    widget.store.addTransaction(
      accountId: _selectedAccountId!,
      targetAccountId: _type == TransactionType.transfer
          ? _targetAccountId
          : null,
      type: _type,
      originalAmount: originalAmount,
      originalCurrency: _selectedCurrency,
      categoryId: category?.id ?? 'cat_other',
      categoryName: category?.name ?? 'General',
      subcategory: _selectedSubcategory ?? 'General',
      note: _noteController.text.trim(),
      date: DateTime.now(),
      installmentsTotal: _installmentsCount,
    );

    Navigator.pop(context);
  }
}
