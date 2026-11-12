import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';
import '../models/budget_limit_model.dart';
import '../models/category_model.dart';
import '../models/detected_payment_model.dart';
import '../models/loan_model.dart';
import '../models/recurring_payment_model.dart';
import '../models/transaction_model.dart';
import '../models/user_settings_model.dart';
import 'payment_parser.dart';

class FinanceStore extends ChangeNotifier {
  static const _kAccountsKey = 'finanzas_accounts_v2';
  static const _kCategoriesKey = 'finanzas_categories_v2';
  static const _kTransactionsKey = 'finanzas_transactions_v2';
  static const _kRecurringKey = 'finanzas_recurring_v2';
  static const _kBudgetsKey = 'finanzas_budgets_v2';
  static const _kSettingsKey = 'finanzas_settings_v2';
  static const _kDetectedKey = 'finanzas_detected_v1';
  static const _kLoansKey = 'finanzas_loans_v1';
  static const _kPeopleKey = 'finanzas_people_v1';
  static const MethodChannel _detectorChannel = MethodChannel(
    'com.personal.finanzas/payment_detector',
  );

  SharedPreferences? _prefs;
  bool _initialized = false;

  List<AccountModel> _accounts = [];
  Map<String, AccountModel> _accountById = {};

  List<CategoryModel> _categories = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  Map<String, CategoryModel> _categoryById = {};

  List<TransactionModel> _transactions = [];
  List<RecurringPaymentModel> _recurringPayments = [];
  List<BudgetLimitModel> _budgets = [];
  List<DetectedPaymentModel> _detectedPayments = [];
  List<LoanModel> _loans = [];
  List<String> _savedPeople = [];
  bool _hasNotificationListenerAccess = false;
  bool _hasSmsPermission = false;
  UserSettingsModel _settings = const UserSettingsModel(
    userName: 'Mi Cuenta',
    userEmail: '',
  );

  bool get initialized => _initialized;
  List<AccountModel> get accounts => _accounts;
  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<RecurringPaymentModel> get recurringPayments => _recurringPayments;
  List<BudgetLimitModel> get budgets => _budgets;
  List<DetectedPaymentModel> get detectedPayments => _detectedPayments;
  List<LoanModel> get loans => _loans;
  List<String> get knownPeople {
    final set = <String>{..._savedPeople};
    for (final l in _loans) {
      if (l.personName.trim().isNotEmpty) {
        set.add(l.personName.trim());
      }
    }
    return set.toList(growable: false);
  }
  List<DetectedPaymentModel> get pendingDetectedPayments => _detectedPayments
      .where((d) => !d.isApplied)
      .toList(growable: false);
  bool get hasNotificationListenerAccess => _hasNotificationListenerAccess;
  bool get hasSmsPermission => _hasSmsPermission;
  UserSettingsModel get settings => _settings;

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;

  AccountModel? get defaultAccount {
    if (_accounts.isEmpty) return null;
    for (final a in _accounts) {
      if (a.isDefault) return a;
    }
    return _accounts.first;
  }

  AccountModel? getAccountById(String? id) {
    if (id == null) return null;
    return _accountById[id];
  }

  CategoryModel? getCategoryById(String? id) {
    if (id == null) return null;
    return _categoryById[id];
  }

  void _rebuildAccountIndex() {
    _accountById = {for (final a in _accounts) a.id: a};
  }

  void _rebuildCategoryIndex() {
    _categoryById = {for (final c in _categories) c.id: c};
    _expenseCategories = _categories
        .where((c) => c.kind == CategoryKind.expense)
        .toList(growable: false);
    _incomeCategories = _categories
        .where((c) => c.kind == CategoryKind.income)
        .toList(growable: false);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _removeLegacyV1Keys();
    _loadFromPrefs();
    _processDueRecurringPayments();
    _setupNativePaymentDetector();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _removeLegacyV1Keys() async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (prefs.containsKey('finanzas_accounts_v1')) {
      await prefs.remove('finanzas_accounts_v1');
      await prefs.remove('finanzas_transactions_v1');
      await prefs.remove('finanzas_recurring_v1');
      await prefs.remove('finanzas_budgets_v1');
    }
  }

  void _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;

    final settingsRaw = prefs.getString(_kSettingsKey);
    if (settingsRaw != null) {
      try {
        _settings = UserSettingsModel.fromJson(
          jsonDecode(settingsRaw) as Map<String, dynamic>,
        );
      } catch (_) {
        _settings = const UserSettingsModel(
          userName: 'Mi Cuenta',
          userEmail: '',
        );
      }
    }

    final categoriesRaw = prefs.getString(_kCategoriesKey);
    if (categoriesRaw != null) {
      try {
        final list = jsonDecode(categoriesRaw) as List<dynamic>;
        _categories = list
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _categories = CategoryModel.defaultCategories();
      }
    } else {
      _categories = CategoryModel.defaultCategories();
      _persistCategories();
    }
    _rebuildCategoryIndex();

    final accountsRaw = prefs.getString(_kAccountsKey);
    if (accountsRaw != null) {
      try {
        final list = jsonDecode(accountsRaw) as List<dynamic>;
        _accounts = list
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _accounts = [];
      }
    } else {
      _accounts = [];
    }
    _rebuildAccountIndex();

    final txRaw = prefs.getString(_kTransactionsKey);
    if (txRaw != null) {
      try {
        final list = jsonDecode(txRaw) as List<dynamic>;
        _transactions = list
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _transactions = [];
      }
    } else {
      _transactions = [];
    }

    final recRaw = prefs.getString(_kRecurringKey);
    if (recRaw != null) {
      try {
        final list = jsonDecode(recRaw) as List<dynamic>;
        _recurringPayments = list
            .map(
              (e) => RecurringPaymentModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        _recurringPayments = [];
      }
    } else {
      _recurringPayments = [];
    }

    final budgetsRaw = prefs.getString(_kBudgetsKey);
    if (budgetsRaw != null) {
      try {
        final list = jsonDecode(budgetsRaw) as List<dynamic>;
        _budgets = list
            .map((e) => BudgetLimitModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _budgets = [];
      }
    } else {
      _budgets = [];
    }

    final detectedRaw = prefs.getString(_kDetectedKey);
    if (detectedRaw != null) {
      try {
        final list = jsonDecode(detectedRaw) as List<dynamic>;
        _detectedPayments = list
            .map(
              (e) => DetectedPaymentModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } catch (_) {
        _detectedPayments = [];
      }
    } else {
      _detectedPayments = [];
    }

    final loansRaw = prefs.getString(_kLoansKey);
    if (loansRaw != null) {
      try {
        final list = jsonDecode(loansRaw) as List<dynamic>;
        _loans = list
            .map((e) => LoanModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _loans = [];
      }
    } else {
      _loans = [];
    }

    final peopleRaw = prefs.getString(_kPeopleKey);
    if (peopleRaw != null) {
      try {
        final list = jsonDecode(peopleRaw) as List<dynamic>;
        _savedPeople = list.map((e) => e.toString()).toList();
      } catch (_) {
        _savedPeople = [];
      }
    } else {
      _savedPeople = [];
    }

    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _persistSettings() async {
    await _prefs?.setString(_kSettingsKey, jsonEncode(_settings.toJson()));
  }

  Future<void> _persistCategories() async {
    await _prefs?.setString(
      _kCategoriesKey,
      jsonEncode(_categories.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistAccounts() async {
    await _prefs?.setString(
      _kAccountsKey,
      jsonEncode(_accounts.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistTransactions() async {
    await _prefs?.setString(
      _kTransactionsKey,
      jsonEncode(_transactions.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistRecurring() async {
    await _prefs?.setString(
      _kRecurringKey,
      jsonEncode(_recurringPayments.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistBudgets() async {
    await _prefs?.setString(
      _kBudgetsKey,
      jsonEncode(_budgets.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistDetected() async {
    await _prefs?.setString(
      _kDetectedKey,
      jsonEncode(_detectedPayments.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistLoans() async {
    await _prefs?.setString(
      _kLoansKey,
      jsonEncode(_loans.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistPeople() async {
    await _prefs?.setString(_kPeopleKey, jsonEncode(_savedPeople));
  }

  Future<void> _persistAll() async {
    await Future.wait([
      _persistSettings(),
      _persistCategories(),
      _persistAccounts(),
      _persistTransactions(),
      _persistRecurring(),
      _persistBudgets(),
      _persistDetected(),
      _persistLoans(),
      _persistPeople(),
    ]);
  }

  int _idSeq = 0;
  String _genId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${++_idSeq}';

  void _processDueRecurringPayments() {
    final now = DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    bool changed = false;

    for (var i = 0; i < _recurringPayments.length; i++) {
      final rec = _recurringPayments[i];
      if (!rec.isActive || !rec.autoDebit) continue;
      final account = getAccountById(rec.accountId);
      if (account == null) continue;

      if (rec.isBiweeklySalary) {
        // 1. Check Quincena (1st half)
        if (rec.lastQuincenaYearMonth != ym && now.day >= rec.quincenaDay) {
          _executeRecurringQuincenaInternal(_recurringPayments[i], now, ym);
          changed = true;
        }
        // 2. Check End of Month (2nd half + Bono - ISR)
        final currentRec = _recurringPayments[i];
        if (currentRec.lastDebitedYearMonth != ym &&
            now.day >= currentRec.billingDay) {
          _executeRecurringDebitInternal(currentRec, now, ym);
          changed = true;
        }
      } else {
        if (rec.payFrequency == 'pago_unico' &&
            rec.lastDebitedYearMonth != null) {
          continue;
        }
        if (rec.lastDebitedYearMonth == ym) continue;
        if (now.day >= rec.billingDay) {
          _executeRecurringDebitInternal(rec, now, ym);
          changed = true;
        }
      }
    }

    if (changed) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _persistAccounts();
      _persistTransactions();
      _persistRecurring();
    }
  }

  void _executeRecurringQuincenaInternal(
    RecurringPaymentModel rec,
    DateTime date,
    String yearMonth,
  ) {
    final rate = rec.currency == 'USD' ? _settings.usdToGtqRate : 1.0;
    final quincenaAmount = rec.quincenaNetAmount;
    final convertedAmount = rec.currency == 'USD'
        ? quincenaAmount * rate
        : quincenaAmount;

    final tx = TransactionModel(
      id: _genId('tx_rec_q1'),
      accountId: rec.accountId,
      type: TransactionType.income,
      amount: convertedAmount,
      originalAmount: quincenaAmount,
      originalCurrency: rec.currency,
      exchangeRateUsed: rate,
      categoryId: rec.categoryId,
      categoryName: rec.categoryName,
      subcategory: rec.subcategory,
      note:
          'Quincena (50% Salario): ${rec.name} (${quincenaAmount.toStringAsFixed(2)})',
      date: date,
      isRecurringGenerated: true,
    );

    _transactions.insert(0, tx);
    _applyAccountDelta(
      rec.accountId,
      TransactionType.income,
      convertedAmount,
    );

    final idx = _recurringPayments.indexWhere((r) => r.id == rec.id);
    if (idx != -1) {
      _recurringPayments[idx] = _recurringPayments[idx].copyWith(
        lastQuincenaYearMonth: yearMonth,
      );
    }
  }

  void _executeRecurringDebitInternal(
    RecurringPaymentModel rec,
    DateTime date,
    String yearMonth,
  ) {
    final rate = rec.currency == 'USD' ? _settings.usdToGtqRate : 1.0;

    if (rec.isIncome) {
      final netAmount = rec.isBiweeklySalary
          ? rec.endOfMonthNetAmount
          : rec.netEffectiveAmount;
      final convertedAmount = rec.currency == 'USD'
          ? netAmount * rate
          : netAmount;

      final details = <String>[];
      if (rec.isBiweeklySalary) {
        details.add('50% Base ${(rec.amount / 2.0).toStringAsFixed(2)}');
      } else if (rec.hasBonoDeLey || rec.calculateIsr || rec.deductIgss) {
        details.add('Base ${rec.amount.toStringAsFixed(2)}');
      }
      if (rec.hasBonoDeLey && rec.effectiveBonoDeLey > 0) {
        details.add('+ Bono ${rec.effectiveBonoDeLey.toStringAsFixed(2)}');
      }
      if (rec.calculateIsr && rec.isrDeduction > 0) {
        details.add('- ISR ${rec.isrDeduction.toStringAsFixed(2)}');
      }
      if (rec.deductIgss && rec.igssDeduction > 0) {
        details.add('- IGSS ${rec.igssDeduction.toStringAsFixed(2)}');
      }
      final noteSuffix = details.isNotEmpty ? ' (${details.join(' ')})' : '';
      final prefixTitle = rec.isBiweeklySalary
          ? 'Fin de Mes: ${rec.name}'
          : 'Ingreso (${rec.incomeRegimeLabel}): ${rec.name}';

      final tx = TransactionModel(
        id: _genId('tx_rec_inc'),
        accountId: rec.accountId,
        type: TransactionType.income,
        amount: convertedAmount,
        originalAmount: netAmount,
        originalCurrency: rec.currency,
        exchangeRateUsed: rate,
        categoryId: rec.categoryId,
        categoryName: rec.categoryName,
        subcategory: rec.subcategory,
        note: '$prefixTitle$noteSuffix',
        date: date,
        isRecurringGenerated: true,
      );

      _transactions.insert(0, tx);
      _applyAccountDelta(
        rec.accountId,
        TransactionType.income,
        convertedAmount,
      );
    } else if (rec.isTransfer && rec.targetAccountId != null) {
      final convertedAmount = rec.currency == 'USD'
          ? rec.amount * rate
          : rec.amount;

      final sourceAcc = getAccountById(rec.accountId);
      final targetAcc = getAccountById(rec.targetAccountId);
      if (sourceAcc != null && targetAcc != null) {
        final tx = TransactionModel(
          id: _genId('tx_rec_trf'),
          accountId: rec.accountId,
          targetAccountId: rec.targetAccountId,
          type: TransactionType.transfer,
          amount: convertedAmount,
          originalAmount: rec.amount,
          originalCurrency: rec.currency,
          exchangeRateUsed: rate,
          categoryId: 'cat_transfer',
          categoryName: 'Transferencia Automática',
          subcategory: '${sourceAcc.name} → ${targetAcc.name}',
          note: 'Transferencia recurrente: ${rec.name}',
          date: date,
          isRecurringGenerated: true,
        );

        _transactions.insert(0, tx);
        _applyAccountDelta(
          rec.accountId,
          TransactionType.expense,
          convertedAmount,
        );
        _applyAccountDelta(
          rec.targetAccountId!,
          TransactionType.income,
          convertedAmount,
        );
      }
    } else {
      final convertedAmount = rec.currency == 'USD'
          ? rec.amount * rate
          : rec.amount;

      final account = getAccountById(rec.accountId);
      final cashbackPercent = account != null
          ? account.resolveCashbackPercent(
              categoryId: rec.categoryId,
              subcategory: rec.subcategory,
            )
          : 0.0;
      final cashbackEarned = cashbackPercent > 0
          ? convertedAmount * (cashbackPercent / 100.0)
          : 0.0;

      final tx = TransactionModel(
        id: _genId('tx_rec'),
        accountId: rec.accountId,
        type: TransactionType.expense,
        amount: convertedAmount,
        originalAmount: rec.amount,
        originalCurrency: rec.currency,
        exchangeRateUsed: rate,
        categoryId: rec.categoryId,
        categoryName: rec.categoryName,
        subcategory: rec.subcategory,
        note: 'Pago recurrente: ${rec.name}',
        date: date,
        isRecurringGenerated: true,
        cashbackEarned: cashbackEarned,
        cashbackPercentUsed: cashbackPercent,
      );

      _transactions.insert(0, tx);
      _applyAccountDelta(
        rec.accountId,
        TransactionType.expense,
        convertedAmount - cashbackEarned,
        cashbackDelta: cashbackEarned,
      );
    }

    final idx = _recurringPayments.indexWhere((r) => r.id == rec.id);
    if (idx != -1) {
      _recurringPayments[idx] = _recurringPayments[idx].copyWith(
        lastDebitedYearMonth: yearMonth,
      );
    }
  }

  void _applyAccountDelta(
    String accountId,
    TransactionType type,
    double amountInPrimary, {
    double cashbackDelta = 0.0,
  }) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return;
    final acc = _accounts[idx];

    AccountModel updated;
    if (acc.type == AccountType.credit) {
      if (type == TransactionType.expense) {
        updated = acc.copyWith(
          currentBalance: (acc.currentBalance + amountInPrimary).clamp(
            0.0,
            double.infinity,
          ),
          accumulatedCashback: (acc.accumulatedCashback + cashbackDelta).clamp(
            0.0,
            double.infinity,
          ),
        );
      } else if (type == TransactionType.income) {
        updated = acc.copyWith(
          currentBalance: (acc.currentBalance - amountInPrimary).clamp(
            0.0,
            double.infinity,
          ),
          accumulatedCashback: (acc.accumulatedCashback + cashbackDelta).clamp(
            0.0,
            double.infinity,
          ),
        );
      } else {
        updated = acc;
      }
    } else {
      if (type == TransactionType.expense) {
        updated = acc.copyWith(
          currentBalance: acc.currentBalance - amountInPrimary,
        );
      } else if (type == TransactionType.income) {
        updated = acc.copyWith(
          currentBalance: acc.currentBalance + amountInPrimary,
        );
      } else {
        updated = acc;
      }
    }

    _accounts[idx] = updated;
    _accountById[accountId] = updated;
  }

  Future<void> saveAccount({
    String? id,
    required String name,
    required String description,
    required AccountType type,
    required double initialBalance,
    double? explicitCurrentBalance,
    required int colorValue,
    required String emoji,
    required bool isDefault,
    double annualInterestRate = 0.0,
    double creditLimit = 0.0,
    int cutoffDay = 15,
    int paymentDueDay = 5,
    bool isPaidThisCycle = false,
    bool isDualCurrency = false,
    bool hasCashback = false,
    double defaultCashbackPercent = 0.0,
    List<CashbackRule> cashbackRules = const [],
    String cardLast4Digits = '',
  }) async {
    if (isDefault) {
      _accounts = _accounts.map((a) => a.copyWith(isDefault: false)).toList();
    } else if (_accounts.isEmpty) {
      isDefault = true;
    }

    if (id != null) {
      final idx = _accounts.indexWhere((a) => a.id == id);
      if (idx != -1) {
        final existing = _accounts[idx];
        final updatedCurrentBalance =
            explicitCurrentBalance ??
            (existing.currentBalance +
                (initialBalance - existing.initialBalance));
        _accounts[idx] = existing.copyWith(
          name: name,
          description: description,
          type: type,
          initialBalance: initialBalance,
          currentBalance: updatedCurrentBalance,
          colorValue: colorValue,
          emoji: emoji,
          isDefault: isDefault,
          annualInterestRate: annualInterestRate,
          creditLimit: creditLimit,
          cutoffDay: cutoffDay,
          paymentDueDay: paymentDueDay,
          isPaidThisCycle: isPaidThisCycle,
          isDualCurrency: isDualCurrency,
          hasCashback: hasCashback,
          defaultCashbackPercent: defaultCashbackPercent,
          cashbackRules: List<CashbackRule>.unmodifiable(cashbackRules),
          cardLast4Digits: cardLast4Digits,
        );
      }
    } else {
      final newAcc = AccountModel(
        id: _genId('acc'),
        name: name,
        description: description,
        type: type,
        initialBalance: initialBalance,
        currentBalance: explicitCurrentBalance ?? initialBalance,
        colorValue: colorValue,
        emoji: emoji,
        isDefault: isDefault,
        annualInterestRate: annualInterestRate,
        creditLimit: creditLimit,
        cutoffDay: cutoffDay,
        paymentDueDay: paymentDueDay,
        isPaidThisCycle: isPaidThisCycle,
        isDualCurrency: isDualCurrency,
        hasCashback: hasCashback,
        defaultCashbackPercent: defaultCashbackPercent,
        cashbackRules: List<CashbackRule>.unmodifiable(cashbackRules),
        cardLast4Digits: cardLast4Digits,
      );
      _accounts.add(newAcc);
    }

    if (!_accounts.any((a) => a.isDefault) && _accounts.isNotEmpty) {
      _accounts[0] = _accounts[0].copyWith(isDefault: true);
    }

    _rebuildAccountIndex();
    notifyListeners();
    await _persistAccounts();
  }

  Future<void> setDefaultAccount(String accountId) async {
    _accounts = _accounts
        .map((a) => a.copyWith(isDefault: a.id == accountId))
        .toList();
    _rebuildAccountIndex();
    notifyListeners();
    await _persistAccounts();
  }

  Future<void> toggleCreditCardPaidStatus(String accountId, bool isPaid) async {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return;
    final updated = _accounts[idx].copyWith(isPaidThisCycle: isPaid);
    _accounts[idx] = updated;
    _accountById[accountId] = updated;
    notifyListeners();
    await _persistAccounts();
  }

  Future<void> payCreditCardFromAccount({
    required String creditAccountId,
    required String sourceAccountId,
    required double amountInPrimary,
  }) async {
    final creditAcc = getAccountById(creditAccountId);
    final sourceAcc = getAccountById(sourceAccountId);
    if (creditAcc == null || sourceAcc == null || amountInPrimary <= 0) return;

    _applyAccountDelta(
      sourceAccountId,
      TransactionType.expense,
      amountInPrimary,
    );
    _applyAccountDelta(
      creditAccountId,
      TransactionType.income,
      amountInPrimary,
    );

    final updatedCredit = getAccountById(creditAccountId);
    if (updatedCredit != null && updatedCredit.currentBalance <= 0.01) {
      final idx = _accounts.indexWhere((a) => a.id == creditAccountId);
      if (idx != -1) {
        final zeroed = _accounts[idx].copyWith(
          currentBalance: 0.0,
          isPaidThisCycle: true,
        );
        _accounts[idx] = zeroed;
        _accountById[creditAccountId] = zeroed;
      }
    }

    final tx = TransactionModel(
      id: _genId('tx_pay'),
      accountId: sourceAccountId,
      targetAccountId: creditAccountId,
      type: TransactionType.transfer,
      amount: amountInPrimary,
      originalAmount: amountInPrimary,
      originalCurrency: _settings.primaryCurrency,
      exchangeRateUsed: 1.0,
      categoryId: 'transfer_card_payment',
      categoryName: 'Pago de Tarjeta',
      subcategory: creditAcc.name,
      note: 'Pago a ${creditAcc.name} desde ${sourceAcc.name}',
      date: DateTime.now(),
    );

    _transactions.insert(0, tx);
    notifyListeners();
    await Future.wait([_persistAccounts(), _persistTransactions()]);
  }

  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((a) => a.id == accountId);
    _transactions.removeWhere(
      (t) => t.accountId == accountId || t.targetAccountId == accountId,
    );
    _recurringPayments.removeWhere((r) => r.accountId == accountId);
    if (!_accounts.any((a) => a.isDefault) && _accounts.isNotEmpty) {
      _accounts[0] = _accounts[0].copyWith(isDefault: true);
    }
    _rebuildAccountIndex();
    notifyListeners();
    await Future.wait([
      _persistAccounts(),
      _persistTransactions(),
      _persistRecurring(),
    ]);
  }

  Future<void> addTransaction({
    required String accountId,
    String? targetAccountId,
    required TransactionType type,
    required double originalAmount,
    required String originalCurrency,
    required String categoryId,
    required String categoryName,
    required String subcategory,
    required String note,
    required DateTime date,
    int installmentsTotal = 1,
  }) async {
    final rate = originalCurrency == 'USD' ? _settings.usdToGtqRate : 1.0;
    final convertedTotal = originalCurrency == 'USD'
        ? originalAmount * rate
        : originalAmount;

    if (type == TransactionType.transfer && targetAccountId != null) {
      final sourceAcc = getAccountById(accountId);
      final targetAcc = getAccountById(targetAccountId);
      if (sourceAcc == null || targetAcc == null) return;

      _applyAccountDelta(accountId, TransactionType.expense, convertedTotal);
      _applyAccountDelta(
        targetAccountId,
        TransactionType.income,
        convertedTotal,
      );

      final tx = TransactionModel(
        id: _genId('tx_trf'),
        accountId: accountId,
        targetAccountId: targetAccountId,
        type: TransactionType.transfer,
        amount: convertedTotal,
        originalAmount: originalAmount,
        originalCurrency: originalCurrency,
        exchangeRateUsed: rate,
        categoryId: 'cat_transfer',
        categoryName: 'Transferencia',
        subcategory: '${sourceAcc.name} → ${targetAcc.name}',
        note: note,
        date: date,
      );
      _transactions.insert(0, tx);
    } else {
      final account = getAccountById(accountId);
      final isCreditInstallment =
          account?.type == AccountType.credit &&
          type == TransactionType.expense &&
          installmentsTotal > 1;

      final cashbackPercent =
          (account != null && type == TransactionType.expense)
          ? account.resolveCashbackPercent(
              categoryId: categoryId,
              subcategory: subcategory,
            )
          : 0.0;
      final cashbackEarned = cashbackPercent > 0
          ? convertedTotal * (cashbackPercent / 100.0)
          : 0.0;

      final tx = TransactionModel(
        id: _genId(isCreditInstallment ? 'tx_inst' : 'tx'),
        accountId: accountId,
        type: type,
        amount: convertedTotal,
        originalAmount: originalAmount,
        originalCurrency: originalCurrency,
        exchangeRateUsed: rate,
        categoryId: categoryId,
        categoryName: categoryName,
        subcategory: subcategory,
        note: note,
        date: date,
        installmentsTotal: isCreditInstallment ? installmentsTotal : 1,
        installmentCurrent: 1,
        cashbackEarned: cashbackEarned,
        cashbackPercentUsed: cashbackPercent,
      );
      _transactions.insert(0, tx);
      _applyAccountDelta(
        accountId,
        type,
        convertedTotal - cashbackEarned,
        cashbackDelta: cashbackEarned,
      );
    }

    if (_transactions.length > 1 &&
        _transactions[0].date.isBefore(_transactions[1].date)) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
    await Future.wait([_persistAccounts(), _persistTransactions()]);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx == -1) return;
    final tx = _transactions[idx];

    if (tx.type == TransactionType.transfer && tx.targetAccountId != null) {
      _applyAccountDelta(tx.accountId, TransactionType.income, tx.amount);
      _applyAccountDelta(
        tx.targetAccountId!,
        TransactionType.expense,
        tx.amount,
      );
    } else if (tx.type == TransactionType.expense) {
      _applyAccountDelta(
        tx.accountId,
        TransactionType.income,
        tx.netAmountAfterCashback,
        cashbackDelta: -tx.cashbackEarned,
      );
    } else if (tx.type == TransactionType.income) {
      _applyAccountDelta(tx.accountId, TransactionType.expense, tx.amount);
    }

    _transactions.removeAt(idx);
    notifyListeners();
    await Future.wait([_persistAccounts(), _persistTransactions()]);
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required String emoji,
    required CategoryKind kind,
    required List<String> subcategories,
    required int colorValue,
  }) async {
    if (id != null) {
      final idx = _categories.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _categories[idx] = _categories[idx].copyWith(
          name: name,
          emoji: emoji,
          kind: kind,
          subcategories: subcategories,
          colorValue: colorValue,
        );
      }
    } else {
      _categories.add(
        CategoryModel(
          id: _genId('cat'),
          name: name,
          emoji: emoji,
          kind: kind,
          subcategories: subcategories,
          colorValue: colorValue,
          isCustom: true,
        ),
      );
    }
    _rebuildCategoryIndex();
    notifyListeners();
    await _persistCategories();
  }

  Future<void> addSubcategory(String categoryId, String newSubcategory) async {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;
    final current = List<String>.from(_categories[idx].subcategories);
    if (!current.contains(newSubcategory.trim())) {
      current.add(newSubcategory.trim());
      _categories[idx] = _categories[idx].copyWith(subcategories: current);
      _rebuildCategoryIndex();
      notifyListeners();
      await _persistCategories();
    }
  }

  Future<void> removeSubcategory(String categoryId, String subcategory) async {
    final idx = _categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;
    final current = List<String>.from(_categories[idx].subcategories)
      ..remove(subcategory);
    _categories[idx] = _categories[idx].copyWith(subcategories: current);
    _rebuildCategoryIndex();
    notifyListeners();
    await _persistCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    _rebuildCategoryIndex();
    notifyListeners();
    await _persistCategories();
  }

  Future<void> resetCategoriesToDefault() async {
    _categories = CategoryModel.defaultCategories();
    _rebuildCategoryIndex();
    notifyListeners();
    await _persistCategories();
  }

  Future<void> saveRecurringPayment({
    String? id,
    required String name,
    required double amount,
    required String currency,
    required String accountId,
    String? targetAccountId,
    required String categoryId,
    required String categoryName,
    required String subcategory,
    required int billingDay,
    required bool autoDebit,
    bool isIncome = false,
    bool isTransfer = false,
    String incomeRegime = 'planilla',
    String payFrequency = 'mensual',
    int quincenaDay = 15,
    bool deductionsAndBonoAtEndOfMonth = true,
    bool hasBonoDeLey = false,
    double bonoDeLeyAmount = 250.0,
    bool calculateIsr = false,
    String isrMode = 'sat_gt',
    double customIsrPercent = 5.0,
    bool deductIgss = false,
  }) async {
    if (id != null) {
      final idx = _recurringPayments.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _recurringPayments[idx] = _recurringPayments[idx].copyWith(
          name: name,
          amount: amount,
          currency: currency,
          accountId: accountId,
          targetAccountId: isTransfer ? targetAccountId : null,
          categoryId: categoryId,
          categoryName: categoryName,
          subcategory: subcategory,
          billingDay: billingDay,
          autoDebit: autoDebit,
          isIncome: isIncome,
          isTransfer: isTransfer,
          incomeRegime: isIncome ? incomeRegime : 'planilla',
          payFrequency: isIncome ? payFrequency : 'mensual',
          quincenaDay: quincenaDay,
          deductionsAndBonoAtEndOfMonth: deductionsAndBonoAtEndOfMonth,
          hasBonoDeLey: isIncome ? hasBonoDeLey : false,
          bonoDeLeyAmount: isIncome ? bonoDeLeyAmount : 0.0,
          calculateIsr: isIncome ? calculateIsr : false,
          isrMode: isrMode,
          customIsrPercent: customIsrPercent,
          deductIgss: isIncome ? deductIgss : false,
        );
      }
    } else {
      final rec = RecurringPaymentModel(
        id: _genId('rec'),
        name: name,
        amount: amount,
        currency: currency,
        accountId: accountId,
        targetAccountId: isTransfer ? targetAccountId : null,
        categoryId: categoryId,
        categoryName: categoryName,
        subcategory: subcategory,
        billingDay: billingDay,
        autoDebit: autoDebit,
        isIncome: isIncome,
        isTransfer: isTransfer,
        incomeRegime: isIncome ? incomeRegime : 'planilla',
        payFrequency: isIncome ? payFrequency : 'mensual',
        quincenaDay: quincenaDay,
        deductionsAndBonoAtEndOfMonth: deductionsAndBonoAtEndOfMonth,
        hasBonoDeLey: isIncome ? hasBonoDeLey : false,
        bonoDeLeyAmount: isIncome ? bonoDeLeyAmount : 0.0,
        calculateIsr: isIncome ? calculateIsr : false,
        isrMode: isrMode,
        customIsrPercent: customIsrPercent,
        deductIgss: isIncome ? deductIgss : false,
      );
      _recurringPayments.add(rec);
    }
    _processDueRecurringPayments();
    notifyListeners();
    await _persistRecurring();
  }

  Future<void> toggleRecurringQuincenaThisMonth(String recurringId) async {
    final idx = _recurringPayments.indexWhere((r) => r.id == recurringId);
    if (idx == -1) return;
    final rec = _recurringPayments[idx];
    final now = DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (rec.isQuincenaPaidForMonth(now)) {
      _recurringPayments[idx] = rec.copyWith(clearLastQuincena: true);
    } else {
      _executeRecurringQuincenaInternal(rec, now, ym);
    }
    notifyListeners();
    await Future.wait([
      _persistAccounts(),
      _persistTransactions(),
      _persistRecurring(),
    ]);
  }

  Future<void> toggleRecurringDebitedThisMonth(String recurringId) async {
    final idx = _recurringPayments.indexWhere((r) => r.id == recurringId);
    if (idx == -1) return;
    final rec = _recurringPayments[idx];
    final now = DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (rec.isDebitedForMonth(now)) {
      _recurringPayments[idx] = rec.copyWith(clearLastDebited: true);
    } else {
      _executeRecurringDebitInternal(rec, now, ym);
    }
    notifyListeners();
    await Future.wait([
      _persistAccounts(),
      _persistTransactions(),
      _persistRecurring(),
    ]);
  }

  Future<void> deleteRecurringPayment(String id) async {
    _recurringPayments.removeWhere((r) => r.id == id);
    notifyListeners();
    await _persistRecurring();
  }

  Future<void> saveBudgetLimit({
    String? id,
    required String name,
    required double monthlyLimit,
    String? categoryId,
    String? subcategory,
    required int colorValue,
    required String emoji,
  }) async {
    if (id != null) {
      final idx = _budgets.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _budgets[idx] = _budgets[idx].copyWith(
          name: name,
          monthlyLimit: monthlyLimit,
          categoryId: categoryId,
          subcategory: subcategory,
          colorValue: colorValue,
          emoji: emoji,
        );
      }
    } else {
      _budgets.add(
        BudgetLimitModel(
          id: _genId('bud'),
          name: name,
          monthlyLimit: monthlyLimit,
          categoryId: categoryId,
          subcategory: subcategory,
          colorValue: colorValue,
          emoji: emoji,
        ),
      );
    }
    notifyListeners();
    await _persistBudgets();
  }

  Future<void> deleteBudgetLimit(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persistBudgets();
  }

  // Loans & People management
  Future<void> addSavedPerson(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (!_savedPeople.any((p) => p.toLowerCase() == clean.toLowerCase())) {
      _savedPeople.add(clean);
      notifyListeners();
      await _persistPeople();
    }
  }

  Future<void> saveLoan({
    String? id,
    required LoanKind kind,
    required String personName,
    String personEmoji = '👤',
    String concept = '',
    required double principalAmount,
    double interestPercent = 0.0,
    required String currency,
    String? accountId,
    DateTime? dueDate,
    int installmentsCount = 1,
    bool affectAccountBalance = false,
  }) async {
    final cleanPerson = personName.trim();
    if (cleanPerson.isNotEmpty &&
        !_savedPeople.any(
          (p) => p.toLowerCase() == cleanPerson.toLowerCase(),
        )) {
      _savedPeople.add(cleanPerson);
    }

    if (id != null) {
      final idx = _loans.indexWhere((l) => l.id == id);
      if (idx != -1) {
        _loans[idx] = _loans[idx].copyWith(
          kind: kind,
          personName: cleanPerson,
          personEmoji: personEmoji,
          concept: concept.trim(),
          principalAmount: principalAmount,
          interestPercent: interestPercent,
          currency: currency,
          accountId: accountId,
          dueDate: dueDate,
          clearDueDate: dueDate == null,
          installmentsCount: installmentsCount,
        );
      }
    } else {
      final newLoan = LoanModel(
        id: _genId('loan'),
        kind: kind,
        personName: cleanPerson,
        personEmoji: personEmoji,
        concept: concept.trim(),
        principalAmount: principalAmount,
        interestPercent: interestPercent,
        currency: currency,
        accountId: accountId,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        installmentsCount: installmentsCount,
      );
      _loans.insert(0, newLoan);

      if (affectAccountBalance &&
          accountId != null &&
          getAccountById(accountId) != null) {
        final rate = currency == 'USD' ? _settings.usdToGtqRate : 1.0;
        final converted = currency == 'USD'
            ? principalAmount * rate
            : principalAmount;
        final txType = kind == LoanKind.lent
            ? TransactionType.expense
            : TransactionType.income;

        final tx = TransactionModel(
          id: _genId('tx_loan'),
          accountId: accountId,
          type: txType,
          amount: converted,
          originalAmount: principalAmount,
          originalCurrency: currency,
          exchangeRateUsed: rate,
          categoryId: 'cat_loan',
          categoryName: kind == LoanKind.lent
              ? 'Préstamo otorgado'
              : 'Préstamo recibido',
          subcategory: cleanPerson,
          note: concept.trim().isNotEmpty
              ? '${kind == LoanKind.lent ? 'Presté a' : 'Me prestó'} $cleanPerson: ${concept.trim()}'
              : '${kind == LoanKind.lent ? 'Presté dinero a' : 'Me prestó dinero'} $cleanPerson',
          date: DateTime.now(),
        );
        _transactions.insert(0, tx);
        _applyAccountDelta(accountId, txType, converted);
      }
    }

    notifyListeners();
    await Future.wait([
      _persistLoans(),
      _persistPeople(),
      _persistAccounts(),
      _persistTransactions(),
    ]);
  }

  Future<void> registerLoanPayment({
    required String loanId,
    required double amount,
    String? accountId,
    String note = '',
  }) async {
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx == -1 || amount <= 0) return;

    final loan = _loans[idx];
    final record = LoanPaymentRecord(
      id: _genId('lpay'),
      amount: amount,
      accountId: accountId,
      note: note.trim(),
      date: DateTime.now(),
    );

    final updatedPayments = [record, ...loan.payments];
    final newPaid = (loan.paidAmount + amount).clamp(0.0, loan.totalAmount);
    _loans[idx] = loan.copyWith(
      paidAmount: newPaid,
      payments: updatedPayments,
    );

    if (accountId != null && getAccountById(accountId) != null) {
      final rate = loan.currency == 'USD' ? _settings.usdToGtqRate : 1.0;
      final converted = loan.currency == 'USD' ? amount * rate : amount;
      // If we lent money, a payment is incoming money (income). If we borrowed, a payment is outgoing (expense).
      final txType = loan.kind == LoanKind.lent
          ? TransactionType.income
          : TransactionType.expense;

      final tx = TransactionModel(
        id: _genId('tx_lpay'),
        accountId: accountId,
        type: txType,
        amount: converted,
        originalAmount: amount,
        originalCurrency: loan.currency,
        exchangeRateUsed: rate,
        categoryId: 'cat_loan_payment',
        categoryName: loan.kind == LoanKind.lent
            ? 'Cobro de Préstamo'
            : 'Pago de Préstamo',
        subcategory: loan.personName,
        note: note.trim().isNotEmpty
            ? 'Abono (${loan.personName}): ${note.trim()}'
            : 'Abono de préstamo • ${loan.personName}',
        date: DateTime.now(),
      );
      _transactions.insert(0, tx);
      _applyAccountDelta(accountId, txType, converted);
    }

    notifyListeners();
    await Future.wait([
      _persistLoans(),
      _persistAccounts(),
      _persistTransactions(),
    ]);
  }

  Future<void> deleteLoan(String loanId) async {
    _loans.removeWhere((l) => l.id == loanId);
    notifyListeners();
    await _persistLoans();
  }

  double calculateBudgetSpent(BudgetLimitModel budget, {DateTime? month}) {
    final ref = month ?? DateTime.now();
    final filterCat = budget.categoryId != null && budget.categoryId!.isNotEmpty
        ? budget.categoryId
        : null;
    final filterSub =
        budget.subcategory != null && budget.subcategory!.isNotEmpty
        ? budget.subcategory!.toLowerCase()
        : null;

    var sum = 0.0;
    for (final tx in _transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.year != ref.year || tx.date.month != ref.month) continue;
      if (filterCat != null && tx.categoryId != filterCat) continue;
      if (filterSub != null && tx.subcategory.toLowerCase() != filterSub) {
        continue;
      }
      sum += tx.amount;
    }
    return sum;
  }

  double totalIncome({String? accountId, DateTime? month}) {
    var sum = 0.0;
    for (final tx in _transactions) {
      if (tx.type != TransactionType.income) continue;
      if (accountId != null && tx.accountId != accountId) continue;
      if (month != null &&
          (tx.date.year != month.year || tx.date.month != month.month)) {
        continue;
      }
      sum += tx.amount;
    }
    return sum;
  }

  double totalExpenses({String? accountId, DateTime? month}) {
    var sum = 0.0;
    for (final tx in _transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (accountId != null && tx.accountId != accountId) continue;
      if (month != null &&
          (tx.date.year != month.year || tx.date.month != month.month)) {
        continue;
      }
      sum += tx.amount;
    }
    return sum;
  }

  Future<void> updateSettings(UserSettingsModel newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> lockOrLogoutSession() async {
    _settings = _settings.copyWith(isSessionLocked: true);
    notifyListeners();
    await _persistSettings();
  }

  Future<bool> unlockSession({String? pinAttempt}) async {
    if (_settings.pinCode != null && _settings.pinCode!.isNotEmpty) {
      if (pinAttempt != _settings.pinCode) {
        return false;
      }
    }
    _settings = _settings.copyWith(isSessionLocked: false);
    notifyListeners();
    await _persistSettings();
    return true;
  }

  Future<void> clearAllUserData() async {
    _accounts = [];
    _transactions = [];
    _recurringPayments = [];
    _budgets = [];
    _detectedPayments = [];
    _loans = [];
    _savedPeople = [];
    _categories = CategoryModel.defaultCategories();
    _rebuildAccountIndex();
    _rebuildCategoryIndex();
    notifyListeners();
    await _persistAll();
  }

  void _setupNativePaymentDetector() {
    _detectorChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPaymentDetected' && call.arguments is Map) {
        final raw = Map<String, dynamic>.from(call.arguments as Map);
        await _ingestRawNativeEvent(raw, isFromNativeListener: true);
      } else if (call.method == 'onPermissionsUpdated' &&
          call.arguments is Map) {
        final perms = Map<String, dynamic>.from(call.arguments as Map);
        _hasNotificationListenerAccess =
            (perms['notificationAccess'] as bool?) ?? false;
        _hasSmsPermission = (perms['smsPermission'] as bool?) ?? false;
        notifyListeners();
      }
    });
    refreshDetectorPermissionsAndQueue();
  }

  Future<void> refreshDetectorPermissionsAndQueue() async {
    try {
      final perms = await _detectorChannel.invokeMapMethod<String, dynamic>(
        'checkPermissions',
      );
      if (perms != null) {
        _hasNotificationListenerAccess =
            (perms['notificationAccess'] as bool?) ?? false;
        _hasSmsPermission = (perms['smsPermission'] as bool?) ?? false;
      }
      final queued = await _detectorChannel.invokeListMethod<dynamic>(
        'consumeQueuedPayments',
      );
      if (queued != null && queued.isNotEmpty) {
        for (final item in queued) {
          if (item is Map) {
            await _ingestRawNativeEvent(
              Map<String, dynamic>.from(item),
              isFromNativeListener: true,
            );
          }
        }
      }
      notifyListeners();
    } catch (_) {
      // Running in widget tests or non-Android host
    }
  }

  Future<bool> openNotificationListenerSettings() async {
    try {
      final opened = await _detectorChannel.invokeMethod<bool>(
        'openNotificationListenerSettings',
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppDetailsSettings() async {
    try {
      final opened = await _detectorChannel.invokeMethod<bool>(
        'openAppDetailsSettings',
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestSmsPermission() async {
    try {
      final granted = await _detectorChannel.invokeMethod<bool>(
        'requestSmsPermission',
      );
      _hasSmsPermission = granted ?? false;
      notifyListeners();
      return _hasSmsPermission;
    } catch (_) {
      return false;
    }
  }

  Future<DetectedPaymentModel?> processRawPaymentMessage({
    required String source,
    required String title,
    required String body,
    DateTime? timestamp,
  }) async {
    final map = <String, dynamic>{
      'id': _genId('det'),
      'source': source,
      'packageName': source,
      'title': title,
      'body': body,
      'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
    };
    return _ingestRawNativeEvent(map, isFromNativeListener: false);
  }

  Future<DetectedPaymentModel?> _ingestRawNativeEvent(
    Map<String, dynamic> raw, {
    bool isFromNativeListener = false,
  }) async {
    final id = (raw['id'] as String?) ?? _genId('det');
    if (_detectedPayments.any((d) => d.id == id)) return null;

    final source = (raw['source'] as String?) ?? 'bank_notification';
    if (isFromNativeListener) {
      if (source == 'bank_sms' && !_settings.smsDetectorEnabled) {
        return null;
      }
      if ((source == 'google_wallet' || source == 'bank_notification') &&
          !_settings.walletDetectorEnabled) {
        return null;
      }
    }
    final pkg = (raw['packageName'] as String?) ?? '';
    final title = (raw['title'] as String?) ?? '';
    final body = (raw['body'] as String?) ?? '';
    final tsMs =
        (raw['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(tsMs);

    final parsed = PaymentParser.parse(
      id: id,
      source: source,
      packageName: pkg,
      title: title,
      body: body,
      timestamp: dt,
      accounts: _accounts,
      expenseCategories: _expenseCategories,
      defaultCurrency: _settings.primaryCurrency,
    );

    if (parsed == null) return null;

    final canAutoApply =
        _settings.autoRegisterDetectedPayments &&
        parsed.matchedAccountId != null &&
        getAccountById(parsed.matchedAccountId) != null;

    if (canAutoApply) {
      final applied = parsed.copyWith(isApplied: true);
      _detectedPayments.insert(0, applied);
      if (_detectedPayments.length > 50) {
        _detectedPayments.removeRange(50, _detectedPayments.length);
      }
      await addTransaction(
        accountId: applied.matchedAccountId!,
        type: TransactionType.expense,
        originalAmount: applied.amount,
        originalCurrency: applied.currency,
        categoryId: applied.categoryId,
        categoryName: applied.categoryName,
        subcategory: applied.subcategory,
        note: '${applied.sourceLabel}: ${applied.merchant}',
        date: applied.detectedAt,
      );
      await _persistDetected();
      return applied;
    } else {
      _detectedPayments.insert(0, parsed);
      if (_detectedPayments.length > 50) {
        _detectedPayments.removeRange(50, _detectedPayments.length);
      }
      notifyListeners();
      await _persistDetected();
      return parsed;
    }
  }

  Future<void> approveDetectedPayment(
    String detectedId, {
    String? overrideAccountId,
  }) async {
    final idx = _detectedPayments.indexWhere((d) => d.id == detectedId);
    if (idx == -1) return;
    final det = _detectedPayments[idx];
    if (det.isApplied) return;

    final targetAccountId =
        overrideAccountId ?? det.matchedAccountId ?? defaultAccount?.id;
    if (targetAccountId == null) return;

    _detectedPayments[idx] = det.copyWith(
      isApplied: true,
      matchedAccountId: targetAccountId,
    );

    await addTransaction(
      accountId: targetAccountId,
      type: TransactionType.expense,
      originalAmount: det.amount,
      originalCurrency: det.currency,
      categoryId: det.categoryId,
      categoryName: det.categoryName,
      subcategory: det.subcategory,
      note: '${det.sourceLabel}: ${det.merchant}',
      date: det.detectedAt,
    );
    await _persistDetected();
  }

  Future<void> dismissDetectedPayment(String detectedId) async {
    _detectedPayments.removeWhere((d) => d.id == detectedId);
    notifyListeners();
    await _persistDetected();
  }

  String exportBackupJson() {
    final data = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': _settings.toJson(),
      'accounts': _accounts.map((e) => e.toJson()).toList(),
      'categories': _categories.map((e) => e.toJson()).toList(),
      'transactions': _transactions.map((e) => e.toJson()).toList(),
      'recurringPayments': _recurringPayments.map((e) => e.toJson()).toList(),
      'budgets': _budgets.map((e) => e.toJson()).toList(),
      'loans': _loans.map((e) => e.toJson()).toList(),
      'savedPeople': _savedPeople,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      if (map['settings'] != null) {
        _settings = UserSettingsModel.fromJson(
          map['settings'] as Map<String, dynamic>,
        );
      }
      if (map['accounts'] != null) {
        _accounts = (map['accounts'] as List<dynamic>)
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (map['categories'] != null) {
        _categories = (map['categories'] as List<dynamic>)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (map['transactions'] != null) {
        _transactions = (map['transactions'] as List<dynamic>)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (map['recurringPayments'] != null) {
        _recurringPayments = (map['recurringPayments'] as List<dynamic>)
            .map(
              (e) => RecurringPaymentModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
      if (map['budgets'] != null) {
        _budgets = (map['budgets'] as List<dynamic>)
            .map((e) => BudgetLimitModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (map['loans'] != null) {
        _loans = (map['loans'] as List<dynamic>)
            .map((e) => LoanModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (map['savedPeople'] != null) {
        _savedPeople = (map['savedPeople'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }
      _rebuildAccountIndex();
      _rebuildCategoryIndex();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      await _persistAll();
      return true;
    } catch (_) {
      return false;
    }
  }
}
