import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/recurring_payment_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/accounts_management_modal.dart';
import 'settings_screen.dart';

class RecurringPaymentsScreen extends StatelessWidget {
  final FinanceStore store;
  const RecurringPaymentsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final primaryCurrency = store.settings.primaryCurrency;
    final rate = store.settings.usdToGtqRate;
    final payments = store.recurringPayments;

    double totalExpensesGtq = 0.0;
    double totalIncomeGtq = 0.0;
    int appliedCount = 0;

    for (final r in payments) {
      final effective = r.netEffectiveAmount;
      final inPrimary = r.currency == 'USD' ? effective * rate : effective;
      if (r.isIncome) {
        totalIncomeGtq += inPrimary;
      } else {
        totalExpensesGtq += inPrimary;
      }
      if (r.isFullyProcessedForMonth(now)) appliedCount++;
    }

    return Scaffold(
      appBar: AppBar(
        leading: SettingsScreen.buildHeaderButton(context, store),
        titleSpacing: 0,
        title: const Text('Recurrentes y Salario'),
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
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nuevo'),
            ),
          ),
        ],
      ),
      body: payments.isEmpty
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
                        Icons.autorenew_rounded,
                        size: 26,
                        color: context.palette.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sin movimientos recurrentes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Configura tu salario (Planilla, Servicios o Pago único; Quincenal y Fin de Mes con Bono e ISR) o tus pagos fijos.',
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
                              _openForm(context, initialIsIncome: true),
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: const Text('Configurar Salario'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.palette.accentFill,
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
                              _openForm(context, initialIsIncome: false),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Agregar Gasto'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => _openForm(
                            context,
                            initialIsIncome: false,
                            initialIsTransfer: true,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('Transferencia Automática'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
              itemCount: payments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
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
                                  'Ingresos recurrentes (Neto)',
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
                                    '+${CurrencyFormatter.format(totalIncomeGtq, currency: primaryCurrency)}',
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
                                  'Gastos recurrentes',
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
                                    '-${CurrencyFormatter.format(totalExpensesGtq, currency: primaryCurrency)}',
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
                              '$appliedCount/${payments.length}',
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
                  );
                }

                final rec = payments[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RepaintBoundary(
                    child: _buildRecurringCard(context, rec, now),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    RecurringPaymentModel rec,
    DateTime now,
  ) {
    final isFullyDone = rec.isFullyProcessedForMonth(now);
    final statusColor = isFullyDone
        ? context.palette.income
        : context.palette.expense;
    final statusSoftBg = isFullyDone
        ? context.palette.incomeSoftBg
        : context.palette.expenseSoftBg;

    final acc = store.getAccountById(rec.accountId);
    final targetAcc = store.getAccountById(rec.targetAccountId);
    final cat = store.getCategoryById(rec.categoryId);
    final rate = store.settings.usdToGtqRate;
    final effectiveAmount = rec.netEffectiveAmount;
    final convertedGtq = rec.currency == 'USD'
        ? effectiveAmount * rate
        : effectiveAmount;

    final dateSubtitle = rec.isBiweeklySalary
        ? 'Quincena: Día ${rec.quincenaDay} • Fin de mes: Día ${rec.billingDay} • ${acc?.name ?? 'Cuenta'}'
        : rec.isTransfer
        ? 'Día ${rec.billingDay} • ${acc?.name ?? 'Origen'} → ${targetAcc?.name ?? 'Destino'}'
        : 'Día ${rec.billingDay} • ${acc?.name ?? 'Cuenta'}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                    color: statusSoftBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    rec.isTransfer
                        ? '⇄'
                        : (cat?.emoji ?? (rec.isIncome ? '💼' : '🔄')),
                    style: const TextStyle(fontSize: 18),
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
                              rec.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: rec.isIncome
                                  ? context.palette.incomeSoftBg
                                  : context.palette.accent.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rec.isIncome
                                  ? rec.incomeRegimeLabel.toUpperCase()
                                  : rec.isTransfer
                                  ? 'TRANSFERENCIA'
                                  : 'GASTO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: rec.isIncome
                                    ? context.palette.income
                                    : context.palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rec.isIncome
                          ? '+'
                          : rec.isTransfer
                          ? '⇄ '
                          : '-'}${CurrencyFormatter.format(effectiveAmount, currency: rec.currency)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: rec.isIncome
                            ? context.palette.income
                            : rec.isTransfer
                            ? context.palette.accent
                            : null,
                      ),
                    ),
                    if (rec.currency == 'USD')
                      Text(
                        '≈ ${CurrencyFormatter.format(convertedGtq, currency: 'GTQ')}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: context.palette.accent,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (rec.isIncome &&
                (rec.hasBonoDeLey || rec.calculateIsr || rec.deductIgss)) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  [
                    'Base: ${CurrencyFormatter.format(rec.amount, currency: rec.currency)}',
                    if (rec.hasBonoDeLey && rec.effectiveBonoDeLey > 0)
                      '+Bono: ${CurrencyFormatter.format(rec.effectiveBonoDeLey, currency: rec.currency)}',
                    if (rec.calculateIsr)
                      '-ISR: ${CurrencyFormatter.format(rec.isrDeduction, currency: rec.currency)}',
                    if (rec.deductIgss && rec.igssDeduction > 0)
                      '-IGSS: ${CurrencyFormatter.format(rec.igssDeduction, currency: rec.currency)}',
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
            if (rec.isBiweeklySalary) ...[
              const SizedBox(height: 8),
              _buildBiweeklySplitRow(
                context: context,
                label: '1ª Quincena (Día ${rec.quincenaDay} • 50% Base)',
                amount: CurrencyFormatter.format(
                  rec.quincenaNetAmount,
                  currency: rec.currency,
                ),
                isPaid: rec.isQuincenaPaidForMonth(now),
                onToggle: () => store.toggleRecurringQuincenaThisMonth(rec.id),
              ),
              const SizedBox(height: 5),
              _buildBiweeklySplitRow(
                context: context,
                label:
                    'Fin de Mes (Día ${rec.billingDay} • 50% + Bono - ISR)',
                amount: CurrencyFormatter.format(
                  rec.endOfMonthNetAmount,
                  currency: rec.currency,
                ),
                isPaid: rec.isDebitedForMonth(now),
                onToggle: () => store.toggleRecurringDebitedThisMonth(rec.id),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _openForm(context, existing: rec),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => store.deleteRecurringPayment(rec.id),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: context.palette.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusSoftBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isFullyDone
                          ? (rec.isIncome
                                ? 'Acreditado'
                                : rec.isTransfer
                                ? 'Transferido'
                                : 'Debitado')
                          : 'Pendiente',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () =>
                            store.toggleRecurringDebitedThisMonth(rec.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            isFullyDone
                                ? 'Marcar pendiente'
                                : (rec.isIncome
                                      ? 'Acreditar ahora'
                                      : rec.isTransfer
                                      ? 'Transferir ahora'
                                      : 'Debitar ahora'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _openForm(context, existing: rec),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => store.deleteRecurringPayment(rec.id),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: context.palette.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiweeklySplitRow({
    required BuildContext context,
    required String label,
    required String amount,
    required bool isPaid,
    required VoidCallback onToggle,
  }) {
    final palette = context.palette;
    final color = isPaid ? palette.income : palette.expense;
    final fill = isPaid ? AppTheme.incomeSolid : AppTheme.expenseSolid;
    final bg = isPaid ? palette.incomeSoftBg : palette.expenseSoftBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+$amount',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                isPaid ? 'Pagado' : 'Acreditar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(
    BuildContext context, {
    RecurringPaymentModel? existing,
    bool initialIsIncome = false,
    bool initialIsTransfer = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RecurringFormPage(
          store: store,
          existing: existing,
          initialIsIncome: initialIsIncome,
          initialIsTransfer: initialIsTransfer,
        ),
      ),
    );
  }
}

class _RecurringFormPage extends StatefulWidget {
  final FinanceStore store;
  final RecurringPaymentModel? existing;
  final bool initialIsIncome;
  final bool initialIsTransfer;

  const _RecurringFormPage({
    required this.store,
    this.existing,
    this.initialIsIncome = false,
    this.initialIsTransfer = false,
  });

  @override
  State<_RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends State<_RecurringFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _bonoCtrl;
  late final TextEditingController _customIsrPctCtrl;
  late final Listenable _salaryCalcListenable;

  late bool _isIncome;
  late bool _isTransfer;
  late String _incomeRegime; // 'planilla', 'servicios', 'unico'
  late String _payFrequency; // 'mensual', 'quincenal_fin_mes', 'pago_unico'
  late int _quincenaDay;
  late bool _deductionsAndBonoAtEndOfMonth;

  String? _selectedAccountId;
  String? _targetAccountId;
  late String _selectedCurrency;
  late int _billingDay;
  late bool _autoDebit;
  String? _selectedCategoryId;
  String? _selectedSubcategory;

  // Salary / Bono / ISR state
  late bool _hasBonoDeLey;
  late bool _calculateIsr;
  late String _isrMode; // 'sat_gt', 'servicios_gt', 'flat_percent'
  late bool _deductIgss;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _isIncome = e?.isIncome ?? widget.initialIsIncome;
    _isTransfer = e?.isTransfer ?? widget.initialIsTransfer;
    if (_isTransfer) _isIncome = false;

    _incomeRegime = e?.incomeRegime ?? 'planilla';
    _payFrequency =
        e?.payFrequency ?? (_isIncome ? 'quincenal_fin_mes' : 'mensual');
    _quincenaDay = e?.quincenaDay ?? 15;
    _deductionsAndBonoAtEndOfMonth = e?.deductionsAndBonoAtEndOfMonth ?? true;

    _nameCtrl = TextEditingController(
      text:
          e?.name ??
          (_isIncome
              ? 'Salario Mensual'
              : _isTransfer
              ? 'Transferencia Automática'
              : ''),
    );
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _bonoCtrl = TextEditingController(
      text: e != null ? e.bonoDeLeyAmount.toStringAsFixed(2) : '250.00',
    );
    _customIsrPctCtrl = TextEditingController(
      text: e != null
          ? (e.customIsrPercent % 1 == 0
                ? e.customIsrPercent.toInt().toString()
                : e.customIsrPercent.toStringAsFixed(1))
          : '5',
    );

    _salaryCalcListenable = Listenable.merge([
      _amountCtrl,
      _bonoCtrl,
      _customIsrPctCtrl,
    ]);

    _selectedAccountId =
        e?.accountId ??
        widget.store.defaultAccount?.id ??
        (widget.store.accounts.isNotEmpty
            ? widget.store.accounts.first.id
            : null);
    if (e?.targetAccountId != null) {
      _targetAccountId = e!.targetAccountId;
    } else if (widget.store.accounts.length > 1) {
      _targetAccountId = widget.store.accounts
          .firstWhere(
            (a) => a.id != _selectedAccountId,
            orElse: () => widget.store.accounts.first,
          )
          .id;
    }

    _selectedCurrency = e?.currency ?? widget.store.settings.primaryCurrency;
    _billingDay = e?.billingDay ?? (_isIncome ? 30 : 15);
    _autoDebit = e?.autoDebit ?? true;

    _hasBonoDeLey = e?.hasBonoDeLey ?? (_isIncome ? true : false);
    _calculateIsr = e?.calculateIsr ?? (_isIncome ? true : false);
    _isrMode = e?.isrMode ?? 'sat_gt';
    _deductIgss = e?.deductIgss ?? false;

    _syncCategoriesForKind(preserveExisting: e != null);
  }

  void _syncCategoriesForKind({bool preserveExisting = false}) {
    final cats = _isIncome
        ? widget.store.incomeCategories
        : widget.store.expenseCategories;
    if (cats.isEmpty) return;

    if (preserveExisting && widget.existing != null) {
      _selectedCategoryId = widget.existing!.categoryId;
      _selectedSubcategory = widget.existing!.subcategory;
      return;
    }

    _selectedCategoryId = cats.first.id;
    _selectedSubcategory = cats.first.subcategories.isNotEmpty
        ? cats.first.subcategories.first
        : 'General';
  }

  void _onIncomeRegimeChanged(String regime) {
    setState(() {
      _incomeRegime = regime;
      if (regime == 'planilla') {
        _hasBonoDeLey = true;
        _calculateIsr = true;
        _isrMode = 'sat_gt';
        if (_payFrequency == 'pago_unico') {
          _payFrequency = 'quincenal_fin_mes';
        }
      } else if (regime == 'servicios') {
        _hasBonoDeLey = false;
        _deductIgss = false;
        _calculateIsr = true;
        _isrMode = 'servicios_gt';
        if (_payFrequency == 'pago_unico') {
          _payFrequency = 'mensual';
        }
      } else if (regime == 'unico') {
        _hasBonoDeLey = false;
        _deductIgss = false;
        _calculateIsr = false;
        _payFrequency = 'pago_unico';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _bonoCtrl.dispose();
    _customIsrPctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store.accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo Recurrente')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Primero crea una cuenta para asociar el movimiento recurrente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () async {
                    await AccountsManagementModal.showAccountForm(
                      context,
                      widget.store,
                    );
                    if (widget.store.accounts.isNotEmpty) {
                      setState(() {
                        _selectedAccountId = widget.store.accounts.first.id;
                      });
                    }
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

    final acc = widget.store.getAccountById(_selectedAccountId);
    final supportsUsd =
        acc?.type == AccountType.credit && (acc?.isDualCurrency ?? false);
    if (!supportsUsd &&
        _selectedCurrency != widget.store.settings.primaryCurrency) {
      _selectedCurrency = widget.store.settings.primaryCurrency;
    }

    final availableCats = _isIncome
        ? widget.store.incomeCategories
        : widget.store.expenseCategories;
    final currentCat =
        widget.store.getCategoryById(_selectedCategoryId) ??
        availableCats.first;

    if (_selectedSubcategory == null ||
        !currentCat.subcategories.contains(_selectedSubcategory)) {
      _selectedSubcategory = currentCat.subcategories.isNotEmpty
          ? currentCat.subcategories.first
          : 'General';
    }

    final isBiweekly = _isIncome && _payFrequency == 'quincenal_fin_mes';
    final currentKindKey = _isTransfer
        ? 'transfer'
        : (_isIncome ? 'income' : 'expense');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? (_isTransfer
                    ? 'Transferencia Automática'
                    : _isIncome
                    ? 'Configurar Salario / Ingreso'
                    : 'Nuevo Pago Recurrente')
              : 'Editar Recurrente',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        children: [
          // 1. Selector: Gasto vs Ingreso / Salario vs Transferencia
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                  value: 'expense',
                  label: Text('Gasto'),
                ),
                const ButtonSegment(
                  value: 'income',
                  label: Text('Ingreso / Salario'),
                ),
                if (widget.store.accounts.length > 1)
                  const ButtonSegment(
                    value: 'transfer',
                    label: Text('Transferencia'),
                  ),
              ],
              selected: {currentKindKey},
              onSelectionChanged: (s) {
                final next = s.first;
                setState(() {
                  _isIncome = next == 'income';
                  _isTransfer = next == 'transfer';
                  if (_isIncome &&
                      (_nameCtrl.text.trim().isEmpty ||
                          _nameCtrl.text.trim() ==
                              'Transferencia Automática')) {
                    _nameCtrl.text = 'Salario Mensual';
                  } else if (_isTransfer &&
                      (_nameCtrl.text.trim().isEmpty ||
                          _nameCtrl.text.trim() == 'Salario Mensual')) {
                    _nameCtrl.text = 'Transferencia Automática';
                  } else if (!_isIncome &&
                      !_isTransfer &&
                      (_nameCtrl.text.trim() == 'Salario Mensual' ||
                          _nameCtrl.text.trim() ==
                              'Transferencia Automática')) {
                    _nameCtrl.text = '';
                  }
                  if (_isTransfer &&
                      (_targetAccountId == null ||
                          _targetAccountId == _selectedAccountId) &&
                      widget.store.accounts.length > 1) {
                    _targetAccountId = widget.store.accounts
                        .firstWhere((a) => a.id != _selectedAccountId)
                        .id;
                  }
                  _syncCategoriesForKind();
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. If Income: Modalidad (Planilla, Servicios, Pago Único) & Frecuencia (Quincenal/Fin de Mes vs Mensual)
          if (_isIncome) ...[
            const Text(
              'Modalidad del ingreso',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'planilla',
                    label: Text('Planilla'),
                  ),
                  ButtonSegment(
                    value: 'servicios',
                    label: Text('Por Servicios'),
                  ),
                  ButtonSegment(
                    value: 'unico',
                    label: Text('Pago Único'),
                  ),
                ],
                selected: {_incomeRegime},
                onSelectionChanged: (s) => _onIncomeRegimeChanged(s.first),
              ),
            ),
            if (_incomeRegime != 'unico') ...[
              const SizedBox(height: 12),
              const Text(
                'Frecuencia de pago',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'quincenal_fin_mes',
                      label: Text('Quincena y Fin de Mes'),
                    ),
                    ButtonSegment(
                      value: 'mensual',
                      label: Text('1 Pago al Mes'),
                    ),
                  ],
                  selected: {
                    _payFrequency == 'quincenal_fin_mes'
                        ? 'quincenal_fin_mes'
                        : 'mensual',
                  },
                  onSelectionChanged: (s) =>
                      setState(() => _payFrequency = s.first),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // 3. Basic Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: _isIncome
                          ? 'Nombre del ingreso o salario *'
                          : _isTransfer
                          ? 'Nombre de la transferencia *'
                          : 'Nombre del servicio *',
                      hintText: _isIncome
                          ? 'Ej. Salario Planilla, Honorarios...'
                          : _isTransfer
                          ? 'Ej. Ahorro mensual, Pago tarjeta...'
                          : 'Ej. Internet, Luz, Spotify...',
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            labelText: _isIncome
                                ? (_incomeRegime == 'planilla'
                                      ? 'Salario base mensual total ($_selectedCurrency) *'
                                      : 'Monto bruto ($_selectedCurrency) *')
                                : 'Monto ($_selectedCurrency) *',
                            prefixText: _selectedCurrency == 'USD'
                                ? '\$ '
                                : 'Q ',
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
                          selected: {_selectedCurrency},
                          onSelectionChanged: (s) =>
                              setState(() => _selectedCurrency = s.first),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Salary / Services deductions & Bono de Ley Card
          if (_isIncome) ...[
            const SizedBox(height: 14),
            const Text(
              'Bono de Ley, ISR y Desglose de Pagos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBiweekly) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'En quincena pagar 50% base, y a fin de mes sumar Bono y descontar ISR',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        subtitle: Text(
                          _deductionsAndBonoAtEndOfMonth
                              ? 'Quincena: 50% salario limpio • Fin de mes: 50% + Bono - ISR'
                              : 'Se divide el Bono y el ISR mitad en quincena y mitad a fin de mes',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: _deductionsAndBonoAtEndOfMonth,
                        onChanged: (v) => setState(
                          () => _deductionsAndBonoAtEndOfMonth = v,
                        ),
                      ),
                      const Divider(height: 18),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: const Text(
                        'Sumar Bono Incentivo de Ley',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        'Se suma automáticamente a tu salario base',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      value: _hasBonoDeLey,
                      onChanged: (v) => setState(() => _hasBonoDeLey = v),
                    ),
                    if (_hasBonoDeLey) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bonoCtrl,
                              style: const TextStyle(fontSize: 13),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText:
                                    'Monto Bono de Ley ($_selectedCurrency)',
                                prefixText: _selectedCurrency == 'USD'
                                    ? '\$ '
                                    : 'Q ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: const Text(
                              'Q250',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _bonoCtrl.text = '250.00',
                          ),
                          const SizedBox(width: 4),
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: const Text(
                              'Q125',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => _bonoCtrl.text = '125.00',
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 18),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: const Text(
                        'Calcular descuento de ISR automático',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        'Descuenta automáticamente el ISR',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      value: _calculateIsr,
                      onChanged: (v) => setState(() => _calculateIsr = v),
                    ),
                    if (_calculateIsr) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: 'sat_gt',
                              label: Text('Planilla SAT'),
                            ),
                            ButtonSegment(
                              value: 'servicios_gt',
                              label: Text('Servicios 5%/7%'),
                            ),
                            ButtonSegment(
                              value: 'flat_percent',
                              label: Text('% Directo'),
                            ),
                          ],
                          selected: {_isrMode},
                          onSelectionChanged: (s) =>
                              setState(() => _isrMode = s.first),
                        ),
                      ),
                      if (_isrMode == 'flat_percent') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customIsrPctCtrl,
                                style: const TextStyle(fontSize: 13),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Porcentaje de ISR a descontar',
                                  suffixText: '%',
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (final pct in const ['5', '7']) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () => _customIsrPctCtrl.text = pct,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                    if (_incomeRegime == 'planilla') ...[
                      const Divider(height: 18),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'Descontar también IGSS (4.83%)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Opcional: descuenta el 4.83% de cuota laboral IGSS',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        value: _deductIgss,
                        onChanged: (v) => setState(() => _deductIgss = v),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Live Salary & Quincena Breakdown Box
                    RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: _salaryCalcListenable,
                        builder: (context, _) {
                          final base =
                              double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                          final bono = _hasBonoDeLey
                              ? (double.tryParse(_bonoCtrl.text.trim()) ?? 0.0)
                              : 0.0;
                          final customPct =
                              double.tryParse(_customIsrPctCtrl.text.trim()) ??
                              5.0;

                          final previewModel = RecurringPaymentModel(
                            id: 'preview',
                            name: 'Preview',
                            amount: base,
                            currency: _selectedCurrency,
                            accountId: '',
                            categoryId: '',
                            categoryName: '',
                            subcategory: '',
                            billingDay: _billingDay,
                            isIncome: true,
                            incomeRegime: _incomeRegime,
                            payFrequency: _payFrequency,
                            quincenaDay: _quincenaDay,
                            deductionsAndBonoAtEndOfMonth:
                                _deductionsAndBonoAtEndOfMonth,
                            hasBonoDeLey: _hasBonoDeLey,
                            bonoDeLeyAmount: bono,
                            calculateIsr: _calculateIsr,
                            isrMode: _isrMode,
                            customIsrPercent: customPct,
                            deductIgss: _deductIgss,
                          );

                          final isr = previewModel.isrDeduction;
                          final igss = previewModel.igssDeduction;
                          final netTotal = previewModel.netEffectiveAmount;

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.palette.incomeSoftBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _breakdownRow(
                                  'Salario base mensual:',
                                  CurrencyFormatter.format(
                                    base,
                                    currency: _selectedCurrency,
                                  ),
                                ),
                                if (_hasBonoDeLey)
                                  _breakdownRow(
                                    '+ Bono de Ley:',
                                    '+${CurrencyFormatter.format(bono, currency: _selectedCurrency)}',
                                    valueColor: context.palette.income,
                                  ),
                                if (_calculateIsr)
                                  _breakdownRow(
                                    '- Descuento ISR (${_isrMode == 'sat_gt'
                                        ? 'Planilla SAT'
                                        : _isrMode == 'servicios_gt'
                                        ? 'Servicios SAT'
                                        : '$customPct%'}):',
                                    '-${CurrencyFormatter.format(isr, currency: _selectedCurrency)}',
                                    valueColor: context.palette.expense,
                                  ),
                                if (_deductIgss)
                                  _breakdownRow(
                                    '- Descuento IGSS (4.83%):',
                                    '-${CurrencyFormatter.format(igss, currency: _selectedCurrency)}',
                                    valueColor: context.palette.expense,
                                  ),
                                Divider(
                                  height: 12,
                                  color: context.palette.incomeDivider,
                                ),
                                if (isBiweekly) ...[
                                  _breakdownRow(
                                    '1ª Quincena (Día $_quincenaDay • 50%):',
                                    CurrencyFormatter.format(
                                      previewModel.quincenaNetAmount,
                                      currency: _selectedCurrency,
                                    ),
                                    valueColor: context.palette.accent,
                                  ),
                                  _breakdownRow(
                                    'Fin de Mes (Día $_billingDay • 50% + Bono - ISR):',
                                    CurrencyFormatter.format(
                                      previewModel.endOfMonthNetAmount,
                                      currency: _selectedCurrency,
                                    ),
                                    valueColor: context.palette.accent,
                                  ),
                                  Divider(
                                    height: 12,
                                    color: context.palette.incomeDivider,
                                  ),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isBiweekly
                                            ? 'Total líquido al mes:'
                                            : 'Monto líquido a recibir:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: context.palette.onIncomeSoft,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.format(
                                        netTotal,
                                        currency: _selectedCurrency,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: context.palette.income,
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
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Text(
            _isIncome
                ? 'Cuenta donde se depositará'
                : _isTransfer
                ? 'Cuenta de origen (de donde sale el dinero)'
                : 'Cuenta a debitar',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.store.accounts.map((a) {
              final selected = a.id == _selectedAccountId;
              return ChoiceChip(
                label: Text('${a.emoji} ${a.name}'),
                selected: selected,
                selectedColor: Color(a.colorValue),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedAccountId = a.id;
                    if (_targetAccountId == a.id &&
                        widget.store.accounts.length > 1) {
                      _targetAccountId = widget.store.accounts
                          .firstWhere((other) => other.id != a.id)
                          .id;
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_isTransfer && widget.store.accounts.length > 1) ...[
            const SizedBox(height: 12),
            const Text(
              'Cuenta de destino (a donde llega el dinero)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.store.accounts
                  .where((a) => a.id != _selectedAccountId)
                  .map((a) {
                    final selected = a.id == _targetAccountId;
                    return ChoiceChip(
                      label: Text('${a.emoji} ${a.name}'),
                      selected: selected,
                      selectedColor: Color(a.colorValue),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        color: selected ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => _targetAccountId = a.id),
                    );
                  })
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (isBiweekly) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Día de pago Quincena (50%)',
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
                          onPressed: () => _pickDay(
                            title: 'Día de pago de Quincena',
                            current: _quincenaDay,
                            onSelected: (d) => setState(() => _quincenaDay = d),
                          ),
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                          ),
                          label: Text('Día $_quincenaDay'),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isBiweekly
                              ? 'Día de pago Fin de Mes'
                              : (_isIncome
                                    ? 'Día de pago'
                                    : 'Día de cobro mensual'),
                          style: const TextStyle(
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
                        onPressed: () => _pickDay(
                          title: isBiweekly
                              ? 'Día de pago de Fin de Mes'
                              : 'Día del mes',
                          current: _billingDay,
                          onSelected: (d) => setState(() => _billingDay = d),
                        ),
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                        ),
                        label: Text('Día $_billingDay'),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      _isIncome
                          ? 'Acreditación automática'
                          : _isTransfer
                          ? 'Transferencia automática'
                          : 'Débito automático',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      isBiweekly
                          ? 'Deposita automáticamente el 50% en quincena y el resto + Bono - ISR a fin de mes'
                          : (_isIncome
                                ? 'Sumar el monto líquido a la cuenta al llegar el día'
                                : _isTransfer
                                ? 'Transferir automáticamente entre las cuentas al llegar el día'
                                : 'Descontar automáticamente al llegar el día'),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    value: _autoDebit,
                    onChanged: (v) => setState(() => _autoDebit = v),
                  ),
                ],
              ),
            ),
          ),
          if (!_isTransfer) ...[
            const SizedBox(height: 14),
            const Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: availableCats.map((c) {
                final selected = c.id == currentCat.id;
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
                      _selectedCategoryId = c.id;
                      _selectedSubcategory = c.subcategories.isNotEmpty
                          ? c.subcategories.first
                          : 'General';
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Subcategoría',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: currentCat.subcategories.map((sub) {
                final selected = _selectedSubcategory == sub;
                return ChoiceChip(
                  label: Text(sub),
                  selected: selected,
                  selectedColor: Color(currentCat.colorValue),
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
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _isIncome
                  ? AppTheme.incomeSolid
                  : context.palette.accentFill,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _save(currentCat),
            child: Text(
              _isIncome
                  ? 'Guardar ingreso / salario'
                  : _isTransfer
                  ? 'Guardar transferencia automática'
                  : 'Guardar pago recurrente',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.palette.onIncomeSoft,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? context.palette.onIncomeSoft,
            ),
          ),
        ],
      ),
    );
  }

  void _pickDay({
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

  void _save(CategoryModel currentCat) {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final bono = double.tryParse(_bonoCtrl.text.trim()) ?? 0.0;
    final customPct = double.tryParse(_customIsrPctCtrl.text.trim()) ?? 5.0;

    if (name.isEmpty || amount <= 0 || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el nombre y un monto mayor a 0.'),
        ),
      );
      return;
    }

    widget.store.saveRecurringPayment(
      id: widget.existing?.id,
      name: name,
      amount: amount,
      currency: _selectedCurrency,
      accountId: _selectedAccountId!,
      targetAccountId: _isTransfer ? _targetAccountId : null,
      categoryId: _isTransfer ? 'cat_transfer' : currentCat.id,
      categoryName: _isTransfer ? 'Transferencia' : currentCat.name,
      subcategory: _isTransfer
          ? 'Automática'
          : (_selectedSubcategory ?? 'General'),
      billingDay: _billingDay,
      autoDebit: _autoDebit,
      isIncome: _isIncome,
      isTransfer: _isTransfer,
      incomeRegime: _isIncome ? _incomeRegime : 'planilla',
      payFrequency: _isIncome ? _payFrequency : 'mensual',
      quincenaDay: _quincenaDay,
      deductionsAndBonoAtEndOfMonth: _deductionsAndBonoAtEndOfMonth,
      hasBonoDeLey: _isIncome ? _hasBonoDeLey : false,
      bonoDeLeyAmount: _isIncome && _hasBonoDeLey ? bono : 0.0,
      calculateIsr: _isIncome ? _calculateIsr : false,
      isrMode: _isrMode,
      customIsrPercent: customPct,
      deductIgss: _isIncome ? _deductIgss : false,
    );
    Navigator.pop(context);
  }
}
