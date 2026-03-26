import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:push_wallet/features/account/presentation/pages/accounts_view.dart';
import 'package:push_wallet/features/category/presentation/pages/categories_view.dart';
import 'package:push_wallet/features/transaction/presentation/pages/transactions_view.dart';
import 'package:push_wallet/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'dashboard_view.dart'; // Same folder
import 'package:home_widget/home_widget.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const AccountsView(),
    const TransactionsView(),
    const CategoriesView(),
  ];

  final GlobalKey _addTransactionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Check for widget interaction
    _checkForWidgetLaunch();

    // Trigger tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  void _showTutorial() async {
    final settingsBox = await Hive.openBox('settings');
    bool shown = settingsBox.get('tutorial_home', defaultValue: false);

    if (!shown && mounted) {
      ShowCaseWidget.of(context).startShowCase([_addTransactionKey]);
      settingsBox.put('tutorial_home', true);
    }
  }

  void _checkForWidgetLaunch() {
    if (kIsWeb) return;

    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null && uri.toString() == 'pushwallet://quick_add') {
        _showAddTransaction();
      }
    });

    // Also listen for widget clicks while app is in background
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null && uri.toString() == 'pushwallet://quick_add') {
        _showAddTransaction();
      }
    });
  }

  void _showAddTransaction() {
    // Delay slightly to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => const AddTransactionSheet(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => const AddTransactionSheet(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
