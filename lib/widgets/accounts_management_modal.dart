import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AccountsManagementModal {
  static Future<void> show(BuildContext context, FinanceStore store) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AccountsManagementPage(store: store),
      ),
    );
  }

  static Future<void> showAccountForm(
    BuildContext context,
    FinanceStore store, {
    AccountModel? existing,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AccountFormPage(store: store, existing: existing),
      ),
    );
  }
}

class _AccountsManagementPage extends StatelessWidget {
  final FinanceStore store;
  const _AccountsManagementPage({required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final currency = store.settings.primaryCurrency;
        final accounts = store.accounts;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Administrar Cuentas'),
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
                  onPressed: () =>
                      AccountsManagementModal.showAccountForm(context, store),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Nueva'),
                ),
              ),
            ],
          ),
          body: accounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.palette.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 28,
                            color: context.palette.accent,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sin cuentas registradas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Agrega tus cuentas de débito, ahorro o tarjetas de crédito.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.palette.accentFill,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () =>
                              AccountsManagementModal.showAccountForm(
                                context,
                                store,
                              ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    return RepaintBoundary(
                      child: _buildAccountItem(context, acc, currency),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    AccountModel acc,
    String currency,
  ) {
    final solidColor = Color(acc.colorValue);
    final isCredit = acc.type == AccountType.credit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: solidColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(acc.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              acc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (acc.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.accent.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Principal',
                                style: TextStyle(
                                  color: context.palette.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _typeSubtitle(acc),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Editar',
                  onPressed: () => AccountsManagementModal.showAccountForm(
                    context,
                    store,
                    existing: acc,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Eliminar',
                  onPressed: () => _confirmDelete(context, acc),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: context.palette.expense,
                  ),
                ),
              ],
            ),
            if (acc.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                acc.description,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (isCredit) ...[
              Row(
                children: [
                  Expanded(
                    child: _statColumn(
                      context,
                      'Disponible',
                      CurrencyFormatter.format(
                        acc.availableCredit,
                        currency: currency,
                      ),
                      context.palette.income,
                    ),
                  ),
                  Expanded(
                    child: _statColumn(
                      context,
                      'Consumido',
                      CurrencyFormatter.format(
                        acc.currentBalance,
                        currency: currency,
                      ),
                      context.palette.expense,
                    ),
                  ),
                  Expanded(
                    child: _statColumn(
                      context,
                      'Límite',
                      CurrencyFormatter.format(
                        acc.creditLimit,
                        currency: currency,
                      ),
                      null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Corte: Día ${acc.cutoffDay}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: acc.isPaidThisCycle
                          ? context.palette.incomeSoftBg
                          : context.palette.expenseSoftBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      acc.isPaidThisCycle ? 'Pagada' : 'Pendiente',
                      style: TextStyle(
                        color: acc.isPaidThisCycle
                            ? context.palette.income
                            : context.palette.expense,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (acc.hasCashback) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.incomeSoftBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.redeem_rounded,
                            size: 14,
                            color: context.palette.income,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Cashback activo (${acc.defaultCashbackPercent.toStringAsFixed(acc.defaultCashbackPercent % 1 == 0 ? 0 : 1)}% en todo lo demás)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.palette.income,
                              ),
                            ),
                          ),
                          if (acc.accumulatedCashback > 0)
                            Text(
                              'Ahorrado: ${CurrencyFormatter.format(acc.accumulatedCashback, currency: currency)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: context.palette.income,
                              ),
                            ),
                        ],
                      ),
                      if (acc.cashbackRules.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          acc.cashbackRules
                              .map((r) => r.displayLabel)
                              .join(' • '),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: context.palette.onIncomeSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _statColumn(
                      context,
                      'Saldo disponible',
                      CurrencyFormatter.format(
                        acc.currentBalance,
                        currency: currency,
                      ),
                      null,
                    ),
                  ),
                  if (acc.type == AccountType.savings)
                    Expanded(
                      child: _statColumn(
                        context,
                        'Rendimiento (${acc.annualInterestRate.toStringAsFixed(1)}%)',
                        '+${CurrencyFormatter.format(acc.currentBalance * (acc.annualInterestRate / 100), currency: currency)}/año',
                        context.palette.income,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (!acc.isDefault)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => store.setDefaultAccount(acc.id),
                    child: const Text('Usar como principal'),
                  ),
                if (isCredit) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => store.toggleCreditCardPaidStatus(
                      acc.id,
                      !acc.isPaidThisCycle,
                    ),
                    child: Text(
                      acc.isPaidThisCycle
                          ? 'Marcar pendiente'
                          : 'Marcar pagada',
                    ),
                  ),
                  if (acc.currentBalance > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _showPayCardSheet(context, acc),
                      child: const Text('Abonar tarjeta'),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeSubtitle(AccountModel acc) {
    final suffix = acc.cardLast4Digits.isNotEmpty
        ? ' • •••• ${acc.cardLast4Digits}'
        : '';
    switch (acc.type) {
      case AccountType.debit:
        return 'Cuenta de débito$suffix';
      case AccountType.savings:
        return 'Ahorro • ${acc.annualInterestRate.toStringAsFixed(1)}% anual$suffix';
      case AccountType.credit:
        return 'Crédito • ${acc.isDualCurrency ? 'Dúo (Q / \$)' : 'Solo Q'}$suffix';
    }
  }

  Widget _statColumn(
    BuildContext context,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AccountModel acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta', style: TextStyle(fontSize: 16)),
        content: Text(
          '¿Eliminar "${acc.name}" y sus movimientos?',
          style: const TextStyle(fontSize: 13),
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
              store.deleteAccount(acc.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showPayCardSheet(BuildContext context, AccountModel creditAcc) {
    final debitAccounts = store.accounts
        .where((a) => a.type != AccountType.credit)
        .toList();

    if (debitAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero agrega una cuenta de débito o ahorro.'),
        ),
      );
      return;
    }

    String selectedSourceId = debitAccounts.first.id;
    final amountCtrl = TextEditingController(
      text: creditAcc.currentBalance.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            'Pagar ${creditAcc.name}',
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuenta de origen:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: debitAccounts.map((a) {
                  final sel = a.id == selectedSourceId;
                  return ChoiceChip(
                    label: Text('${a.emoji} ${a.name}'),
                    selected: sel,
                    selectedColor: context.palette.accentFill,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : null,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => selectedSourceId = a.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Monto (${store.settings.primaryCurrency})',
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
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amount > 0) {
                  store.payCreditCardFromAccount(
                    creditAccountId: creditAcc.id,
                    sourceAccountId: selectedSourceId,
                    amountInPrimary: amount,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Pagar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFormPage extends StatefulWidget {
  final FinanceStore store;
  final AccountModel? existing;

  const _AccountFormPage({required this.store, this.existing});

  @override
  State<_AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<_AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _initialBalanceController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _defaultCashbackController;
  late final TextEditingController _cardLast4Controller;
  late final Listenable _previewListenable;

  late AccountType _selectedType;
  late int _selectedColor;
  late String _selectedEmoji;
  late bool _isDefault;
  late int _cutoffDay;
  late bool _isPaidThisCycle;
  late bool _isDualCurrency;
  late bool _hasCashback;
  late List<CashbackRule> _cashbackRules;

  // Inline cashback rule composer state (avoids bottom-sheet + keyboard jank)
  bool _isAddingCashbackRule = false;
  late TextEditingController _rulePctController;
  String? _ruleCategoryId;
  String? _ruleSubcategory;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _initialBalanceController = TextEditingController(
      text: e != null ? e.currentBalance.toStringAsFixed(2) : '',
    );
    _interestRateController = TextEditingController(
      text: e != null && e.annualInterestRate > 0
          ? e.annualInterestRate.toStringAsFixed(2)
          : '',
    );
    _creditLimitController = TextEditingController(
      text: e != null && e.creditLimit > 0
          ? e.creditLimit.toStringAsFixed(2)
          : '',
    );
    _defaultCashbackController = TextEditingController(
      text: e != null && e.defaultCashbackPercent > 0
          ? (e.defaultCashbackPercent % 1 == 0
                ? e.defaultCashbackPercent.toInt().toString()
                : e.defaultCashbackPercent.toStringAsFixed(1))
          : '1',
    );
    _rulePctController = TextEditingController(text: '5');
    _cardLast4Controller = TextEditingController(
      text: e?.cardLast4Digits ?? '',
    );

    _previewListenable = Listenable.merge([
      _nameController,
      _initialBalanceController,
      _creditLimitController,
    ]);

    _selectedType = e?.type ?? AccountType.debit;
    _selectedColor = e?.colorValue ?? AppTheme.accountSolidColors.first;
    _selectedEmoji = e?.emoji ?? AppTheme.accountEmojis.first;
    _isDefault = e?.isDefault ?? widget.store.accounts.isEmpty;
    _cutoffDay = e?.cutoffDay ?? 15;
    _isPaidThisCycle = e?.isPaidThisCycle ?? false;
    _isDualCurrency = e?.isDualCurrency ?? false;
    _hasCashback = e?.hasCashback ?? false;
    _cashbackRules = List<CashbackRule>.from(e?.cashbackRules ?? const []);

    final expenseCats = widget.store.expenseCategories;
    if (expenseCats.isNotEmpty) {
      _ruleCategoryId = expenseCats.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _initialBalanceController.dispose();
    _interestRateController.dispose();
    _creditLimitController.dispose();
    _defaultCashbackController.dispose();
    _rulePctController.dispose();
    _cardLast4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = _selectedType == AccountType.credit;
    final isSavings = _selectedType == AccountType.savings;
    final currency = widget.store.settings.primaryCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Nueva Cuenta' : 'Editar Cuenta',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
          children: [
            // Isolated Preview Card: only this small widget rebuilds when typing name/balance/limit
            RepaintBoundary(
              child: ListenableBuilder(
                listenable: _previewListenable,
                builder: (context, _) {
                  final previewName = _nameController.text.trim().isEmpty
                      ? 'Nombre de la cuenta'
                      : _nameController.text.trim();
                  final previewBalance =
                      double.tryParse(_initialBalanceController.text.trim()) ??
                      0.0;
                  final previewLimit =
                      double.tryParse(_creditLimitController.text.trim()) ??
                      0.0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Color(_selectedColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                previewName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                isCredit
                                    ? 'Crédito ${_isDualCurrency ? '• Dúo (Q/\$)' : '• Solo Q'}'
                                    : isSavings
                                    ? 'Cuenta de ahorro'
                                    : 'Cuenta de débito',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isCredit ? 'Límite' : 'Saldo',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10.5,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                isCredit ? previewLimit : previewBalance,
                                currency: currency,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Account Type Selector
            const Text(
              'Tipo de cuenta',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AccountType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AccountType.debit,
                    label: Text('Débito'),
                  ),
                  ButtonSegment(
                    value: AccountType.savings,
                    label: Text('Ahorro'),
                  ),
                  ButtonSegment(
                    value: AccountType.credit,
                    label: Text('Crédito'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() => _selectedType = set.first);
                },
              ),
            ),
            const SizedBox(height: 14),

            // Basic Fields Card (no setState on keystrokes!)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la cuenta *',
                        hintText: 'Ej. Monetaria, Ahorro, Visa...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    if (isCredit) ...[
                      TextFormField(
                        controller: _creditLimitController,
                        style: const TextStyle(fontSize: 13.5),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Límite de crédito ($currency) *',
                          hintText: '0.00',
                        ),
                        validator: (v) {
                          final val = double.tryParse(v ?? '');
                          if (val == null || val <= 0) {
                            return 'Ingresa el límite de crédito';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(
                      controller: _initialBalanceController,
                      style: const TextStyle(fontSize: 13.5),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: isCredit
                            ? 'Saldo consumido actual ($currency)'
                            : 'Saldo inicial ($currency) *',
                        hintText: '0.00',
                      ),
                      validator: (v) {
                        if (isCredit && (v == null || v.trim().isEmpty)) {
                          return null;
                        }
                        if (double.tryParse(v ?? '') == null) {
                          return 'Ingresa un monto válido';
                        }
                        return null;
                      },
                    ),
                    if (isSavings) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _interestRateController,
                        style: const TextStyle(fontSize: 13.5),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Rendimiento anual (%) *',
                          hintText: 'Ej. 5.0',
                          suffixText: '%',
                        ),
                        validator: (v) => double.tryParse(v ?? '') == null
                            ? 'Ingresa el porcentaje anual'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        labelText: 'Descripción (Opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cardLast4Controller,
                      style: const TextStyle(fontSize: 13.5),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText:
                            'Últimos 4 dígitos de tarjeta (Opcional - Wallet/SMS)',
                        hintText: 'Ej. 4521',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Credit Card Options & Cashback
            if (isCredit) ...[
              const SizedBox(height: 14),
              const Text(
                'Opciones de tarjeta de crédito',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Fecha de corte mensual',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _pickDayOfMonth(
                              title: 'Selecciona el día de corte',
                              current: _cutoffDay,
                              onSelected: (d) => setState(() => _cutoffDay = d),
                            ),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                            ),
                            label: Text('Día $_cutoffDay'),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      const Text(
                        'Moneda de cobro',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Solo Quetzales'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Dúo (Q y \$)'),
                            ),
                          ],
                          selected: {_isDualCurrency},
                          onSelectionChanged: (s) =>
                              setState(() => _isDualCurrency = s.first),
                        ),
                      ),
                      const Divider(height: 18),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          '¿Ya se pagó este corte?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          _isPaidThisCycle ? 'Pagada' : 'Pendiente de pago',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _isPaidThisCycle
                                ? context.palette.income
                                : context.palette.expense,
                          ),
                        ),
                        value: _isPaidThisCycle,
                        onChanged: (v) => setState(() => _isPaidThisCycle = v),
                      ),
                      const Divider(height: 18),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'Configurar Cashback automático',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Descuenta automáticamente el cashback al pagar con esta tarjeta',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        value: _hasCashback,
                        onChanged: (v) => setState(() {
                          _hasCashback = v;
                          if (!v) _isAddingCashbackRule = false;
                        }),
                      ),
                      if (_hasCashback) ...[
                        const SizedBox(height: 10),
                        _buildCashbackSection(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Appearance & Default Card wrapped in RepaintBoundary
            const SizedBox(height: 14),
            const Text(
              'Apariencia',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            RepaintBoundary(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AppTheme.accountSolidColors.map((colorVal) {
                          final selected = _selectedColor == colorVal;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedColor = colorVal),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ícono',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppTheme.accountEmojis.map((emoji) {
                          final selected = _selectedEmoji == emoji;
                          return InkWell(
                            onTap: () => setState(() => _selectedEmoji = emoji),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Color(_selectedColor)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? Color(_selectedColor)
                                      : context.palette.outline,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 20),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'Cuenta principal predeterminada',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Color(_selectedColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _save,
              child: Text(
                widget.existing == null ? 'Guardar cuenta' : 'Guardar cambios',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashbackSection(BuildContext context) {
    final expenseCats = widget.store.expenseCategories;
    final selectedRuleCat =
        widget.store.getCategoryById(_ruleCategoryId) ??
        (expenseCats.isNotEmpty ? expenseCats.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default cashback row + quick presets
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _defaultCashbackController,
                style: const TextStyle(fontSize: 13),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '% en todo lo demás *',
                  hintText: '1',
                  suffixText: '%',
                ),
                validator: (v) {
                  if (!_hasCashback) return null;
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 0) {
                    return 'Inválido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            for (final preset in const ['0', '1', '1.5', '2']) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ActionChip(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(
                    '$preset%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    _defaultCashbackController.text = preset;
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Porcentajes por categoría / subcategoría',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(
                  () => _isAddingCashbackRule = !_isAddingCashbackRule,
                );
              },
              icon: Icon(
                _isAddingCashbackRule
                    ? Icons.expand_less_rounded
                    : Icons.add_rounded,
                size: 16,
              ),
              label: Text(_isAddingCashbackRule ? 'Cerrar' : 'Agregar %'),
            ),
          ],
        ),
        if (_cashbackRules.isEmpty && !_isAddingCashbackRule)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Ej: 5% en Alimentación, 3% o 7% en Gasolina...',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        if (_cashbackRules.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _cashbackRules.map((rule) {
              return InputChip(
                backgroundColor: context.palette.incomeSoftBg,
                label: Text(
                  rule.displayLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: context.palette.income,
                  ),
                ),
                deleteIconColor: context.palette.income,
                onDeleted: () {
                  setState(() {
                    _cashbackRules.removeWhere((r) => r.id == rule.id);
                  });
                },
              );
            }).toList(),
          ),
        ],

        // Fast inline rule builder (no modal sheet or keyboard animation stutter!)
        if (_isAddingCashbackRule && selectedRuleCat != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.palette.income.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Porcentaje de Cashback',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: 82,
                      child: TextField(
                        controller: _rulePctController,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          suffixText: '%',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final p in const [
                              '2',
                              '3',
                              '5',
                              '7',
                              '10',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  label: Text(
                                    '$p%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () {
                                    _rulePctController.text = p;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '2. Categoría',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: expenseCats.map((cat) {
                    final sel = cat.id == selectedRuleCat.id;
                    return ChoiceChip(
                      label: Text('${cat.emoji} ${cat.name}'),
                      selected: sel,
                      selectedColor: Color(cat.colorValue),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: sel ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _ruleCategoryId = cat.id;
                          _ruleSubcategory = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text(
                  '3. Toda la categoría o subcategoría específica',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text('Todo ${selectedRuleCat.name}'),
                      selected: _ruleSubcategory == null,
                      selectedColor: Color(selectedRuleCat.colorValue),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: _ruleSubcategory == null ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => _ruleSubcategory = null),
                    ),
                    ...selectedRuleCat.subcategories.map((sub) {
                      final sel = _ruleSubcategory == sub;
                      return ChoiceChip(
                        label: Text(sub),
                        selected: sel,
                        selectedColor: Color(selectedRuleCat.colorValue),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: sel ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) =>
                            setState(() => _ruleSubcategory = sub),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.incomeSolid,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onPressed: () => _confirmAddInlineRule(selectedRuleCat),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Confirmar regla de Cashback',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _confirmAddInlineRule(CategoryModel selectedCat) {
    final pct = double.tryParse(_rulePctController.text.trim()) ?? 0.0;
    if (pct <= 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cashbackRules.removeWhere(
        (r) =>
            r.categoryId == selectedCat.id && r.subcategory == _ruleSubcategory,
      );
      _cashbackRules.add(
        CashbackRule(
          id: 'cb_${DateTime.now().microsecondsSinceEpoch}',
          categoryId: selectedCat.id,
          categoryName: selectedCat.name,
          subcategory: _ruleSubcategory,
          percentage: pct,
        ),
      );
      _isAddingCashbackRule = false;
    });
  }

  void _pickDayOfMonth({
    required String title,
    required int current,
    required ValueChanged<int> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(31, (index) {
                  final day = index + 1;
                  final selected = day == current;
                  return ChoiceChip(
                    label: Text('$day'),
                    selected: selected,
                    selectedColor: context.palette.accentFill,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      onSelected(day);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final enteredBalance =
        double.tryParse(_initialBalanceController.text.trim()) ?? 0.0;
    final interest =
        double.tryParse(_interestRateController.text.trim()) ?? 0.0;
    final limit = double.tryParse(_creditLimitController.text.trim()) ?? 0.0;
    final defaultCb =
        double.tryParse(_defaultCashbackController.text.trim()) ?? 0.0;
    final isCredit = _selectedType == AccountType.credit;

    widget.store.saveAccount(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      type: _selectedType,
      initialBalance: enteredBalance,
      explicitCurrentBalance: enteredBalance,
      colorValue: _selectedColor,
      emoji: _selectedEmoji,
      isDefault: _isDefault,
      annualInterestRate: _selectedType == AccountType.savings ? interest : 0.0,
      creditLimit: isCredit ? limit : 0.0,
      cutoffDay: _cutoffDay,
      isPaidThisCycle: _isPaidThisCycle,
      isDualCurrency: isCredit ? _isDualCurrency : false,
      hasCashback: isCredit ? _hasCashback : false,
      defaultCashbackPercent: isCredit && _hasCashback ? defaultCb : 0.0,
      cashbackRules: isCredit && _hasCashback ? _cashbackRules : const [],
      cardLast4Digits: _cardLast4Controller.text.trim(),
    );
    Navigator.pop(context);
  }
}
