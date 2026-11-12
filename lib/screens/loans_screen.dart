import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/loan_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'settings_screen.dart';

class LoansScreen extends StatefulWidget {
  final FinanceStore store;
  const LoansScreen({super.key, required this.store});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String _statusFilter = 'all'; // 'all', 'lent', 'borrowed', 'settled'
  String? _selectedPerson;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final primaryCurrency = store.settings.primaryCurrency;
    final rate = store.settings.usdToGtqRate;
    final allLoans = store.loans;
    final people = store.knownPeople;

    if (_selectedPerson != null && !people.contains(_selectedPerson)) {
      _selectedPerson = null;
    }

    double totalToCollectGtq = 0.0;
    double totalToPayGtq = 0.0;
    int activeLoansCount = 0;

    for (final loan in allLoans) {
      if (loan.isSettled) continue;
      activeLoansCount++;
      final rem = loan.remainingAmount;
      final inPrimary = loan.currency == 'USD' ? rem * rate : rem;
      if (loan.kind == LoanKind.lent) {
        totalToCollectGtq += inPrimary;
      } else {
        totalToPayGtq += inPrimary;
      }
    }

    final filteredLoans = allLoans.where((l) {
      if (_selectedPerson != null &&
          l.personName.toLowerCase() != _selectedPerson!.toLowerCase()) {
        return false;
      }
      if (_statusFilter == 'lent') {
        return l.kind == LoanKind.lent && !l.isSettled;
      }
      if (_statusFilter == 'borrowed') {
        return l.kind == LoanKind.borrowed && !l.isSettled;
      }
      if (_statusFilter == 'settled') {
        return l.isSettled;
      }
      return true;
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: SettingsScreen.buildHeaderButton(context, store),
        titleSpacing: 0,
        title: const Text('Préstamos'),
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
              onPressed: () => _openLoanForm(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nuevo'),
            ),
          ),
        ],
      ),
      body: allLoans.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
              children: [
                // 1. Summary Hero Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.palette.heroBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Me deben (Por cobrar)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(
                                  totalToCollectGtq,
                                  currency: primaryCurrency,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yo debo (Por pagar)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(
                                  totalToPayGtq,
                                  currency: primaryCurrency,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$activeLoansCount activos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Filter by Type
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Todos', 'all'),
                      const SizedBox(width: 6),
                      _filterChip('Presté (Me deben)', 'lent'),
                      const SizedBox(width: 6),
                      _filterChip('Me prestaron (Debo)', 'borrowed'),
                      const SizedBox(width: 6),
                      _filterChip('Saldados', 'settled'),
                    ],
                  ),
                ),

                // 3. Filter by Person
                if (people.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: const Text('👥 Todas las personas'),
                            selected: _selectedPerson == null,
                            selectedColor: context.palette.accentFill,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: _selectedPerson == null
                                  ? Colors.white
                                  : null,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedPerson = null),
                          ),
                        ),
                        ...people.map((person) {
                          final sel = _selectedPerson == person;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('👤 $person'),
                              selected: sel,
                              selectedColor: context.palette.accentFill,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: sel ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => setState(
                                () => _selectedPerson = sel ? null : person,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                if (filteredLoans.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No hay préstamos con el filtro seleccionado.',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  for (final loan in filteredLoans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RepaintBoundary(
                        child: _buildLoanCard(context, loan),
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: context.palette.accentFill,
      labelStyle: TextStyle(
        fontSize: 11.5,
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
                Icons.handshake_outlined,
                size: 26,
                color: context.palette.accent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Control de Préstamos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra cuando prestas dinero a alguien o cuando te prestan dinero, selecciona a la persona y lleva el control de abonos y fechas de pago.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.incomeSolid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () =>
                      _openLoanForm(context, initialKind: LoanKind.lent),
                  icon: const Icon(Icons.call_made_rounded, size: 16),
                  label: const Text('Presté Dinero'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.expenseSolid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () =>
                      _openLoanForm(context, initialKind: LoanKind.borrowed),
                  icon: const Icon(Icons.call_received_rounded, size: 16),
                  label: const Text('Me Prestaron'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, LoanModel loan) {
    final palette = context.palette;
    final isLent = loan.kind == LoanKind.lent;
    final isSettled = loan.isSettled;
    final isOverdue = loan.isOverdue;

    final mainColor = isSettled
        ? palette.income
        : isOverdue
        ? palette.expense
        : (isLent ? palette.income : palette.warning);
    final softBg = isSettled
        ? palette.incomeSoftBg
        : isOverdue
        ? palette.expenseSoftBg
        : (isLent ? palette.incomeSoftBg : palette.warningSoftBg);

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
                    color: softBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loan.personEmoji,
                    style: const TextStyle(fontSize: 19),
                  ),
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
                              loan.personName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isLent
                                  ? palette.incomeSoftBg
                                  : palette.expenseSoftBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isLent ? 'ME DEBE' : 'YO DEBO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isLent
                                    ? palette.income
                                    : palette.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (loan.concept.isNotEmpty) loan.concept,
                          if (loan.dueDate != null)
                            'Vence: ${CurrencyFormatter.formatShortDate(loan.dueDate!)}',
                          if (loan.installmentsCount > 1)
                            '${loan.installmentsCount} cuotas',
                          if (loan.interestPercent > 0)
                            '+${loan.interestPercent.toStringAsFixed(1)}% interés',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue
                              ? palette.expense
                              : palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSettled
                        ? 'Saldado'
                        : isOverdue
                        ? 'Vencido'
                        : 'Pendiente',
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: loan.progressRatio,
                minHeight: 6,
                backgroundColor: palette.track,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricCol(
                    'Pendiente',
                    CurrencyFormatter.format(
                      loan.remainingAmount,
                      currency: loan.currency,
                    ),
                    isSettled ? palette.income : mainColor,
                  ),
                ),
                Expanded(
                  child: _metricCol(
                    'Abonado',
                    CurrencyFormatter.format(
                      loan.paidAmount,
                      currency: loan.currency,
                    ),
                    palette.income,
                  ),
                ),
                Expanded(
                  child: _metricCol(
                    'Total',
                    CurrencyFormatter.format(
                      loan.totalAmount,
                      currency: loan.currency,
                    ),
                    null,
                  ),
                ),
              ],
            ),
            if (loan.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'Último abono: ${CurrencyFormatter.format(loan.payments.first.amount, currency: loan.currency)} (${CurrencyFormatter.formatShortDate(loan.payments.first.date)}) • ${loan.payments.length} abono(s)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isSettled) ...[
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: palette.incomeSoftBg,
                      foregroundColor: palette.income,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () => _showPaymentDialog(context, loan),
                    icon: const Icon(Icons.payments_outlined, size: 15),
                    label: Text(
                      isLent ? 'Registrar cobro' : 'Registrar abono',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _openLoanForm(context, existing: loan),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.edit_outlined, size: 17),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => widget.store.deleteLoan(loan.id),
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
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String label, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: context.palette.textMuted),
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

  void _showPaymentDialog(BuildContext context, LoanModel loan) {
    final store = widget.store;
    final isLent = loan.kind == LoanKind.lent;
    final suggestedInstallment = loan.installmentsCount > 1
        ? (loan.totalAmount / loan.installmentsCount).clamp(
            0.0,
            loan.remainingAmount,
          )
        : loan.remainingAmount;

    final amountCtrl = TextEditingController(
      text: suggestedInstallment.toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController();
    String? selectedAccountId = loan.accountId ?? store.defaultAccount?.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isLent
                ? 'Cobrar a ${loan.personName}'
                : 'Abonar a ${loan.personName}',
            style: const TextStyle(fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo pendiente: ${CurrencyFormatter.format(loan.remainingAmount, currency: loan.currency)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Monto (${loan.currency})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        amountCtrl.text = loan.remainingAmount.toStringAsFixed(
                          2,
                        );
                      },
                      child: const Text(
                        'Total',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
                if (store.accounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    isLent
                        ? 'Cuenta donde recibes el dinero:'
                        : 'Cuenta de donde pagas:',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('Solo registro'),
                        selected: selectedAccountId == null,
                        selectedColor: context.palette.accentFill,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: selectedAccountId == null
                              ? Colors.white
                              : null,
                        ),
                        onSelected: (_) =>
                            setDialogState(() => selectedAccountId = null),
                      ),
                      ...store.accounts.map((a) {
                        final sel = selectedAccountId == a.id;
                        return ChoiceChip(
                          label: Text('${a.emoji} ${a.name}'),
                          selected: sel,
                          selectedColor: Color(a.colorValue),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: sel ? Colors.white : null,
                          ),
                          onSelected: (_) =>
                              setDialogState(() => selectedAccountId = a.id),
                        );
                      }),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: const InputDecoration(
                    labelText: 'Nota (Opcional)',
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
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.incomeSolid,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final val = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (val > 0) {
                  store.registerLoanPayment(
                    loanId: loan.id,
                    amount: val,
                    accountId: selectedAccountId,
                    note: noteCtrl.text.trim(),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openLoanForm(
    BuildContext context, {
    LoanModel? existing,
    LoanKind initialKind = LoanKind.lent,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _LoanFormPage(
          store: widget.store,
          existing: existing,
          initialKind: initialKind,
        ),
      ),
    );
  }
}

class _LoanFormPage extends StatefulWidget {
  final FinanceStore store;
  final LoanModel? existing;
  final LoanKind initialKind;

  const _LoanFormPage({
    required this.store,
    this.existing,
    this.initialKind = LoanKind.lent,
  });

  @override
  State<_LoanFormPage> createState() => _LoanFormPageState();
}

class _LoanFormPageState extends State<_LoanFormPage> {
  static const List<String> _personEmojis = [
    '👤',
    '👨',
    '👩',
    '🧑',
    '🤝',
    '👨‍💼',
    '👩‍💼',
    '🏦',
  ];

  late final TextEditingController _personCtrl;
  late final TextEditingController _conceptCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _interestCtrl;
  late final Listenable _calcListenable;

  late LoanKind _kind;
  late String _personEmoji;
  late String _currency;
  String? _selectedAccountId;
  bool _affectAccountNow = true;
  DateTime? _dueDate;
  late int _installmentsCount;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kind = e?.kind ?? widget.initialKind;
    _personEmoji = e?.personEmoji ?? '👤';
    _currency = e?.currency ?? widget.store.settings.primaryCurrency;
    _selectedAccountId = e?.accountId ?? widget.store.defaultAccount?.id;
    _affectAccountNow = e == null && widget.store.accounts.isNotEmpty;
    _dueDate = e?.dueDate;
    _installmentsCount = e?.installmentsCount ?? 1;

    _personCtrl = TextEditingController(text: e?.personName ?? '');
    _conceptCtrl = TextEditingController(text: e?.concept ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.principalAmount.toStringAsFixed(2) : '',
    );
    _interestCtrl = TextEditingController(
      text: e != null && e.interestPercent > 0
          ? (e.interestPercent % 1 == 0
                ? e.interestPercent.toInt().toString()
                : e.interestPercent.toStringAsFixed(1))
          : '0',
    );

    _calcListenable = Listenable.merge([_amountCtrl, _interestCtrl]);
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _conceptCtrl.dispose();
    _amountCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLent = _kind == LoanKind.lent;
    final people = widget.store.knownPeople;
    final selectedAcc = widget.store.getAccountById(_selectedAccountId);
    final supportsUsd =
        selectedAcc?.type == AccountType.credit &&
        (selectedAcc?.isDualCurrency ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Nuevo Préstamo' : 'Editar Préstamo',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        children: [
          // 1. Presté vs Me Prestaron
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<LoanKind>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: LoanKind.lent,
                  label: Text('Presté dinero (Me deben)'),
                ),
                ButtonSegment(
                  value: LoanKind.borrowed,
                  label: Text('Me prestaron (Yo debo)'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Person selector & input
          const Text(
            'Persona o entidad',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (people.isNotEmpty) ...[
                    const Text(
                      'Seleccionar persona guardada:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: people.map((p) {
                        final selected =
                            _personCtrl.text.trim().toLowerCase() ==
                            p.toLowerCase();
                        return ChoiceChip(
                          label: Text('👤 $p'),
                          selected: selected,
                          selectedColor: context.palette.accentFill,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _personCtrl.text = p;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _personCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: isLent
                          ? '¿A quién le prestaste dinero? *'
                          : '¿Quién te prestó dinero? *',
                      hintText: 'Ej. Carlos, Mamá, Juan, Banco...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _personEmojis.map((em) {
                        final sel = _personEmoji == em;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(em),
                            selected: sel,
                            selectedColor: context.palette.accentFill,
                            onSelected: (_) =>
                                setState(() => _personEmoji = em),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _conceptCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: const InputDecoration(
                      labelText: 'Motivo o descripción (Opcional)',
                      hintText: 'Ej. Emergencia médica, adelanto, viaje...',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          // 3. Amount & Optional Interest
          const Text(
            'Monto e interés opcional',
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
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          style: const TextStyle(fontSize: 13.5),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Monto prestado ($_currency) *',
                            prefixText: _currency == 'USD' ? '\$ ' : 'Q ',
                          ),
                        ),
                      ),
                      if (supportsUsd) ...[
                        const SizedBox(width: 8),
                        SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'GTQ', label: Text('Q')),
                            ButtonSegment(value: 'USD', label: Text('\$')),
                          ],
                          selected: {_currency},
                          onSelectionChanged: (s) =>
                              setState(() => _currency = s.first),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interestCtrl,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Interés adicional (%) (Opcional)',
                            suffixText: '%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final p in const ['0', '5', '10', '15'])
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '$p%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _interestCtrl.text = p,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: _calcListenable,
                      builder: (context, _) {
                        final base =
                            double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                        final pct =
                            double.tryParse(_interestCtrl.text.trim()) ?? 0.0;
                        final interestAmt = base * (pct / 100.0);
                        final total = base + interestAmt;
                        final perInstallment = _installmentsCount > 1
                            ? total / _installmentsCount
                            : total;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isLent
                                ? context.palette.incomeSoftBg
                                : context.palette.warningSoftBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            [
                              'Total a ${isLent ? 'cobrar' : 'pagar'}: ${CurrencyFormatter.format(total, currency: _currency)}',
                              if (pct > 0)
                                '(Interés: +${CurrencyFormatter.format(interestAmt, currency: _currency)})',
                              if (_installmentsCount > 1)
                                '• $_installmentsCount pagos de ${CurrencyFormatter.format(perInstallment, currency: _currency)}',
                            ].join(' '),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isLent
                                  ? context.palette.income
                                  : context.palette.warning,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          // 4. Due Date & Installments
          const Text(
            'Plazo y cuotas acordadas',
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
                      Expanded(
                        child: Text(
                          _dueDate == null
                              ? 'Fecha límite: Sin fecha definida'
                              : 'Fecha límite: ${CurrencyFormatter.formatShortDate(_dueDate!)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _dueDate = null),
                          icon: const Icon(Icons.clear, size: 16),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: _pickDueDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                        ),
                        label: const Text(
                          'Elegir fecha',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text(
                          'En 15 días',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () => setState(
                          () => _dueDate = DateTime.now().add(
                            const Duration(days: 15),
                          ),
                        ),
                      ),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text(
                          'En 1 mes',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () => setState(
                          () => _dueDate = DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        ),
                      ),
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text(
                          'En 3 meses',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () => setState(
                          () => _dueDate = DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  const Text(
                    'Número de pagos / cuotas acordadas',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [1, 2, 3, 6, 12].map((count) {
                      final sel = _installmentsCount == count;
                      return ChoiceChip(
                        label: Text(count == 1 ? '1 pago' : '$count pagos'),
                        selected: sel,
                        selectedColor: context.palette.accentFill,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          color: sel ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) =>
                            setState(() => _installmentsCount = count),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // 5. Account link
          if (widget.store.accounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Cuenta asociada',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.store.accounts.map((a) {
                        final sel = _selectedAccountId == a.id;
                        return ChoiceChip(
                          label: Text('${a.emoji} ${a.name}'),
                          selected: sel,
                          selectedColor: Color(a.colorValue),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            color: sel ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedAccountId = a.id),
                        );
                      }).toList(),
                    ),
                    if (widget.existing == null) ...[
                      const Divider(height: 18),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          isLent
                              ? 'Descontar el dinero prestado de mi cuenta ahora'
                              : 'Sumar el dinero recibido a mi cuenta ahora',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _affectAccountNow,
                        onChanged: (v) => setState(() => _affectAccountNow = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isLent
                  ? AppTheme.incomeSolid
                  : context.palette.accentFill,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _save,
            child: Text(
              widget.existing == null ? 'Guardar préstamo' : 'Guardar cambios',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _save() {
    final person = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final interest = double.tryParse(_interestCtrl.text.trim()) ?? 0.0;

    if (person.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre de la persona y un monto válido.'),
        ),
      );
      return;
    }

    widget.store.saveLoan(
      id: widget.existing?.id,
      kind: _kind,
      personName: person,
      personEmoji: _personEmoji,
      concept: _conceptCtrl.text.trim(),
      principalAmount: amount,
      interestPercent: interest,
      currency: _currency,
      accountId: _selectedAccountId,
      dueDate: _dueDate,
      installmentsCount: _installmentsCount,
      affectAccountBalance: widget.existing == null && _affectAccountNow,
    );
    Navigator.pop(context);
  }
}
