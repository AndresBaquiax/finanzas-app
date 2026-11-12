import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/accounts_management_modal.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/payment_detector_sheet.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final FinanceStore store;
  const DashboardScreen({super.key, required this.store});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _filterAccountId;
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final currency = store.settings.primaryCurrency;

    if (_filterAccountId != null &&
        store.getAccountById(_filterAccountId) == null) {
      _filterAccountId = null;
    }

    final defaultAcc = store.defaultAccount;
    final selectedFilterAcc = store.getAccountById(_filterAccountId);

    final filteredTx = store.transactions.where((tx) {
      if (_filterAccountId != null &&
          tx.accountId != _filterAccountId &&
          tx.targetAccountId != _filterAccountId) {
        return false;
      }
      if (_filterType != null && tx.type != _filterType) {
        return false;
      }
      return true;
    }).toList(growable: false);

    final totalIncome = store.totalIncome(accountId: _filterAccountId);
    final totalExpense = store.totalExpenses(accountId: _filterAccountId);
    final pendingDetected = store.pendingDetectedPayments;

    return Scaffold(
      appBar: AppBar(
        leading: SettingsScreen.buildHeaderButton(context, store),
        titleSpacing: 0,
        title: const Text('Finanzas'),
        actions: [
          IconButton(
            tooltip: 'Detector Google Wallet y SMS',
            onPressed: () => PaymentDetectorPage.show(context, store),
            icon: Badge(
              isLabelVisible: pendingDetected.isNotEmpty,
              label: Text('${pendingDetected.length}'),
              child: Icon(
                Icons.contactless_rounded,
                size: 20,
                color: store.hasNotificationListenerAccess
                    ? context.palette.income
                    : context.palette.accent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                side: BorderSide(color: context.palette.accent),
                foregroundColor: context.palette.accent,
              ),
              onPressed: () => AccountsManagementModal.show(context, store),
              icon: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 15,
              ),
              label: const Text(
                'Cuentas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
        children: [
          if (pendingDetected.isNotEmpty) ...[
            _buildPendingDetectedBanner(context, pendingDetected.length),
            const SizedBox(height: 10),
          ],
          if (defaultAcc == null)
            _buildEmptyAccountsOnboarding(context)
          else ...[
            RepaintBoundary(
              child: _buildPrimaryAccountCard(context, defaultAcc, currency),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Ingresos',
                      amount: totalIncome,
                      currency: currency,
                      solidColor: context.palette.income,
                      softBg: context.palette.incomeSoftBg,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Gastos',
                      amount: totalExpense,
                      currency: currency,
                      solidColor: context.palette.expense,
                      softBg: context.palette.expenseSoftBg,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 16),
            _buildAccountFilters(context, selectedFilterAcc, currency),
          ],
          const SizedBox(height: 16),
          _buildTransactionsSection(context, filteredTx, currency),
        ],
      ),
    );
  }

  Widget _buildPendingDetectedBanner(BuildContext context, int count) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => PaymentDetectorPage.show(context, widget.store),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.palette.warningSoftBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.palette.warning.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.contactless_rounded,
              color: context.palette.warning,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count pago(s) de Google Wallet / SMS pendientes de confirmar',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.palette.warning,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.palette.warning,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAccountsOnboarding(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.palette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: context.palette.accent,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega tu primera cuenta',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Registra tus cuentas de débito, ahorro o tarjetas de crédito para comenzar a llevar el control.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
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
              onPressed: () => AccountsManagementModal.showAccountForm(
                context,
                widget.store,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAccountCard(
    BuildContext context,
    AccountModel acc,
    String currency,
  ) {
    final solidColor = Color(acc.colorValue);
    final isCredit = acc.type == AccountType.credit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: solidColor,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(acc.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuenta principal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      acc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.store.accounts.length > 1)
                PopupMenuButton<String>(
                  tooltip: 'Cambiar cuenta principal',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onSelected: (id) => widget.store.setDefaultAccount(id),
                  itemBuilder: (ctx) => widget.store.accounts
                      .map(
                        (a) => PopupMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.emoji} ${a.name} ${a.isDefault ? '✓' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isCredit ? 'Crédito disponible' : 'Saldo disponible',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(
                isCredit ? acc.availableCredit : acc.currentBalance,
                currency: currency,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (isCredit) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: acc.creditUsageRatio,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Consumido: ${CurrencyFormatter.format(acc.currentBalance, currency: currency)} / ${CurrencyFormatter.format(acc.creditLimit, currency: currency)} • Corte día ${acc.cutoffDay}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ] else if (acc.type == AccountType.savings) ...[
            const SizedBox(height: 6),
            Text(
              'Cuenta de ahorro • ${acc.annualInterestRate.toStringAsFixed(1)}% anual',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required double amount,
    required String currency,
    required Color solidColor,
    required Color softBg,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? solidColor.withValues(alpha: 0.16) : softBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: solidColor, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(amount, currency: currency),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: solidColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expenseSolid,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 9),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => AddTransactionModal.show(
              context,
              widget.store,
              preselectedAccountId: _filterAccountId,
              initialType: TransactionType.expense,
            ),
            icon: const Icon(Icons.remove_rounded, size: 16),
            label: const Text('Gasto'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.incomeSolid,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 9),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => AddTransactionModal.show(
              context,
              widget.store,
              preselectedAccountId: _filterAccountId,
              initialType: TransactionType.income,
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Ingreso'),
          ),
        ),
        if (widget.store.accounts.length > 1) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 9),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => AddTransactionModal.show(
                context,
                widget.store,
                preselectedAccountId: _filterAccountId,
                initialType: TransactionType.transfer,
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Transferir'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountFilters(
    BuildContext context,
    AccountModel? selectedAcc,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por cuenta',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('Todas'),
                  selected: _filterAccountId == null,
                  selectedColor: context.palette.accentFill,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    color: _filterAccountId == null ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _filterAccountId = null),
                ),
              ),
              ...widget.store.accounts.map((acc) {
                final selected = _filterAccountId == acc.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${acc.emoji} ${acc.name}'),
                    selected: selected,
                    selectedColor: Color(acc.colorValue),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        setState(() => _filterAccountId = acc.id),
                  ),
                );
              }),
            ],
          ),
        ),
        if (selectedAcc != null &&
            selectedAcc.type == AccountType.credit) ...[
          const SizedBox(height: 10),
          RepaintBoundary(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${selectedAcc.emoji} ${selectedAcc.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => widget.store.toggleCreditCardPaidStatus(
                            selectedAcc.id,
                            !selectedAcc.isPaidThisCycle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: selectedAcc.isPaidThisCycle
                                  ? context.palette.incomeSoftBg
                                  : context.palette.expenseSoftBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedAcc.isPaidThisCycle
                                  ? '✓ Pagada'
                                  : 'Pendiente',
                              style: TextStyle(
                                color: selectedAcc.isPaidThisCycle
                                    ? context.palette.income
                                    : context.palette.expense,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _miniCreditMetric(
                            'Consumido',
                            CurrencyFormatter.format(
                              selectedAcc.currentBalance,
                              currency: currency,
                            ),
                            context.palette.expense,
                          ),
                        ),
                        Expanded(
                          child: _miniCreditMetric(
                            'Disponible',
                            CurrencyFormatter.format(
                              selectedAcc.availableCredit,
                              currency: currency,
                            ),
                            context.palette.income,
                          ),
                        ),
                        Expanded(
                          child: _miniCreditMetric(
                            'Límite',
                            CurrencyFormatter.format(
                              selectedAcc.creditLimit,
                              currency: currency,
                            ),
                            null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: selectedAcc.creditUsageRatio,
                        minHeight: 5,
                        backgroundColor: context.palette.track,
                        color: Color(selectedAcc.colorValue),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Corte: Día ${selectedAcc.cutoffDay} • ${selectedAcc.isDualCurrency ? 'Dúo (Q y \$)' : 'Solo Quetzales'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (selectedAcc.hasCashback) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.incomeSoftBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          [
                            ...selectedAcc.cashbackRules.map(
                              (r) => r.displayLabel,
                            ),
                            '${selectedAcc.defaultCashbackPercent.toStringAsFixed(selectedAcc.defaultCashbackPercent % 1 == 0 ? 0 : 1)}% en todo lo demás',
                            if (selectedAcc.accumulatedCashback > 0)
                              'Ahorrado: ${CurrencyFormatter.format(selectedAcc.accumulatedCashback, currency: currency)}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: context.palette.income,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _miniCreditMetric(String label, String value, Color? color) {
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

  Widget _buildTransactionsSection(
    BuildContext context,
    List<TransactionModel> filteredTx,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Últimas Transacciones',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
            _typePill('Todos', null),
            const SizedBox(width: 4),
            _typePill('Gastos', TransactionType.expense),
            const SizedBox(width: 4),
            _typePill('Ingresos', TransactionType.income),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredTx.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  'Sin movimientos registrados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < filteredTx.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  RepaintBoundary(
                    child: _buildTransactionRow(
                      context,
                      filteredTx[i],
                      currency,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _typePill(String label, TransactionType? type) {
    final selected = _filterType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.palette.accentFill : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    TransactionModel tx,
    String currency,
  ) {
    final store = widget.store;
    final acc = store.getAccountById(tx.accountId);
    final cat = store.getCategoryById(tx.categoryId);

    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;
    final amountColor = isIncome
        ? context.palette.income
        : isTransfer
        ? context.palette.accent
        : context.palette.expense;

    final sign = isIncome
        ? '+'
        : isTransfer
        ? '⇄ '
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(
                cat?.colorValue ?? acc?.colorValue ?? 0xFF1D4ED8,
              ).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              isTransfer ? '🔄' : (cat?.emoji ?? acc?.emoji ?? '💸'),
              style: const TextStyle(fontSize: 17),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.subcategory.isNotEmpty
                      ? '${tx.categoryName} • ${tx.subcategory}'
                      : tx.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${acc?.name ?? 'Cuenta'} • ${CurrencyFormatter.formatShortDate(tx.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (tx.note.isNotEmpty)
                  Text(
                    tx.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                if (tx.originalCurrency == 'USD')
                  Text(
                    'USD \$${tx.originalAmount.toStringAsFixed(2)} (TC Q${tx.exchangeRateUsed.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.palette.accent,
                    ),
                  ),
                if (tx.isInstallment)
                  Text(
                    '${tx.installmentsTotal} cuotas (${CurrencyFormatter.format(tx.amount / tx.installmentsTotal, currency: currency)}/mes)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.palette.accent,
                    ),
                  ),
                if (tx.hasCashback)
                  Text(
                    'Cashback ${tx.cashbackPercentUsed.toStringAsFixed(tx.cashbackPercentUsed % 1 == 0 ? 0 : 1)}%: -${CurrencyFormatter.format(tx.cashbackEarned, currency: currency)} (Neto: ${CurrencyFormatter.format(tx.netAmountAfterCashback, currency: currency)})',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: context.palette.income,
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
                '$sign${CurrencyFormatter.format(tx.amount, currency: currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: amountColor,
                ),
              ),
              InkWell(
                onTap: () => store.deleteTransaction(tx.id),
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.delete_outline,
                    size: 15,
                    color: context.palette.iconMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
