enum LoanKind {
  lent, // Presté dinero (Me deben / Por cobrar)
  borrowed, // Me prestaron (Yo debo / Por pagar)
}

class LoanPaymentRecord {
  final String id;
  final double amount;
  final String? accountId;
  final String note;
  final DateTime date;

  const LoanPaymentRecord({
    required this.id,
    required this.amount,
    this.accountId,
    this.note = '',
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'accountId': accountId,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory LoanPaymentRecord.fromJson(Map<String, dynamic> json) {
    return LoanPaymentRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      accountId: json['accountId'] as String?,
      note: (json['note'] as String?) ?? '',
      date:
          DateTime.tryParse((json['date'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

class LoanModel {
  final String id;
  final LoanKind kind;
  final String personName;
  final String personEmoji;
  final String concept;
  final double principalAmount;
  final double interestPercent;
  final String currency; // 'GTQ' or 'USD'
  final String? accountId;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int installmentsCount;
  final double paidAmount;
  final List<LoanPaymentRecord> payments;

  const LoanModel({
    required this.id,
    required this.kind,
    required this.personName,
    this.personEmoji = '👤',
    this.concept = '',
    required this.principalAmount,
    this.interestPercent = 0.0,
    this.currency = 'GTQ',
    this.accountId,
    required this.createdAt,
    this.dueDate,
    this.installmentsCount = 1,
    this.paidAmount = 0.0,
    this.payments = const [],
  });

  double get interestAmount => principalAmount * (interestPercent / 100.0);
  double get totalAmount => principalAmount + interestAmount;
  double get remainingAmount =>
      (totalAmount - paidAmount).clamp(0.0, double.infinity);

  double get progressRatio =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 1.0;

  bool get isSettled => remainingAmount <= 0.01;

  bool get isOverdue {
    if (isSettled || dueDate == null) return false;
    final today = DateTime.now();
    final endOfDueDay = DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      23,
      59,
      59,
    );
    return today.isAfter(endOfDueDay);
  }

  LoanModel copyWith({
    String? id,
    LoanKind? kind,
    String? personName,
    String? personEmoji,
    String? concept,
    double? principalAmount,
    double? interestPercent,
    String? currency,
    String? accountId,
    DateTime? createdAt,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? installmentsCount,
    double? paidAmount,
    List<LoanPaymentRecord>? payments,
  }) {
    return LoanModel(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      personName: personName ?? this.personName,
      personEmoji: personEmoji ?? this.personEmoji,
      concept: concept ?? this.concept,
      principalAmount: principalAmount ?? this.principalAmount,
      interestPercent: interestPercent ?? this.interestPercent,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      installmentsCount: installmentsCount ?? this.installmentsCount,
      paidAmount: paidAmount ?? this.paidAmount,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'personName': personName,
      'personEmoji': personEmoji,
      'concept': concept,
      'principalAmount': principalAmount,
      'interestPercent': interestPercent,
      'currency': currency,
      'accountId': accountId,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'installmentsCount': installmentsCount,
      'paidAmount': paidAmount,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      kind: LoanKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => LoanKind.lent,
      ),
      personName: (json['personName'] as String?) ?? '',
      personEmoji: (json['personEmoji'] as String?) ?? '👤',
      concept: (json['concept'] as String?) ?? '',
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestPercent: (json['interestPercent'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'GTQ',
      accountId: json['accountId'] as String?,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      installmentsCount: (json['installmentsCount'] as int?) ?? 1,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      payments:
          (json['payments'] as List<dynamic>?)
              ?.map(
                (e) => LoanPaymentRecord.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
