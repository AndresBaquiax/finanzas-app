class AppStrings {
  final String language;
  const AppStrings(this.language);

  bool get isEs => language == 'es';

  String get appTitle => isEs ? 'Finanzas' : 'Finances';
  String get dashboard => isEs ? 'Inicio' : 'Dashboard';
  String get budgets => isEs ? 'Límites' : 'Budgets';
  String get recurring => isEs ? 'Recurrentes' : 'Recurring';
  String get loans => isEs ? 'Préstamos' : 'Loans';
  String get stats => isEs ? 'Estadísticas' : 'Analytics';
  String get settings => isEs ? 'Ajustes' : 'Settings';

  String get defaultAccount => isEs ? 'Cuenta Principal' : 'Default Account';
  String get manageAccounts => isEs ? 'Administrar Cuentas' : 'Manage Accounts';
  String get income => isEs ? 'Ingresos' : 'Income';
  String get expenses => isEs ? 'Gastos' : 'Expenses';
  String get transfer => isEs ? 'Transferir' : 'Transfer';
  String get recentTransactions => isEs ? 'Últimas Transacciones' : 'Recent Transactions';
  String get allAccounts => isEs ? 'Todas las cuentas' : 'All accounts';
  String get allTypes => isEs ? 'Todos' : 'All';
  String get creditAvailable => isEs ? 'Crédito disponible' : 'Available credit';
  String get creditUsed => isEs ? 'Consumido' : 'Used credit';
  String get creditLimit => isEs ? 'Límite de crédito' : 'Credit limit';
  String get cutoffDay => isEs ? 'Día de corte' : 'Cutoff day';
  String get paymentDueDay => isEs ? 'Día de pago' : 'Payment due day';
  String get paidThisCycle => isEs ? 'Pagada este mes' : 'Paid this cycle';
  String get pendingPayment => isEs ? 'Pago pendiente' : 'Payment pending';
  String get annualInterest => isEs ? 'Rendimiento anual' : 'Annual yield';
  String get dualCurrency => isEs ? 'Doble moneda (Q / \$)' : 'Dual currency (Q / \$)';
  String get singleCurrency => isEs ? 'Solo moneda principal' : 'Primary currency only';
  String get newTransaction => isEs ? 'Nuevo Movimiento' : 'New Transaction';
  String get newAccount => isEs ? 'Nueva Cuenta' : 'New Account';
  String get editAccount => isEs ? 'Editar Cuenta' : 'Edit Account';

  String get debitAccount => isEs ? 'Débito / Efectivo' : 'Debit / Cash';
  String get savingsAccount => isEs ? 'Cuenta de Ahorro' : 'Savings Account';
  String get creditCard => isEs ? 'Tarjeta de Crédito' : 'Credit Card';

  String get debited => isEs ? 'Debitado' : 'Debited';
  String get notDebited => isEs ? 'Pendiente de débito' : 'Pending debit';
}
