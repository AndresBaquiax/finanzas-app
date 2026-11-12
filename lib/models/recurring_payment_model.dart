class RecurringPaymentModel {
  final String id;
  final String name;
  final double amount; // For expense/transfer: payment amount. For income: total monthly base salary / income
  final String currency; // 'GTQ' or 'USD'
  final String accountId; // Source account (or destination account for income)
  final String? targetAccountId; // Destination account when isTransfer == true
  final String categoryId;
  final String categoryName;
  final String subcategory;
  final int billingDay; // 1..31 (For biweekly: End of Month day, default 30)
  final bool autoDebit;
  final String? lastDebitedYearMonth; // Format: 'YYYY-MM' (Monthly or End-of-Month payment)
  final bool isActive;

  // Kind flags
  final bool isIncome;
  final bool isTransfer;

  // Recurring Income / Salary / Biweekly specific fields
  final String incomeRegime; // 'planilla', 'servicios', 'unico'
  final String payFrequency; // 'mensual', 'quincenal_fin_mes', 'pago_unico'
  final int quincenaDay; // Default 15
  final bool deductionsAndBonoAtEndOfMonth; // true = Quincena is 50% base clean; Fin de Mes is 50% base + Bono - ISR - IGSS
  final String? lastQuincenaYearMonth; // Format: 'YYYY-MM'
  final bool hasBonoDeLey;
  final double bonoDeLeyAmount;
  final bool calculateIsr;
  final String isrMode; // 'sat_gt', 'servicios_gt', 'flat_percent'
  final double customIsrPercent;
  final bool deductIgss;

  const RecurringPaymentModel({
    required this.id,
    required this.name,
    required this.amount,
    this.currency = 'GTQ',
    required this.accountId,
    this.targetAccountId,
    required this.categoryId,
    required this.categoryName,
    required this.subcategory,
    required this.billingDay,
    this.autoDebit = true,
    this.lastDebitedYearMonth,
    this.isActive = true,
    this.isIncome = false,
    this.isTransfer = false,
    this.incomeRegime = 'planilla',
    this.payFrequency = 'mensual',
    this.quincenaDay = 15,
    this.deductionsAndBonoAtEndOfMonth = true,
    this.lastQuincenaYearMonth,
    this.hasBonoDeLey = false,
    this.bonoDeLeyAmount = 250.0,
    this.calculateIsr = false,
    this.isrMode = 'sat_gt',
    this.customIsrPercent = 5.0,
    this.deductIgss = false,
  });

  bool get isBiweeklySalary =>
      isIncome && payFrequency == 'quincenal_fin_mes';

  bool isDebitedForMonth(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return lastDebitedYearMonth == key;
  }

  bool isQuincenaPaidForMonth(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return lastQuincenaYearMonth == key;
  }

  bool isFullyProcessedForMonth(DateTime date) {
    if (isBiweeklySalary) {
      return isQuincenaPaidForMonth(date) && isDebitedForMonth(date);
    }
    return isDebitedForMonth(date);
  }

  String get incomeRegimeLabel {
    switch (incomeRegime) {
      case 'planilla':
        return 'Planilla';
      case 'servicios':
        return 'Servicios / Facturado';
      case 'unico':
        return 'Pago Único';
      default:
        return 'Ingreso';
    }
  }

  double get effectiveBonoDeLey =>
      (isIncome && hasBonoDeLey && bonoDeLeyAmount > 0) ? bonoDeLeyAmount : 0.0;

  double get grossAmount => amount + effectiveBonoDeLey;

  double get igssDeduction =>
      (isIncome && deductIgss && amount > 0) ? (amount * 0.0483) : 0.0;

  double get isrDeduction {
    if (!isIncome || !calculateIsr || amount <= 0) return 0.0;
    return computeIsrMonthly(
      baseSalary: amount,
      bonoDeLey: effectiveBonoDeLey,
      mode: isrMode,
      customPercent: customIsrPercent,
      deductIgss: deductIgss,
    );
  }

  /// Total monthly net amount.
  /// For expenses/transfers: returns `amount`.
  /// For income (salary): returns `Salario Base + Bono de Ley - ISR - IGSS`.
  double get netEffectiveAmount {
    if (!isIncome) return amount;
    return (grossAmount - isrDeduction - igssDeduction).clamp(
      0.0,
      double.infinity,
    );
  }

  /// Net amount paid on Quincena (1st payment of the month, e.g. day 15).
  double get quincenaNetAmount {
    if (!isBiweeklySalary) return netEffectiveAmount;
    final halfBase = amount / 2.0;
    if (deductionsAndBonoAtEndOfMonth) {
      return halfBase;
    }
    return (halfBase +
            (effectiveBonoDeLey / 2.0) -
            (isrDeduction / 2.0) -
            (igssDeduction / 2.0))
        .clamp(0.0, double.infinity);
  }

  /// Net amount paid at End of Month (2nd payment of the month, e.g. day 30).
  double get endOfMonthNetAmount {
    if (!isBiweeklySalary) return netEffectiveAmount;
    final halfBase = amount / 2.0;
    if (deductionsAndBonoAtEndOfMonth) {
      return (halfBase + effectiveBonoDeLey - isrDeduction - igssDeduction)
          .clamp(0.0, double.infinity);
    }
    return (halfBase +
            (effectiveBonoDeLey / 2.0) -
            (isrDeduction / 2.0) -
            (igssDeduction / 2.0))
        .clamp(0.0, double.infinity);
  }

  static double computeIsrMonthly({
    required double baseSalary,
    required double bonoDeLey,
    required String mode,
    required double customPercent,
    required bool deductIgss,
  }) {
    if (baseSalary <= 0) return 0.0;

    if (mode == 'flat_percent') {
      final pct = customPercent.clamp(0.0, 100.0);
      return baseSalary * (pct / 100.0);
    }

    if (mode == 'servicios_gt') {
      if (baseSalary <= 30000.0) {
        return baseSalary * 0.05;
      } else {
        return 1500.0 + (baseSalary - 30000.0) * 0.07;
      }
    }

    final annualGross = (baseSalary + bonoDeLey) * 12.0;
    final annualIgss = deductIgss ? (baseSalary * 0.0483 * 12.0) : 0.0;
    final taxableAnnual = annualGross - 48000.0 - annualIgss;

    if (taxableAnnual <= 0) return 0.0;

    if (taxableAnnual <= 300000.0) {
      return (taxableAnnual * 0.05) / 12.0;
    } else {
      return (15000.0 + (taxableAnnual - 300000.0) * 0.07) / 12.0;
    }
  }

  RecurringPaymentModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? currency,
    String? accountId,
    String? targetAccountId,
    String? categoryId,
    String? categoryName,
    String? subcategory,
    int? billingDay,
    bool? autoDebit,
    String? lastDebitedYearMonth,
    bool clearLastDebited = false,
    bool? isActive,
    bool? isIncome,
    bool? isTransfer,
    String? incomeRegime,
    String? payFrequency,
    int? quincenaDay,
    bool? deductionsAndBonoAtEndOfMonth,
    String? lastQuincenaYearMonth,
    bool clearLastQuincena = false,
    bool? hasBonoDeLey,
    double? bonoDeLeyAmount,
    bool? calculateIsr,
    String? isrMode,
    double? customIsrPercent,
    bool? deductIgss,
  }) {
    return RecurringPaymentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      billingDay: billingDay ?? this.billingDay,
      autoDebit: autoDebit ?? this.autoDebit,
      lastDebitedYearMonth: clearLastDebited
          ? null
          : (lastDebitedYearMonth ?? this.lastDebitedYearMonth),
      isActive: isActive ?? this.isActive,
      isIncome: isIncome ?? this.isIncome,
      isTransfer: isTransfer ?? this.isTransfer,
      incomeRegime: incomeRegime ?? this.incomeRegime,
      payFrequency: payFrequency ?? this.payFrequency,
      quincenaDay: quincenaDay ?? this.quincenaDay,
      deductionsAndBonoAtEndOfMonth:
          deductionsAndBonoAtEndOfMonth ?? this.deductionsAndBonoAtEndOfMonth,
      lastQuincenaYearMonth: clearLastQuincena
          ? null
          : (lastQuincenaYearMonth ?? this.lastQuincenaYearMonth),
      hasBonoDeLey: hasBonoDeLey ?? this.hasBonoDeLey,
      bonoDeLeyAmount: bonoDeLeyAmount ?? this.bonoDeLeyAmount,
      calculateIsr: calculateIsr ?? this.calculateIsr,
      isrMode: isrMode ?? this.isrMode,
      customIsrPercent: customIsrPercent ?? this.customIsrPercent,
      deductIgss: deductIgss ?? this.deductIgss,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'accountId': accountId,
      'targetAccountId': targetAccountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategory': subcategory,
      'billingDay': billingDay,
      'autoDebit': autoDebit,
      'lastDebitedYearMonth': lastDebitedYearMonth,
      'isActive': isActive,
      'isIncome': isIncome,
      'isTransfer': isTransfer,
      'incomeRegime': incomeRegime,
      'payFrequency': payFrequency,
      'quincenaDay': quincenaDay,
      'deductionsAndBonoAtEndOfMonth': deductionsAndBonoAtEndOfMonth,
      'lastQuincenaYearMonth': lastQuincenaYearMonth,
      'hasBonoDeLey': hasBonoDeLey,
      'bonoDeLeyAmount': bonoDeLeyAmount,
      'calculateIsr': calculateIsr,
      'isrMode': isrMode,
      'customIsrPercent': customIsrPercent,
      'deductIgss': deductIgss,
    };
  }

  factory RecurringPaymentModel.fromJson(Map<String, dynamic> json) {
    return RecurringPaymentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'GTQ',
      accountId: json['accountId'] as String,
      targetAccountId: json['targetAccountId'] as String?,
      categoryId: (json['categoryId'] as String?) ?? '',
      categoryName: (json['categoryName'] as String?) ?? '',
      subcategory: (json['subcategory'] as String?) ?? '',
      billingDay: json['billingDay'] as int,
      autoDebit: (json['autoDebit'] as bool?) ?? true,
      lastDebitedYearMonth: json['lastDebitedYearMonth'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      isIncome: (json['isIncome'] as bool?) ?? false,
      isTransfer: (json['isTransfer'] as bool?) ?? false,
      incomeRegime: (json['incomeRegime'] as String?) ?? 'planilla',
      payFrequency: (json['payFrequency'] as String?) ?? 'mensual',
      quincenaDay: (json['quincenaDay'] as int?) ?? 15,
      deductionsAndBonoAtEndOfMonth:
          (json['deductionsAndBonoAtEndOfMonth'] as bool?) ?? true,
      lastQuincenaYearMonth: json['lastQuincenaYearMonth'] as String?,
      hasBonoDeLey: (json['hasBonoDeLey'] as bool?) ?? false,
      bonoDeLeyAmount: (json['bonoDeLeyAmount'] as num?)?.toDouble() ?? 250.0,
      calculateIsr: (json['calculateIsr'] as bool?) ?? false,
      isrMode: (json['isrMode'] as String?) ?? 'sat_gt',
      customIsrPercent: (json['customIsrPercent'] as num?)?.toDouble() ?? 5.0,
      deductIgss: (json['deductIgss'] as bool?) ?? false,
    );
  }
}
