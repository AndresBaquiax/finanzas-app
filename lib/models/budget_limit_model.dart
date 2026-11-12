class BudgetLimitModel {
  final String id;
  final String name;
  final double monthlyLimit;
  final String? categoryId;
  final String? subcategory;
  final int colorValue;
  final String emoji;

  const BudgetLimitModel({
    required this.id,
    required this.name,
    required this.monthlyLimit,
    this.categoryId,
    this.subcategory,
    required this.colorValue,
    required this.emoji,
  });

  BudgetLimitModel copyWith({
    String? id,
    String? name,
    double? monthlyLimit,
    String? categoryId,
    String? subcategory,
    int? colorValue,
    String? emoji,
  }) {
    return BudgetLimitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyLimit': monthlyLimit,
      'categoryId': categoryId,
      'subcategory': subcategory,
      'colorValue': colorValue,
      'emoji': emoji,
    };
  }

  factory BudgetLimitModel.fromJson(Map<String, dynamic> json) {
    return BudgetLimitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      categoryId: json['categoryId'] as String?,
      subcategory: json['subcategory'] as String?,
      colorValue: (json['colorValue'] as int?) ?? 0xFF2563EB,
      emoji: (json['emoji'] as String?) ?? '🎯',
    );
  }
}
