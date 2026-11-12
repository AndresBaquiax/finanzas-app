enum TransactionType {
  expense,
  income,
  transfer,
}

class TransactionModel {
  final String id;
  final String accountId;
  final String? targetAccountId;
  final TransactionType type;
  final double amount; // Converted amount in primary currency (e.g., GTQ)
  final double originalAmount; // Amount entered in originalCurrency
  final String originalCurrency; // 'GTQ' or 'USD'
  final double exchangeRateUsed;
  final String categoryId;
  final String categoryName;
  final String subcategory;
  final String note;
  final DateTime date;
  final int installmentsTotal;
  final int installmentCurrent;
  final String? parentInstallmentId;
  final bool isRecurringGenerated;
  final double cashbackEarned;
  final double cashbackPercentUsed;

  const TransactionModel({
    required this.id,
    required this.accountId,
    this.targetAccountId,
    required this.type,
    required this.amount,
    required this.originalAmount,
    this.originalCurrency = 'GTQ',
    this.exchangeRateUsed = 1.0,
    required this.categoryId,
    required this.categoryName,
    required this.subcategory,
    this.note = '',
    required this.date,
    this.installmentsTotal = 1,
    this.installmentCurrent = 1,
    this.parentInstallmentId,
    this.isRecurringGenerated = false,
    this.cashbackEarned = 0.0,
    this.cashbackPercentUsed = 0.0,
  });

  bool get isInstallment => installmentsTotal > 1;
  bool get hasCashback => cashbackEarned > 0;
  double get netAmountAfterCashback =>
      (amount - cashbackEarned).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'targetAccountId': targetAccountId,
      'type': type.name,
      'amount': amount,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'exchangeRateUsed': exchangeRateUsed,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategory': subcategory,
      'note': note,
      'date': date.toIso8601String(),
      'installmentsTotal': installmentsTotal,
      'installmentCurrent': installmentCurrent,
      'parentInstallmentId': parentInstallmentId,
      'isRecurringGenerated': isRecurringGenerated,
      'cashbackEarned': cashbackEarned,
      'cashbackPercentUsed': cashbackPercentUsed,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      targetAccountId: json['targetAccountId'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (json['amount'] as num).toDouble(),
      originalAmount:
          (json['originalAmount'] as num?)?.toDouble() ??
          (json['amount'] as num).toDouble(),
      originalCurrency: (json['originalCurrency'] as String?) ?? 'GTQ',
      exchangeRateUsed:
          (json['exchangeRateUsed'] as num?)?.toDouble() ?? 1.0,
      categoryId: (json['categoryId'] as String?) ?? '',
      categoryName: (json['categoryName'] as String?) ?? '',
      subcategory: (json['subcategory'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      installmentsTotal: (json['installmentsTotal'] as int?) ?? 1,
      installmentCurrent: (json['installmentCurrent'] as int?) ?? 1,
      parentInstallmentId: json['parentInstallmentId'] as String?,
      isRecurringGenerated: (json['isRecurringGenerated'] as bool?) ?? false,
      cashbackEarned: (json['cashbackEarned'] as num?)?.toDouble() ?? 0.0,
      cashbackPercentUsed:
          (json['cashbackPercentUsed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
