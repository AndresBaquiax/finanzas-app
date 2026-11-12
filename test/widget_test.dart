import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finanzas_app/main.dart';
import 'package:finanzas_app/models/account_model.dart';
import 'package:finanzas_app/models/loan_model.dart';
import 'package:finanzas_app/models/transaction_model.dart';
import 'package:finanzas_app/services/finance_store.dart';

void main() {
  testWidgets(
    'All screens and forms render without overflow on 360px mobile width',
    (WidgetTester tester) async {
      // Exact 360px logical width like Huawei LIO L29
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final store = FinanceStore();
      await store.init();

      await tester.pumpWidget(FinanzasApp(store: store));
      await tester.pumpAndSettle();

      // Open New Account screen from empty state
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      // Switch to Ahorro
      await tester.tap(find.text('Ahorro'));
      await tester.pumpAndSettle();

      // Switch to Crédito (this previously caused RenderFlex overflow at 328px!)
      await tester.tap(find.text('Crédito'));
      await tester.pumpAndSettle();

      // Close New Account screen
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      // Create accounts & data programmatically and verify all tabs at 360px width
      await store.saveAccount(
        name: 'Tarjeta Visa Dúo',
        description: 'Uso general',
        type: AccountType.credit,
        initialBalance: 0,
        colorValue: 0xFF1E293B,
        emoji: '💳',
        isDefault: true,
        creditLimit: 10000,
        cutoffDay: 20,
        isPaidThisCycle: false,
        isDualCurrency: true,
        hasCashback: true,
        defaultCashbackPercent: 1.0,
        cardLast4Digits: '4521',
        cashbackRules: const [
          CashbackRule(
            id: 'cb_1',
            categoryId: 'cat_alimentacion',
            categoryName: 'Alimentación',
            subcategory: null,
            percentage: 5.0,
          ),
          CashbackRule(
            id: 'cb_2',
            categoryId: 'cat_transporte',
            categoryName: 'Transporte',
            subcategory: 'Gasolina',
            percentage: 3.0,
          ),
        ],
      );
      await store.saveAccount(
        name: 'Tarjeta Gasolina 7%',
        description: 'Cashback gasolina',
        type: AccountType.credit,
        initialBalance: 0,
        colorValue: 0xFF1D4ED8,
        emoji: '⛽',
        isDefault: false,
        creditLimit: 8000,
        cutoffDay: 15,
        isPaidThisCycle: false,
        isDualCurrency: false,
        hasCashback: true,
        defaultCashbackPercent: 1.0,
        cardLast4Digits: '8899',
        cashbackRules: const [
          CashbackRule(
            id: 'cb_3',
            categoryId: 'cat_transporte',
            categoryName: 'Transporte',
            subcategory: 'Gasolina',
            percentage: 7.0,
          ),
        ],
      );
      await store.saveAccount(
        name: 'Ahorro Personal',
        description: 'Fondo',
        type: AccountType.savings,
        initialBalance: 5000,
        colorValue: 0xFF0F766E,
        emoji: '🐷',
        isDefault: false,
        annualInterestRate: 5.0,
      );

      // Spend Q200 on Alimentación -> Restaurantes with Card 1 (5% cashback = Q10, net Q190)
      await store.addTransaction(
        accountId: store.accounts[0].id,
        type: TransactionType.expense,
        originalAmount: 200.0,
        originalCurrency: 'GTQ',
        categoryId: 'cat_alimentacion',
        categoryName: 'Alimentación',
        subcategory: 'Restaurantes',
        note: 'Cena',
        date: DateTime.now(),
        installmentsTotal: 1,
      );
      expect(store.accounts[0].currentBalance, closeTo(190.0, 0.01));
      expect(store.accounts[0].accumulatedCashback, closeTo(10.0, 0.01));

      // Spend Q300 on Gasolina with Card 2 (7% cashback = Q21, net Q279)
      await store.addTransaction(
        accountId: store.accounts[1].id,
        type: TransactionType.expense,
        originalAmount: 300.0,
        originalCurrency: 'GTQ',
        categoryId: 'cat_transporte',
        categoryName: 'Transporte',
        subcategory: 'Gasolina',
        note: 'Tanque lleno',
        date: DateTime.now(),
        installmentsTotal: 1,
      );
      expect(store.accounts[1].currentBalance, closeTo(279.0, 0.01));
      expect(store.accounts[1].accumulatedCashback, closeTo(21.0, 0.01));

      // Test automatic Google Wallet detection on card 4521 (Q100 at McDonald's -> 5% cashback = Q5, net +Q95)
      final walletDet = await store.processRawPaymentMessage(
        source: 'google_wallet',
        title: 'McDonald\'s',
        body: 'Q100.00 con Visa •••• 4521 en McDonald\'s',
      );
      expect(walletDet, isNotNull);
      expect(walletDet!.isApplied, isTrue);
      expect(walletDet.categoryId, 'cat_alimentacion');
      expect(store.accounts[0].currentBalance, closeTo(285.0, 0.01));
      expect(store.accounts[0].accumulatedCashback, closeTo(15.0, 0.01));

      // Test automatic Bank SMS detection on card 8899 (Q100 at Gasolinera Shell -> 7% cashback = Q7, net +Q93)
      final smsDet = await store.processRawPaymentMessage(
        source: 'bank_sms',
        title: 'BI',
        body:
            'BI: Se realizo un consumo por Q.100.00 en GASOLINERA SHELL con tarjeta *8899',
      );
      expect(smsDet, isNotNull);
      expect(smsDet!.isApplied, isTrue);
      expect(smsDet.subcategory, 'Gasolina');
      expect(store.accounts[1].currentBalance, closeTo(372.0, 0.01));
      expect(store.accounts[1].accumulatedCashback, closeTo(28.0, 0.01));
      await store.saveBudgetLimit(
        name: 'Salidas del mes',
        monthlyLimit: 1000,
        categoryId: 'cat_alimentacion',
        subcategory: 'Restaurantes',
        colorValue: 0xFF1D4ED8,
        emoji: '🍽️',
      );
      await store.saveRecurringPayment(
        name: 'Internet Residencial',
        amount: 350,
        currency: 'GTQ',
        accountId: store.accounts.first.id,
        categoryId: 'cat_servicios',
        categoryName: 'Servicios',
        subcategory: 'Internet',
        billingDay: 15,
        autoDebit: true,
      );

      // Save a recurring Salary income with Quincena & End of Month:
      // Base Q8,000 -> Quincena (50% = Q4,000), Fin de Mes (50% Q4,000 + Bono Q250 - ISR Q212.50 = Q4,037.50)
      await store.saveRecurringPayment(
        name: 'Salario Planilla',
        amount: 8000,
        currency: 'GTQ',
        accountId: store.accounts[2].id,
        categoryId: 'cat_salario',
        categoryName: 'Salario',
        subcategory: 'Salario base',
        quincenaDay: 1,
        billingDay: 1,
        autoDebit: true,
        isIncome: true,
        incomeRegime: 'planilla',
        payFrequency: 'quincenal_fin_mes',
        deductionsAndBonoAtEndOfMonth: true,
        hasBonoDeLey: true,
        bonoDeLeyAmount: 250.0,
        calculateIsr: true,
        isrMode: 'sat_gt',
      );
      expect(
        store.recurringPayments.last.quincenaNetAmount,
        closeTo(4000.0, 0.01),
      );
      expect(
        store.recurringPayments.last.endOfMonthNetAmount,
        closeTo(4037.50, 0.01),
      );
      // Both Quincena (Q4,000) and End of Month (Q4,037.50) credited to Savings Account (Q5,000 + Q8,037.50 = Q13,037.50)
      expect(store.accounts[2].currentBalance, closeTo(13037.50, 0.01));

      // Test automatic recurring transfer: Q37.50 from Savings Account to pay down Card 1
      await store.saveRecurringPayment(
        name: 'Abono programado tarjeta',
        amount: 37.50,
        currency: 'GTQ',
        accountId: store.accounts[2].id,
        targetAccountId: store.accounts[0].id,
        categoryId: 'cat_transfer',
        categoryName: 'Transferencia',
        subcategory: 'Automática',
        billingDay: 1,
        autoDebit: true,
        isTransfer: true,
      );
      expect(store.accounts[2].currentBalance, closeTo(13000.0, 0.01));

      // Test Loans: Lend Q500 to Carlos from Savings Account, then receive Q200 payment
      await store.saveLoan(
        kind: LoanKind.lent,
        personName: 'Carlos',
        personEmoji: '👨',
        concept: 'Emergencia',
        principalAmount: 500.0,
        interestPercent: 0.0,
        currency: 'GTQ',
        accountId: store.accounts[2].id,
        installmentsCount: 2,
        affectAccountBalance: true,
      );
      expect(store.accounts[2].currentBalance, closeTo(12500.0, 0.01));
      expect(store.loans.first.remainingAmount, closeTo(500.0, 0.01));

      await store.registerLoanPayment(
        loanId: store.loans.first.id,
        amount: 200.0,
        accountId: store.accounts[2].id,
        note: 'Primer abono',
      );
      expect(store.accounts[2].currentBalance, closeTo(12700.0, 0.01));
      expect(store.loans.first.remainingAmount, closeTo(300.0, 0.01));
      await tester.pumpAndSettle();

      // Filter by credit card on Dashboard
      await tester.tap(find.text('💳 Tarjeta Visa Dúo'));
      await tester.pumpAndSettle();

      // Navigate to Budgets tab
      await tester.tap(find.text('Límites'));
      await tester.pumpAndSettle();

      // Navigate to Recurring tab and test opening the Salary/Recurring/Transfer form
      await tester.tap(find.text('Recurrentes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingreso / Salario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      // Navigate to Loans tab and test opening the Loan form
      await tester.tap(find.text('Préstamos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      // Open Settings from the top-left header icon
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();

      // Open Categories Management page
      await tester.tap(find.text('Administrar categorías'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Open Google Wallet & Bank SMS Detector page
      await tester.tap(find.text('Google Wallet y SMS Bancarios'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Close Settings page
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Navigate back to Inicio and open Manage Accounts and Add Transaction
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
    },
  );
}
