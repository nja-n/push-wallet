import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:push_wallet/features/category/data/category_data.dart';
import 'package:push_wallet/features/transaction/data/transaction_data.dart';
import 'package:push_wallet/features/account/data/models/account_model.dart';

// Key constants
const String kWidgetAmountKey = 'widget_amount';
const String kWidgetCategoryKey = 'widget_category';

@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  if (uri == null) return;

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Handle Keypad Input
  if (uri.scheme == 'quickadd') {
    if (uri.host == 'num') {
      final value = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      await _handleNumInput(value, prefs);
    } else if (uri.host == 'clear') {
      await _handleClear(prefs);
    } else if (uri.host == 'save') {
      await _handleSave(prefs);
    }
  }
}

Future<void> _handleNumInput(String num, SharedPreferences prefs) async {
  String current = prefs.getString(kWidgetAmountKey) ?? '0';

  if (num == '.') {
    if (!current.contains('.')) {
      current = '$current.';
    }
  } else {
    if (current == '0') {
      current = num;
    } else {
      current = '$current$num';
    }
  }

  await prefs.setString(kWidgetAmountKey, current);
  await HomeWidget.saveWidgetData(kWidgetAmountKey, current);
  await HomeWidget.updateWidget(
    name: 'QuickAddWidget',
    androidName: 'QuickAddWidget',
  );
}

Future<void> _handleClear(SharedPreferences prefs) async {
  await prefs.setString(kWidgetAmountKey, '0');
  await HomeWidget.saveWidgetData(kWidgetAmountKey, '0');
  await HomeWidget.updateWidget(
    name: 'QuickAddWidget',
    androidName: 'QuickAddWidget',
  );
}

Future<void> _handleSave(SharedPreferences prefs) async {
  final amountStr = prefs.getString(kWidgetAmountKey) ?? '0';
  final amount = double.tryParse(amountStr) ?? 0.0;

  if (amount <= 0) return;

  // Initialize Hive for background write
  await Hive.initFlutter();

  // Open necessary boxes
  // Note: We are doing direct data layer operations here since we don't have full app context
  final accountBox = await Hive.openBox<AccountModel>('accounts');
  final categoryBox = await Hive.openBox<CategoryModel>('categories');
  final transactionBox = await Hive.openBox<TransactionModel>('transactions');

  // Default to first account and 'Food' or first category if not selected
  // For V1, we just take the first available ones or defaults
  String accountId = '';
  if (accountBox.isNotEmpty) {
    accountId = accountBox.values.first.id;
  }

  String categoryId = '';
  if (categoryBox.isNotEmpty) {
    categoryId = categoryBox.values.first.id;
  }

  // Create Transaction
  final newTx = TransactionModel(
    id: const Uuid().v4(),
    amount: amount,
    date: DateTime.now(),
    description: 'Quick Widget Entry',
    typeIndex: 1, // Expense
    accountId: accountId,
    categoryId: categoryId,
    subCategoryId: null,
    toAccountId: null,
  );

  await transactionBox.put(newTx.id, newTx);

  // Update Account Balance
  if (accountId.isNotEmpty) {
    final account = accountBox.get(accountId);
    if (account != null) {
      final updatedAccount = AccountModel(
        id: account.id,
        name: account.name,
        type: account.type,
        balance: account.balance - amount,
        color: account.color,
        icon: account.icon,
        creditLimit: account.creditLimit,
      );
      await accountBox.put(accountId, updatedAccount);
    }
  }

  // Clear Widget State
  await _handleClear(prefs);
}
