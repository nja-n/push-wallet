import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart' as web_helper;

import '../../features/account/data/models/account_model.dart';
import '../../features/category/data/category_data.dart';
import '../../features/transaction/data/transaction_data.dart';

class BackupService {
  final Box<AccountModel> accountBox;
  final Box<CategoryModel> categoryBox;
  final Box<TransactionModel> transactionBox;
  final Box settingsBox;

  BackupService({
    required this.accountBox,
    required this.categoryBox,
    required this.transactionBox,
    required this.settingsBox,
  });

  Future<void> createBackup(BuildContext context) async {
    try {
      // 1. Serialize Data
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'accounts': accountBox.values.map((e) => _accountToJson(e)).toList(),
        'categories': categoryBox.values
            .map((e) => _categoryToJson(e))
            .toList(),
        'transactions': transactionBox.values
            .map((e) => _transactionToJson(e))
            .toList(),
        'settings': settingsBox.toMap().map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      };

      final jsonString = jsonEncode(data);
      final fileName =
          'push_wallet_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';

      if (kIsWeb) {
        // 2. Web specific download
        web_helper.downloadFile(jsonString, fileName);
        return;
      }

      // 2. Write to File (Mobile/Desktop)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // 3. Share File
      final result = await Share.shareXFiles([XFile(file.path)], text: 'Push Wallet Backup');

      if (result.status == ShareResultStatus.success) {
        // Optional: Update last backup time
      }
    } catch (e) {
      debugPrint('Backup Error: $e');
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup Failed: $e')));
      }
    }
  }

  Future<bool> restoreBackup() async {
    try {
      // 1. Pick File
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final Map<String, dynamic> data;
      if (kIsWeb) {
        final bytes = result.files.single.bytes!;
        final jsonString = utf8.decode(bytes);
        data = jsonDecode(jsonString);
      } else {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        data = jsonDecode(jsonString);
      }

      // 2. Validate
      if (!data.containsKey('accounts') ||
          !data.containsKey('categories') ||
          !data.containsKey('transactions')) {
        throw Exception('Invalid backup format');
      }

      // 3. Clear Existing Data
      await accountBox.clear();
      await categoryBox.clear();
      await transactionBox.clear();
      // Only clear specific settings if needed, or all
      // await settingsBox.clear(); // Maybe preserve some settings? User wants full restore.

      // 4. Restore Accounts
      for (var item in data['accounts']) {
        final model = _jsonToAccount(item);
        await accountBox.put(model.id, model);
      }

      // 5. Restore Categories
      for (var item in data['categories']) {
        final model = _jsonToCategory(item);
        await categoryBox.put(model.id, model);
      }

      // 6. Restore Transactions
      for (var item in data['transactions']) {
        final model = _jsonToTransaction(item);
        await transactionBox.put(model.id, model);
      }

      // 7. Restore Settings
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;
        for (var entry in settings.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      return true;
    } catch (e, stack) {
      debugPrint('Restore Error: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  // Helpers (Manual Mapping to avoid modifying Models with toJson/fromJson for now)
  // Or I could check if models have conversion logic.
  // Models are HiveObjects.

  Map<String, dynamic> _accountToJson(AccountModel a) {
    return {
      'id': a.id,
      'name': a.name,
      'type': a.type,
      'balance': a.balance,
      'color': a.color,
      'icon': a.icon,
      'creditLimit': a.creditLimit,
    };
  }

  AccountModel _jsonToAccount(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      color: json['color'],
      icon: json['icon'],
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> _categoryToJson(CategoryModel c) {
    return {
      'id': c.id,
      'name': c.name,
      'color': c.color,
      'icon': c.icon,
      'isIncome': c.isIncome,
      'isDeleted': c.isDeleted,
      'subCategories': c.subCategories
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              // 'color': s.color,
              // 'icon': s.icon,
            },
          )
          .toList(),
    };
  }

  CategoryModel _jsonToCategory(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
      isIncome: json['isIncome'],
      isDeleted: json['isDeleted'] ?? false,
      subCategories: (json['subCategories'] as List)
          .map(
            (s) => SubCategoryModel(
              id: s['id'],
              name: s['name'],
              // color: s['color'],
              // icon: s['icon'],
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> _transactionToJson(TransactionModel t) {
    return {
      'id': t.id,
      'amount': t.amount,
      'date': t.date.toIso8601String(),
      'description': t.description,
      'categoryId': t.categoryId,
      'accountId': t.accountId,
      'toAccountId': t.toAccountId,
      'typeIndex': t.typeIndex,
      'subCategoryId': t.subCategoryId,
    };
  }

  TransactionModel _jsonToTransaction(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      categoryId: json['categoryId'],
      accountId: json['accountId'],
      toAccountId: json['toAccountId'],
      typeIndex: json['typeIndex'],
      subCategoryId: json['subCategoryId'],
    );
  }
}
