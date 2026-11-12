class UserSettingsModel {
  final String userName;
  final String userEmail;
  final String? pinCode;
  final bool isSessionLocked;
  final String primaryCurrency; // 'GTQ', 'USD', 'EUR', 'MXN'
  final String language; // 'es', 'en'
  final bool isDarkMode;
  final double usdToGtqRate;
  final bool autoRegisterDetectedPayments;
  final bool walletDetectorEnabled;
  final bool smsDetectorEnabled;

  const UserSettingsModel({
    this.userName = 'Usuario Principal',
    this.userEmail = 'usuario@finanzas.local',
    this.pinCode,
    this.isSessionLocked = false,
    this.primaryCurrency = 'GTQ',
    this.language = 'es',
    this.isDarkMode = false,
    this.usdToGtqRate = 7.75,
    this.autoRegisterDetectedPayments = true,
    this.walletDetectorEnabled = true,
    this.smsDetectorEnabled = true,
  });

  UserSettingsModel copyWith({
    String? userName,
    String? userEmail,
    String? pinCode,
    bool clearPin = false,
    bool? isSessionLocked,
    String? primaryCurrency,
    String? language,
    bool? isDarkMode,
    double? usdToGtqRate,
    bool? autoRegisterDetectedPayments,
    bool? walletDetectorEnabled,
    bool? smsDetectorEnabled,
  }) {
    return UserSettingsModel(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      pinCode: clearPin ? null : (pinCode ?? this.pinCode),
      isSessionLocked: isSessionLocked ?? this.isSessionLocked,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      usdToGtqRate: usdToGtqRate ?? this.usdToGtqRate,
      autoRegisterDetectedPayments:
          autoRegisterDetectedPayments ?? this.autoRegisterDetectedPayments,
      walletDetectorEnabled:
          walletDetectorEnabled ?? this.walletDetectorEnabled,
      smsDetectorEnabled: smsDetectorEnabled ?? this.smsDetectorEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'pinCode': pinCode,
      'isSessionLocked': isSessionLocked,
      'primaryCurrency': primaryCurrency,
      'language': language,
      'isDarkMode': isDarkMode,
      'usdToGtqRate': usdToGtqRate,
      'autoRegisterDetectedPayments': autoRegisterDetectedPayments,
      'walletDetectorEnabled': walletDetectorEnabled,
      'smsDetectorEnabled': smsDetectorEnabled,
    };
  }

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userName: (json['userName'] as String?) ?? 'Usuario Principal',
      userEmail: (json['userEmail'] as String?) ?? 'usuario@finanzas.local',
      pinCode: json['pinCode'] as String?,
      isSessionLocked: (json['isSessionLocked'] as bool?) ?? false,
      primaryCurrency: (json['primaryCurrency'] as String?) ?? 'GTQ',
      language: (json['language'] as String?) ?? 'es',
      isDarkMode: (json['isDarkMode'] as bool?) ?? false,
      usdToGtqRate: (json['usdToGtqRate'] as num?)?.toDouble() ?? 7.75,
      autoRegisterDetectedPayments:
          (json['autoRegisterDetectedPayments'] as bool?) ?? true,
      walletDetectorEnabled:
          (json['walletDetectorEnabled'] as bool?) ?? true,
      smsDetectorEnabled: (json['smsDetectorEnabled'] as bool?) ?? true,
    );
  }
}
