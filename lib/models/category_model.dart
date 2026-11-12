enum CategoryKind {
  expense,
  income,
}

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final CategoryKind kind;
  final List<String> subcategories;
  final int colorValue;
  final bool isCustom;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.kind,
    required this.subcategories,
    required this.colorValue,
    this.isCustom = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? emoji,
    CategoryKind? kind,
    List<String>? subcategories,
    int? colorValue,
    bool? isCustom,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      kind: kind ?? this.kind,
      subcategories: subcategories ?? this.subcategories,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'kind': kind.name,
      'subcategories': subcategories,
      'colorValue': colorValue,
      'isCustom': isCustom,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      kind: CategoryKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => CategoryKind.expense,
      ),
      subcategories: (json['subcategories'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      colorValue: (json['colorValue'] as int?) ?? 0xFF2563EB,
      isCustom: (json['isCustom'] as bool?) ?? false,
    );
  }

  static List<CategoryModel> defaultCategories() {
    return const [
      // Expense categories
      CategoryModel(
        id: 'cat_alimentacion',
        name: 'Alimentación',
        emoji: '🍔',
        kind: CategoryKind.expense,
        colorValue: 0xFFEA580C,
        subcategories: [
          'Supermercado',
          'Restaurantes',
          'Comida rápida',
          'Café',
          'Comida a domicilio',
          'Panadería',
          'Snacks',
        ],
      ),
      CategoryModel(
        id: 'cat_transporte',
        name: 'Transporte',
        emoji: '🚗',
        kind: CategoryKind.expense,
        colorValue: 0xFF2563EB,
        subcategories: [
          'Gasolina',
          'Uber',
          'Estacionamiento',
          'Reparaciones',
          'Lavado',
        ],
      ),
      CategoryModel(
        id: 'cat_servicios',
        name: 'Servicios',
        emoji: '💡',
        kind: CategoryKind.expense,
        colorValue: 0xFF0891B2,
        subcategories: [
          'Electricidad',
          'Agua',
          'Gas',
          'Internet',
          'Teléfono',
          'Streaming',
        ],
      ),
      CategoryModel(
        id: 'cat_entretenimiento',
        name: 'Entretenimiento',
        emoji: '🎮',
        kind: CategoryKind.expense,
        colorValue: 0xFF7C3AED,
        subcategories: [
          'Cine',
          'Spotify',
          'Videojuegos',
          'Eventos',
          'Atracciones',
          'Suscripciones',
        ],
      ),
      CategoryModel(
        id: 'cat_salud',
        name: 'Salud',
        emoji: '🏥',
        kind: CategoryKind.expense,
        colorValue: 0xFFDC2626,
        subcategories: [
          'Medicamentos',
          'Farmacia',
          'Consulta médica',
          'Oftalmólogo',
          'Dentista',
          'Emergencia médica',
          'Gimnasio',
        ],
      ),
      CategoryModel(
        id: 'cat_compras',
        name: 'Compras',
        emoji: '🛍️',
        kind: CategoryKind.expense,
        colorValue: 0xFFDB2777,
        subcategories: [
          'Ropa',
          'Zapatos',
          'Electrónicos',
          'Accesorios',
          'Muebles',
          'Decoración',
          'Regalos',
          'Joyas',
        ],
      ),
      CategoryModel(
        id: 'cat_educacion',
        name: 'Educación',
        emoji: '🎓',
        kind: CategoryKind.expense,
        colorValue: 0xFF4F46E5,
        subcategories: [
          'Matrícula',
          'Colegiaturas',
          'Libros',
          'Cursos',
          'Tutorías',
          'Certificaciones',
        ],
      ),
      CategoryModel(
        id: 'cat_mascotas',
        name: 'Mascotas',
        emoji: '🐾',
        kind: CategoryKind.expense,
        colorValue: 0xFFD97706,
        subcategories: [
          'Alimento',
          'Veterinario',
          'Vacunas',
          'Juguetes',
          'Grooming',
          'Medicamentos',
          'Accesorios',
          'Guardería',
        ],
      ),
      // Income categories
      CategoryModel(
        id: 'cat_salario',
        name: 'Salario',
        emoji: '💼',
        kind: CategoryKind.income,
        colorValue: 0xFF16A34A,
        subcategories: [
          'Nómina',
          'Salario base',
          'Horas extra',
          'Aguinaldo',
          'Bono 14',
          'Finiquito',
        ],
      ),
      CategoryModel(
        id: 'cat_regalos',
        name: 'Regalos',
        emoji: '🎁',
        kind: CategoryKind.income,
        colorValue: 0xFF059669,
        subcategories: [
          'Cumpleaños',
          'Premios',
          'Lotería',
          'Recompensa',
          'Donaciones',
        ],
      ),
    ];
  }
}
