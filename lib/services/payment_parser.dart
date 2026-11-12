import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/detected_payment_model.dart';

class PaymentParser {
  static final RegExp _amountWithSymbolRegex = RegExp(
    r'(?:(GTQ|USD|US\$|Q\.?|\$)\s*)(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _fallbackAmountRegex = RegExp(
    r'(?:por|monto|de|total)\s*:?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+\.\d{2})',
    caseSensitive: false,
  );

  static final RegExp _cardLast4Regex = RegExp(
    r'(?:[•*xX#]{1,4}\s*|\bterminada\s+en\s+[•*xX#\s]*|\btarjeta\s+(?:no\.?\s*)?[•*xX#\s]*|\bt\.?c\.?\s*[•*xX#\s]*)(\d{4})\b',
    caseSensitive: false,
  );

  static final RegExp _merchantInBodyRegex = RegExp(
    r'\ben\s+([A-Za-z0-9ÁÉÍÓÚÑáéíóúñ&\-\.\s]{2,32}?)(?=\s+(?:con\b|el\b|por\b|tarjeta\b|t\.c\.|aut|ref|fecha|hora|\d{2}[\/\-]\d{2})|[,\.;]|$)',
    caseSensitive: false,
  );

  static DetectedPaymentModel? parse({
    required String id,
    required String source,
    required String packageName,
    required String title,
    required String body,
    required DateTime timestamp,
    required List<AccountModel> accounts,
    required List<CategoryModel> expenseCategories,
    required String defaultCurrency,
  }) {
    final fullText = '$title $body'.trim();
    if (fullText.isEmpty) return null;

    // 1. Extract Currency & Amount
    String currency = defaultCurrency;
    double? amount;

    final match = _amountWithSymbolRegex.firstMatch(fullText);
    if (match != null) {
      final rawSymbol = (match.group(1) ?? '').toUpperCase();
      final rawNumber = (match.group(2) ?? '').replaceAll(',', '');
      amount = double.tryParse(rawNumber);
      if (rawSymbol.contains('USD') || rawSymbol.contains('\$')) {
        currency = 'USD';
      } else if (rawSymbol.contains('Q') || rawSymbol.contains('GTQ')) {
        currency = 'GTQ';
      }
    } else {
      final fallback = _fallbackAmountRegex.firstMatch(fullText);
      if (fallback != null) {
        final rawNumber = (fallback.group(1) ?? '').replaceAll(',', '');
        amount = double.tryParse(rawNumber);
      }
    }

    if (amount == null || amount <= 0) return null;

    // 2. Extract Card Last 4 Digits
    String? cardLast4;
    final cardMatch = _cardLast4Regex.firstMatch(fullText);
    if (cardMatch != null) {
      cardLast4 = cardMatch.group(1);
    }

    // 3. Extract Merchant / Commerce Name
    String merchant = _extractMerchant(
      source: source,
      title: title,
      body: body,
    );

    // 4. Match Account (by last 4 digits, by account name in text, or default account)
    AccountModel? matchedAccount = _matchAccount(
      accounts: accounts,
      cardLast4: cardLast4,
      fullText: fullText,
      isWallet: source == 'google_wallet',
    );

    // 5. Infer Category & Subcategory from Merchant + Text
    final (catId, catName, subcat) = _inferCategoryAndSubcategory(
      text: '$merchant $fullText',
      expenseCategories: expenseCategories,
    );

    return DetectedPaymentModel(
      id: id,
      source: source,
      rawTitle: title,
      rawBody: body,
      amount: amount,
      currency: currency,
      merchant: merchant,
      cardLast4: cardLast4,
      matchedAccountId: matchedAccount?.id,
      categoryId: catId,
      categoryName: catName,
      subcategory: subcat,
      detectedAt: timestamp,
    );
  }

  static String _extractMerchant({
    required String source,
    required String title,
    required String body,
  }) {
    final cleanTitle = title.trim();
    if (source == 'google_wallet' &&
        cleanTitle.isNotEmpty &&
        !cleanTitle.toLowerCase().contains('google wallet') &&
        !cleanTitle.toLowerCase().contains('billetera') &&
        !cleanTitle.toLowerCase().contains('g pay') &&
        !cleanTitle.toLowerCase().contains('pago realizado')) {
      return cleanTitle;
    }

    final bodyMatch = _merchantInBodyRegex.firstMatch(body);
    if (bodyMatch != null) {
      final extracted = bodyMatch.group(1)?.trim() ?? '';
      if (extracted.length >= 2) {
        return extracted;
      }
    }

    if (cleanTitle.isNotEmpty) return cleanTitle;
    return source == 'google_wallet' ? 'Pago Google Wallet' : 'Consumo Bancario';
  }

  static AccountModel? _matchAccount({
    required List<AccountModel> accounts,
    required String? cardLast4,
    required String fullText,
    required bool isWallet,
  }) {
    if (accounts.isEmpty) return null;

    // 1. Exact match by last 4 digits
    if (cardLast4 != null && cardLast4.isNotEmpty) {
      for (final acc in accounts) {
        if (acc.cardLast4Digits.trim() == cardLast4) {
          return acc;
        }
      }
    }

    // 2. Match by account name words
    final lowerText = fullText.toLowerCase();
    for (final acc in accounts) {
      final accNameLower = acc.name.trim().toLowerCase();
      if (accNameLower.length >= 3 && lowerText.contains(accNameLower)) {
        return acc;
      }
    }

    // 3. For Google Wallet, prefer default credit card or first credit card if available
    if (isWallet) {
      for (final acc in accounts) {
        if (acc.isDefault && acc.type == AccountType.credit) return acc;
      }
      for (final acc in accounts) {
        if (acc.type == AccountType.credit) return acc;
      }
    }

    // 4. Fallback to default account
    for (final acc in accounts) {
      if (acc.isDefault) return acc;
    }
    return accounts.first;
  }

  static (String, String, String) _inferCategoryAndSubcategory({
    required String text,
    required List<CategoryModel> expenseCategories,
  }) {
    final lower = text.toLowerCase();

    (String, String, String)? resolve(String catId, String preferredSub) {
      for (final c in expenseCategories) {
        if (c.id == catId) {
          final sub = c.subcategories.firstWhere(
            (s) => s.toLowerCase() == preferredSub.toLowerCase(),
            orElse: () =>
                c.subcategories.isNotEmpty ? c.subcategories.first : preferredSub,
          );
          return (c.id, c.name, sub);
        }
      }
      return null;
    }

    // Gasolina
    if (_containsAny(lower, const [
      'shell',
      'texaco',
      'puma',
      'gasolinera',
      'gasolina',
      'combustible',
      'uno ',
      'don arturo',
      'pacific oil',
    ])) {
      final r = resolve('cat_transporte', 'Gasolina');
      if (r != null) return r;
    }

    // Uber / Transporte
    if (_containsAny(lower, const ['uber', 'didi', 'indrive', 'taxi'])) {
      if (lower.contains('uber eats') || lower.contains('pedidosya')) {
        final r = resolve('cat_alimentacion', 'Comida a domicilio');
        if (r != null) return r;
      }
      final r = resolve('cat_transporte', 'Uber');
      if (r != null) return r;
    }
    if (_containsAny(lower, const ['parqueo', 'estacionamiento'])) {
      final r = resolve('cat_transporte', 'Estacionamiento');
      if (r != null) return r;
    }

    // Alimentación
    if (_containsAny(lower, const [
      'supermercado',
      'la torre',
      'paiz',
      'walmart',
      'pricesmart',
      'maxi despensa',
      'despensa familiar',
    ])) {
      final r = resolve('cat_alimentacion', 'Supermercado');
      if (r != null) return r;
    }
    if (_containsAny(lower, const [
      'pedidosya',
      'uber eats',
      'domicilio',
      'glovo',
    ])) {
      final r = resolve('cat_alimentacion', 'Comida a domicilio');
      if (r != null) return r;
    }
    if (_containsAny(lower, const [
      'starbucks',
      'barista',
      'cafe',
      'café',
      ' & cafe',
      '& café',
    ])) {
      final r = resolve('cat_alimentacion', 'Café');
      if (r != null) return r;
    }
    if (_containsAny(lower, const [
      'mcdonald',
      'burger king',
      'wendy',
      'kfc',
      'campero',
      'pizza',
      'taco bell',
      'subway',
      'little caesars',
      'comida rapida',
    ])) {
      final r = resolve('cat_alimentacion', 'Comida rápida');
      if (r != null) return r;
    }
    if (_containsAny(lower, const [
      'panaderia',
      'panadería',
      'san martin',
      'san martín',
      'patsy',
    ])) {
      final r = resolve('cat_alimentacion', 'Panadería');
      if (r != null) return r;
    }
    if (_containsAny(lower, const [
      'restaurante',
      'cebollines',
      'tre fratelli',
      'comedor',
      'comida',
      'almuerzo',
      'cena',
    ])) {
      final r = resolve('cat_alimentacion', 'Restaurantes');
      if (r != null) return r;
    }

    // Servicios & Entretenimiento
    if (_containsAny(lower, const ['spotify'])) {
      final r = resolve('cat_entretenimiento', 'Spotify');
      if (r != null) return r;
    }
    if (_containsAny(lower, const ['cine', 'cinemark', 'cinepolis'])) {
      final r = resolve('cat_entretenimiento', 'Cine');
      if (r != null) return r;
    }
    if (_containsAny(lower, const [
      'netflix',
      'disney',
      'hbo',
      'max.com',
      'prime video',
      'youtube',
      'apple.com/bill',
      'google *',
    ])) {
      final r = resolve('cat_servicios', 'Streaming');
      if (r != null) return r;
    }
    if (_containsAny(lower, const ['claro', 'tigo'])) {
      final r = resolve('cat_servicios', 'Teléfono');
      if (r != null) return r;
    }
    if (_containsAny(lower, const ['eegsa', 'energuate', 'electricidad'])) {
      final r = resolve('cat_servicios', 'Electricidad');
      if (r != null) return r;
    }

    // Salud
    if (_containsAny(lower, const [
      'farmacia',
      'galeno',
      'cruz verde',
      'meyko',
      'batres',
    ])) {
      final r = resolve('cat_salud', 'Farmacia');
      if (r != null) return r;
    }
    if (_containsAny(lower, const ['gimnasio', 'smart fit', 'impulso', 'gym'])) {
      final r = resolve('cat_salud', 'Gimnasio');
      if (r != null) return r;
    }

    // Fallback
    if (expenseCategories.isNotEmpty) {
      final fallbackCat = expenseCategories.firstWhere(
        (c) => c.id == 'cat_compras',
        orElse: () => expenseCategories.first,
      );
      final fallbackSub = fallbackCat.subcategories.isNotEmpty
          ? fallbackCat.subcategories.first
          : 'General';
      return (fallbackCat.id, fallbackCat.name, fallbackSub);
    }

    return ('cat_compras', 'Compras', 'General');
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}
