class DetectedPaymentModel {
  final String id;
  final String source; // 'google_wallet', 'bank_sms', 'bank_notification'
  final String rawTitle;
  final String rawBody;
  final double amount;
  final String currency; // 'GTQ' or 'USD'
  final String merchant;
  final String? cardLast4;
  final String? matchedAccountId;
  final String categoryId;
  final String categoryName;
  final String subcategory;
  final DateTime detectedAt;
  final bool isApplied;

  const DetectedPaymentModel({
    required this.id,
    required this.source,
    required this.rawTitle,
    required this.rawBody,
    required this.amount,
    required this.currency,
    required this.merchant,
    this.cardLast4,
    this.matchedAccountId,
    required this.categoryId,
    required this.categoryName,
    required this.subcategory,
    required this.detectedAt,
    this.isApplied = false,
  });

  String get sourceLabel {
    switch (source) {
      case 'google_wallet':
        return 'Google Wallet';
      case 'bank_sms':
        return 'SMS del Banco';
      default:
        return 'Notificación Bancaria';
    }
  }

  DetectedPaymentModel copyWith({
    String? id,
    String? source,
    String? rawTitle,
    String? rawBody,
    double? amount,
    String? currency,
    String? merchant,
    String? cardLast4,
    String? matchedAccountId,
    String? categoryId,
    String? categoryName,
    String? subcategory,
    DateTime? detectedAt,
    bool? isApplied,
  }) {
    return DetectedPaymentModel(
      id: id ?? this.id,
      source: source ?? this.source,
      rawTitle: rawTitle ?? this.rawTitle,
      rawBody: rawBody ?? this.rawBody,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      cardLast4: cardLast4 ?? this.cardLast4,
      matchedAccountId: matchedAccountId ?? this.matchedAccountId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      detectedAt: detectedAt ?? this.detectedAt,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'rawTitle': rawTitle,
      'rawBody': rawBody,
      'amount': amount,
      'currency': currency,
      'merchant': merchant,
      'cardLast4': cardLast4,
      'matchedAccountId': matchedAccountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategory': subcategory,
      'detectedAt': detectedAt.toIso8601String(),
      'isApplied': isApplied,
    };
  }

  factory DetectedPaymentModel.fromJson(Map<String, dynamic> json) {
    return DetectedPaymentModel(
      id: json['id'] as String,
      source: (json['source'] as String?) ?? 'bank_notification',
      rawTitle: (json['rawTitle'] as String?) ?? '',
      rawBody: (json['rawBody'] as String?) ?? '',
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'GTQ',
      merchant: (json['merchant'] as String?) ?? 'Comercio',
      cardLast4: json['cardLast4'] as String?,
      matchedAccountId: json['matchedAccountId'] as String?,
      categoryId: (json['categoryId'] as String?) ?? 'cat_compras',
      categoryName: (json['categoryName'] as String?) ?? 'Compras',
      subcategory: (json['subcategory'] as String?) ?? 'Accesorios',
      detectedAt:
          DateTime.tryParse((json['detectedAt'] as String?) ?? '') ??
          DateTime.now(),
      isApplied: (json['isApplied'] as bool?) ?? false,
    );
  }
}
