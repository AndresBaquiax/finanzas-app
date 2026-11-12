import 'package:flutter/material.dart';
import '../models/detected_payment_model.dart';
import '../services/finance_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PaymentDetectorPage extends StatefulWidget {
  final FinanceStore store;
  const PaymentDetectorPage({super.key, required this.store});

  static Future<void> show(BuildContext context, FinanceStore store) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentDetectorPage(store: store),
      ),
    );
  }

  @override
  State<PaymentDetectorPage> createState() => _PaymentDetectorPageState();
}

class _PaymentDetectorPageState extends State<PaymentDetectorPage>
    with WidgetsBindingObserver {
  final _customTestCtrl = TextEditingController();
  bool _showCustomTester = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.refreshDetectorPermissionsAndQueue();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customTestCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.refreshDetectorPermissionsAndQueue();
    }
  }

  Future<void> _handleToggleWallet(BuildContext context) async {
    final store = widget.store;
    final settings = store.settings;
    final hasNotifPerm = store.hasNotificationListenerAccess;
    final isCurrentlyActive = settings.walletDetectorEnabled && hasNotifPerm;

    if (isCurrentlyActive) {
      await store.updateSettings(
        settings.copyWith(walletDetectorEnabled: false),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detector de Google Wallet y notificaciones pausado.'),
        ),
      );
      return;
    }

    await store.updateSettings(settings.copyWith(walletDetectorEnabled: true));
    if (!hasNotifPerm) {
      final opened = await store.openNotificationListenerSettings();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Activa "Finanzas" en la lista de Acceso a notificaciones de Android.'
                : 'Detector activado en la app.',
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detector de Google Wallet y notificaciones activado.'),
        ),
      );
    }
  }

  Future<void> _handleToggleSms(BuildContext context) async {
    final store = widget.store;
    final settings = store.settings;
    final hasSmsPerm = store.hasSmsPermission;
    final isCurrentlyActive = settings.smsDetectorEnabled && hasSmsPerm;

    if (isCurrentlyActive) {
      await store.updateSettings(settings.copyWith(smsDetectorEnabled: false));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lectura automática de SMS bancarios desactivada.'),
        ),
      );
      return;
    }

    await store.updateSettings(settings.copyWith(smsDetectorEnabled: true));
    if (!hasSmsPerm) {
      final granted = await store.requestSmsPermission();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Permiso de SMS concedido y detector activo.'
                : 'Habilita el permiso de SMS en la configuración de la aplicación.',
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lectura automática de SMS bancarios activada.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final settings = store.settings;
        final notifPerm = store.hasNotificationListenerAccess;
        final smsPerm = store.hasSmsPermission;
        final walletActive = settings.walletDetectorEnabled && notifPerm;
        final smsActive = settings.smsDetectorEnabled && smsPerm;
        final autoApply = settings.autoRegisterDetectedPayments;
        final detectedList = store.detectedPayments;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Google Wallet y Bancos'),
            actions: [
              IconButton(
                tooltip: 'Permisos de la app en Android',
                onPressed: store.openAppDetailsSettings,
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Actualizar estado',
                onPressed: store.refreshDetectorPermissionsAndQueue,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 36),
            children: [
              const Text(
                'Configuración de detección en Android',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Google Wallet & Notifications Row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: walletActive
                                  ? context.palette.incomeSoftBg
                                  : context.palette.warningSoftBg,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.contactless_rounded,
                              color: walletActive
                                  ? context.palette.income
                                  : context.palette.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Google Wallet y Notificaciones',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  walletActive
                                      ? 'Activo • Detectando pagos de Wallet y bancos'
                                      : !notifPerm
                                      ? 'Requiere permiso de acceso a notificaciones'
                                      : 'Pausado por el usuario',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: walletActive
                                        ? context.palette.income
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              backgroundColor: walletActive
                                  ? context.palette.incomeSoftBg
                                  : context.palette.accentFill,
                              foregroundColor: walletActive
                                  ? context.palette.income
                                  : Colors.white,
                            ),
                            onPressed: () => _handleToggleWallet(context),
                            child: Text(
                              walletActive ? 'Activo (Desactivar)' : 'Activar',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // SMS Reader Row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: smsActive
                                  ? context.palette.incomeSoftBg
                                  : context.palette.accent.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.sms_outlined,
                              color: smsActive
                                  ? context.palette.income
                                  : context.palette.accent,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lectura directa de SMS bancarios',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  smsActive
                                      ? 'Activo • Detectando SMS de consumos'
                                      : !smsPerm
                                      ? 'Toca Permitir para autorizar lectura de SMS'
                                      : 'Pausado por el usuario',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: smsActive
                                        ? context.palette.income
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              backgroundColor: smsActive
                                  ? context.palette.incomeSoftBg
                                  : context.palette.accentFill,
                              foregroundColor: smsActive
                                  ? context.palette.income
                                  : Colors.white,
                            ),
                            onPressed: () => _handleToggleSms(context),
                            child: Text(
                              smsActive ? 'Activo (Desactivar)' : 'Permitir',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'Debitar automáticamente al detectar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Descuenta de la cuenta asociada (aplica conversión Dúo y Cashback automáticamente)',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: autoApply,
                        onChanged: (v) {
                          store.updateSettings(
                            settings.copyWith(autoRegisterDetectedPayments: v),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 7),
                          ),
                          onPressed: store.openAppDetailsSettings,
                          icon: const Icon(
                            Icons.settings_applications_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Abrir permisos de la app en Android / MIUI',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.palette.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      size: 18,
                      color: context.palette.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: En "Administrar Cuentas" puedes poner los últimos 4 dígitos de cada tarjeta (ej. 4521) para que al pagar con Google Wallet o recibir un SMS, se asigne automáticamente a esa tarjeta.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Probar detector ahora',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () =>
                        setState(() => _showCustomTester = !_showCustomTester),
                    child: Text(
                      _showCustomTester ? 'Ocultar texto' : 'Pegar SMS',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => _simulateWalletPayment(context),
                              icon: const Icon(
                                Icons.contactless_outlined,
                                size: 15,
                              ),
                              label: const Text(
                                'Simular Google Wallet',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => _simulateBankSms(context),
                              icon: const Icon(Icons.sms_outlined, size: 15),
                              label: const Text(
                                'Simular SMS Banco',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showCustomTester) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customTestCtrl,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12.5),
                          decoration: const InputDecoration(
                            labelText:
                                'Pega aquí un SMS del banco o texto de Google Wallet',
                            hintText:
                                'Ej: Consumo por Q150.00 en Gasolinera Shell con tarjeta *4521',
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: context.palette.accentFill,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _processCustomText(context),
                            child: const Text(
                              'Procesar mensaje',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Pagos detectados (${detectedList.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 6),
              if (detectedList.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Center(
                      child: Text(
                        'Aún no se han detectado pagos de Google Wallet o SMS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                )
              else
                for (final det in detectedList)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RepaintBoundary(
                      child: _buildDetectedCard(context, det),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetectedCard(BuildContext context, DetectedPaymentModel det) {
    final store = widget.store;
    final acc = store.getAccountById(det.matchedAccountId);
    final isWallet = det.source == 'google_wallet';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: det.isApplied
                        ? context.palette.incomeSoftBg
                        : context.palette.warningSoftBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isWallet ? Icons.contactless_rounded : Icons.sms_outlined,
                    size: 18,
                    color: det.isApplied
                        ? context.palette.income
                        : context.palette.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        det.merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${det.sourceLabel} • ${det.categoryName} (${det.subcategory})${acc != null ? ' • ${acc.name}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        det.amount,
                        currency: det.currency,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: context.palette.expense,
                      ),
                    ),
                    Text(
                      det.isApplied ? '✓ Aplicado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: det.isApplied
                            ? context.palette.income
                            : context.palette.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              det.rawBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (!det.isApplied) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: context.palette.expense,
                    ),
                    onPressed: () => store.dismissDetectedPayment(det.id),
                    child: const Text(
                      'Descartar',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.incomeSolid,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () => store.approveDetectedPayment(det.id),
                    child: const Text(
                      'Confirmar y descontar',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _simulateWalletPayment(BuildContext context) async {
    final acc = widget.store.defaultAccount;
    final last4 = (acc != null && acc.cardLast4Digits.isNotEmpty)
        ? acc.cardLast4Digits
        : '4521';
    final res = await widget.store.processRawPaymentMessage(
      source: 'google_wallet',
      title: 'McDonald\'s',
      body: 'Q85.00 con Visa •••• $last4 en McDonald\'s',
    );
    if (!context.mounted) return;
    _showResultSnack(context, res);
  }

  Future<void> _simulateBankSms(BuildContext context) async {
    final acc = widget.store.defaultAccount;
    final last4 = (acc != null && acc.cardLast4Digits.isNotEmpty)
        ? acc.cardLast4Digits
        : '4521';
    final res = await widget.store.processRawPaymentMessage(
      source: 'bank_sms',
      title: 'Banco',
      body:
          'Se realizo un consumo por Q.200.00 en GASOLINERA SHELL con su tarjeta *$last4',
    );
    if (!context.mounted) return;
    _showResultSnack(context, res);
  }

  Future<void> _processCustomText(BuildContext context) async {
    final text = _customTestCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final res = await widget.store.processRawPaymentMessage(
      source: 'bank_sms',
      title: 'Mensaje Bancario',
      body: text,
    );
    _customTestCtrl.clear();
    if (!context.mounted) return;
    _showResultSnack(context, res);
  }

  void _showResultSnack(BuildContext context, DetectedPaymentModel? res) {
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró un monto válido en el mensaje.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.isApplied
              ? 'Pago detectado y descontado: ${CurrencyFormatter.format(res.amount, currency: res.currency)} en ${res.merchant} (${res.categoryName})'
              : 'Pago detectado pendiente de confirmar: ${CurrencyFormatter.format(res.amount, currency: res.currency)} en ${res.merchant}',
        ),
      ),
    );
  }
}
