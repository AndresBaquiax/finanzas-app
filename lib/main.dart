import 'package:flutter/material.dart';
import 'screens/budgets_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/recurring_payments_screen.dart';
import 'services/finance_store.dart';
import 'theme/app_theme.dart';
import 'utils/app_strings.dart';
import 'widgets/add_transaction_modal.dart';
import 'widgets/app_animations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FinanceStore();
  await store.init();
  runApp(FinanzasApp(store: store));
}

class FinanzasApp extends StatelessWidget {
  final FinanceStore store;
  const FinanzasApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final isDark = store.settings.isDarkMode;
        return MaterialApp(
          title: 'Finanzas',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          themeAnimationStyle: AnimationStyle.noAnimation,
          home: store.settings.isSessionLocked
              ? LockScreen(key: const ValueKey('lock'), store: store)
              : MainNavigationShell(
                  key: const ValueKey('main'),
                  store: store,
                ),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final FinanceStore store;
  const MainNavigationShell({super.key, required this.store});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.refreshDetectorPermissionsAndQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final strings = AppStrings(store.settings.language);

    final pages = [
      DashboardScreen(store: store),
      BudgetsScreen(store: store),
      RecurringPaymentsScreen(store: store),
      LoansScreen(store: store),
    ];

    return Scaffold(
      body: FadeThroughIndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: context.palette.accentFill,
              foregroundColor: Colors.white,
              elevation: 2,
              onPressed: () => AddTransactionModal.show(context, store),
              child: const Icon(Icons.add_rounded, size: 24),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerTheme.color ??
                  const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          animationDuration: const Duration(milliseconds: 180),
          onDestinationSelected: (idx) {
            if (idx != _selectedIndex) setState(() => _selectedIndex = idx);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: strings.dashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: const Icon(Icons.pie_chart_rounded),
              label: strings.budgets,
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_repeat_outlined),
              selectedIcon: const Icon(Icons.event_repeat_rounded),
              label: strings.recurring,
            ),
            NavigationDestination(
              icon: const Icon(Icons.handshake_outlined),
              selectedIcon: const Icon(Icons.handshake_rounded),
              label: strings.loans,
            ),
          ],
        ),
      ),
    );
  }
}
