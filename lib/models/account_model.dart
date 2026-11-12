enum AccountType {
  debit,
  savings,
  credit,
}

class CashbackRule {
  final String id;
  final String categoryId;
  final String categoryName;
  final String? subcategory; // null = entire category
  final double percentage;

  const CashbackRule({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.subcategory,
    required this.percentage,
  });

  String get displayLabel {
    final target = (subcategory != null && subcategory!.isNotEmpty)
        ? subcategory!
        : categoryName;
    final pctText = percentage % 1 == 0
        ? percentage.toInt().toString()
        : percentage.toStringAsFixed(1);
    return '$pctText% en $target';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategory': subcategory,
      'percentage': percentage,
    };
  }

  factory CashbackRule.fromJson(Map<String, dynamic> json) {
    return CashbackRule(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      subcategory: json['subcategory'] as String?,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class AccountModel {
  final String id;
  final String name;
  final String description;
  final AccountType type;
  final double initialBalance;
  final double currentBalance; // For debit/savings: available funds. For credit: consumed debt in primary currency
  final int colorValue;
  final String emoji;
  final bool isDefault;

  // Savings specific
  final double annualInterestRate;

  // Credit card specific
  final double creditLimit;
  final int cutoffDay;
  final int paymentDueDay;
  final bool isPaidThisCycle;
  final bool isDualCurrency;
  final bool hasCashback;
  final double defaultCashbackPercent; // "% en todo lo demás"
  final List<CashbackRule> cashbackRules;
  final double accumulatedCashback;
  final String cardLast4Digits;

  const AccountModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    required this.colorValue,
    required this.emoji,
    this.isDefault = false,
    this.annualInterestRate = 0.0,
    this.creditLimit = 0.0,
    this.cutoffDay = 15,
    this.paymentDueDay = 5,
    this.isPaidThisCycle = false,
    this.isDualCurrency = false,
    this.hasCashback = false,
    this.defaultCashbackPercent = 0.0,
    this.cashbackRules = const [],
    this.accumulatedCashback = 0.0,
    this.cardLast4Digits = '',
  });

  double get availableCredit {
    if (type != AccountType.credit) return 0.0;
    return (creditLimit - currentBalance).clamp(0.0, double.infinity);
  }

  double get creditUsageRatio {
    if (type != AccountType.credit || creditLimit <= 0) return 0.0;
    return (currentBalance / creditLimit).clamp(0.0, 1.0);
  }

  /// Resolves the cashback percentage applicable for a given category and subcategory.
  /// Priority:
  /// 1. Exact subcategory rule
  /// 2. Category-wide rule (subcategory == null)
  /// 3. Default cashback percentage ("todo lo demás")
  double resolveCashbackPercent({
    required String categoryId,
    required String subcategory,
  }) {
    if (type != AccountType.credit || !hasCashback) return 0.0;

    final subLower = subcategory.trim().toLowerCase();
    for (final rule in cashbackRules) {
      if (rule.subcategory != null &&
          rule.subcategory!.trim().isNotEmpty &&
          rule.subcategory!.trim().toLowerCase() == subLower &&
          (rule.categoryId == categoryId || rule.categoryId.isEmpty)) {
        return rule.percentage;
      }
    }

    for (final rule in cashbackRules) {
      if ((rule.subcategory == null || rule.subcategory!.trim().isEmpty) &&
          rule.categoryId == categoryId) {
        return rule.percentage;
      }
    }

    return defaultCashbackPercent;
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? description,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    int? colorValue,
    String? emoji,
    bool? isDefault,
    double? annualInterestRate,
    double? creditLimit,
    int? cutoffDay,
    int? paymentDueDay,
    bool? isPaidThisCycle,
    bool? isDualCurrency,
    bool? hasCashback,
    double? defaultCashbackPercent,
    List<CashbackRule>? cashbackRules,
    double? accumulatedCashback,
    String? cardLast4Digits,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      isDefault: isDefault ?? this.isDefault,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      creditLimit: creditLimit ?? this.creditLimit,
      cutoffDay: cutoffDay ?? this.cutoffDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      isPaidThisCycle: isPaidThisCycle ?? this.isPaidThisCycle,
      isDualCurrency: isDualCurrency ?? this.isDualCurrency,
      hasCashback: hasCashback ?? this.hasCashback,
      defaultCashbackPercent:
          defaultCashbackPercent ?? this.defaultCashbackPercent,
      cashbackRules: cashbackRules ?? this.cashbackRules,
      accumulatedCashback: accumulatedCashback ?? this.accumulatedCashback,
      cardLast4Digits: cardLast4Digits ?? this.cardLast4Digits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'colorValue': colorValue,
      'emoji': emoji,
      'isDefault': isDefault,
      'annualInterestRate': annualInterestRate,
      'creditLimit': creditLimit,
      'cutoffDay': cutoffDay,
      'paymentDueDay': paymentDueDay,
      'isPaidThisCycle': isPaidThisCycle,
      'isDualCurrency': isDualCurrency,
      'hasCashback': hasCashback,
      'defaultCashbackPercent': defaultCashbackPercent,
      'cashbackRules': cashbackRules.map((r) => r.toJson()).toList(),
      'accumulatedCashback': accumulatedCashback,
      'cardLast4Digits': cardLast4Digits,
    };
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.debit,
      ),
      initialBalance: (json['initialBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      emoji: json['emoji'] as String,
      isDefault: (json['isDefault'] as bool?) ?? false,
      annualInterestRate:
          (json['annualInterestRate'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      cutoffDay: (json['cutoffDay'] as int?) ?? 15,
      paymentDueDay: (json['paymentDueDay'] as int?) ?? 5,
      isPaidThisCycle: (json['isPaidThisCycle'] as bool?) ?? false,
      isDualCurrency: (json['isDualCurrency'] as bool?) ?? false,
      hasCashback: (json['hasCashback'] as bool?) ?? false,
      defaultCashbackPercent:
          (json['defaultCashbackPercent'] as num?)?.toDouble() ?? 0.0,
      cashbackRules:
          (json['cashbackRules'] as List<dynamic>?)
              ?.map((e) => CashbackRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      accumulatedCashback:
          (json['accumulatedCashback'] as num?)?.toDouble() ?? 0.0,
      cardLast4Digits: (json['cardLast4Digits'] as String?) ?? '',
    );
  }
}
