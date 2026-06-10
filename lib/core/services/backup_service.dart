import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart' as web_helper;

import '../../features/account/data/models/account_model.dart';
import '../../features/category/data/category_data.dart';
import '../../features/transaction/data/transaction_data.dart';
import '../../features/todo/data/todo_data.dart';
import '../../features/workout/data/workout_data.dart';

class BackupService {
  final Box<AccountModel> accountBox;
  final Box<CategoryModel> categoryBox;
  final Box<TransactionModel> transactionBox;
  final Box settingsBox;
  final Box<TodoModel> todoBox;
  final Box<WorkoutModel> workoutBox;
  bool _isRestoring = false;

  BackupService({
    required this.accountBox,
    required this.categoryBox,
    required this.transactionBox,
    required this.settingsBox,
    required this.todoBox,
    required this.workoutBox,
  }) {
    _initAutoBackupListener();
  }

  void _initAutoBackupListener() {
    final boxesToWatch = [accountBox, categoryBox, transactionBox, todoBox, workoutBox];
    for (final box in boxesToWatch) {
      box.watch().listen((event) {
        if (_isRestoring) return;
        final isAutoBackupEnabled = settingsBox.get('auto_backup', defaultValue: false);
        if (isAutoBackupEnabled) {
          backupToFirebase();
        }
      });
    }
  }

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
        'todos': todoBox.values.map((e) => _todoToJson(e)).toList(),
        'workouts': workoutBox.values.map((e) => _workoutToJson(e)).toList(),
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
      final result = await Share.shareXFiles([XFile(file.path)], text: 'HOMO Backup');

      if (result.status == ShareResultStatus.success) {
        // Optional: Update last backup time
      }
    } catch (e) {
      debugPrint('Backup Error: $e');
      if (context.mounted) {
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

      return await _performRestore(data);
    } catch (e, stack) {
      debugPrint('Restore Error: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  // Firebase Realtime Database Backup & Restore Sync Methods
  Future<bool> backupToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Firebase Backup: User is not logged in.');
        return false;
      }
      final userId = user.uid;

      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'accounts': accountBox.values.map((e) => _accountToJson(e)).toList(),
        'categories': categoryBox.values.map((e) => _categoryToJson(e)).toList(),
        'transactions': transactionBox.values.map((e) => _transactionToJson(e)).toList(),
        'todos': todoBox.values.map((e) => _todoToJson(e)).toList(),
        'workouts': workoutBox.values.map((e) => _workoutToJson(e)).toList(),
        'settings': settingsBox.toMap().map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      };

      final jsonString = jsonEncode(data);

      // Realtime Database path: backups/userId/timestamp
      // Firebase database paths cannot contain: '.', '#', '$', '[', or ']'
      final timestampKey = DateTime.now().toIso8601String()
          .replaceAll('.', '_')
          .replaceAll('#', '_')
          .replaceAll('\$', '_')
          .replaceAll('[', '_')
          .replaceAll(']', '_');

      final ref = FirebaseDatabase.instance.ref('backups/$userId/$timestampKey');
      await ref.set(jsonString);

      await settingsBox.put('last_firebase_backup_time', DateTime.now().toIso8601String());

      final bool autoLimit = settingsBox.get('auto_limit_backups', defaultValue: false);
      if (autoLimit) {
        await pruneOldBackups(userId);
      }

      return true;
    } catch (e) {
      debugPrint('Firebase Backup Error: $e');
      return false;
    }
  }

  Future<bool> restoreLatestFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Firebase Restore: User is not logged in.');
        return false;
      }
      final userId = user.uid;

      final ref = FirebaseDatabase.instance.ref('backups/$userId');
      final event = await ref.once();
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('Firebase Restore: No backups found.');
        return false;
      }

      // Read backups Map
      final rawData = snapshot.value;
      if (rawData is! Map) return false;

      final backupsMap = Map<String, dynamic>.from(rawData);
      final sortedKeys = backupsMap.keys.toList()..sort();
      if (sortedKeys.isEmpty) return false;

      final latestKey = sortedKeys.last;
      final latestBackupVal = backupsMap[latestKey];
      final Map<String, dynamic> latestBackup;
      if (latestBackupVal is String) {
        latestBackup = jsonDecode(latestBackupVal) as Map<String, dynamic>;
      } else {
        latestBackup = _deepCastMap(latestBackupVal);
      }

      return await _performRestore(latestBackup);
    } catch (e, stack) {
      debugPrint('Firebase Restore Error: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }

  Future<String?> getLatestBackupTimestamp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final userId = user.uid;

      final ref = FirebaseDatabase.instance.ref('backups/$userId');
      final event = await ref.once();
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;

      final rawData = snapshot.value;
      if (rawData is! Map) return null;

      final backupsMap = Map<String, dynamic>.from(rawData);
      final sortedKeys = backupsMap.keys.toList()..sort();
      if (sortedKeys.isEmpty) return null;

      final latestKey = sortedKeys.last;
      final latestBackupVal = backupsMap[latestKey];
      Map<String, dynamic> latestBackup = {};
      if (latestBackupVal is String) {
        try {
          latestBackup = jsonDecode(latestBackupVal) as Map<String, dynamic>;
        } catch (_) {}
      } else {
        latestBackup = _deepCastMap(latestBackupVal);
      }

      if (latestBackup.containsKey('timestamp')) {
        return latestBackup['timestamp'] as String?;
      }
      return latestKey.replaceAll('_', '.');
    } catch (e) {
      debugPrint('Firebase Get Latest Timestamp Error: $e');
      return null;
    }
  }

  Map<String, dynamic> _deepCastMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), _deepCastValue(value)));
    }
    try {
      final map = Map.from(data as Map);
      return map.map((key, value) => MapEntry(key.toString(), _deepCastValue(value)));
    } catch (_) {}
    return {};
  }

  dynamic _deepCastValue(dynamic val) {
    if (val is Map) {
      return _deepCastMap(val);
    } else if (val is List) {
      return val.map((e) => _deepCastValue(e)).toList();
    }
    try {
      final map = Map.from(val as Map);
      return _deepCastMap(map);
    } catch (_) {}
    try {
      final list = List.from(val as Iterable);
      return list.map((e) => _deepCastValue(e)).toList();
    } catch (_) {}
    return val;
  }

  List _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) return value.values.toList();
    try {
      final list = List.from(value as Iterable);
      return list;
    } catch (_) {}
    try {
      final map = Map.from(value as Map);
      return map.values.toList();
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> getAllCloudBackups() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final userId = user.uid;

      final ref = FirebaseDatabase.instance.ref('backups/$userId');
      final event = await ref.once();
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;

      final rawData = snapshot.value;
      if (rawData is Map) {
        return Map<String, dynamic>.from(rawData);
      }
      try {
        final map = Map.from(rawData as Map);
        return Map<String, dynamic>.from(map);
      } catch (_) {}
      return null;
    } catch (e) {
      debugPrint('Error getting all cloud backups: $e');
      return null;
    }
  }

  Map<String, dynamic>? parseBackupData(dynamic rawBackupVal) {
    debugPrint('parseBackupData: type of rawBackupVal is: ${rawBackupVal.runtimeType}');
    if (rawBackupVal == null) {
      debugPrint('parseBackupData: rawBackupVal is null');
      return null;
    }
    if (rawBackupVal is String) {
      try {
        final decoded = jsonDecode(rawBackupVal) as Map<String, dynamic>;
        debugPrint('parseBackupData: Decoded JSON string successfully. Keys: ${decoded.keys.toList()}');
        return decoded;
      } catch (e) {
        debugPrint('parseBackupData: Failed to decode JSON backup string: $e');
        return null;
      }
    }
    try {
      final casted = _deepCastMap(rawBackupVal);
      debugPrint('parseBackupData: Casted map successfully. Keys: ${casted.keys.toList()}');
      if (casted.isNotEmpty) {
        return casted;
      }
    } catch (e) {
      debugPrint('parseBackupData: Error during deep casting map: $e');
    }
    debugPrint('parseBackupData: Returning null (invalid/empty backup)');
    return null;
  }

  Future<bool> restoreSpecificBackup(dynamic backupVal) async {
    try {
      final parsed = parseBackupData(backupVal);
      if (parsed == null) return false;
      return await _performRestore(parsed);
    } catch (e) {
      debugPrint('Error restoring specific backup: $e');
      return false;
    }
  }

  Future<void> pruneOldBackups(String userId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('backups/$userId');
      final event = await ref.once();
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return;

      final rawData = snapshot.value;
      if (rawData is! Map) return;

      final backupsMap = Map<String, dynamic>.from(rawData);
      final sortedKeys = backupsMap.keys.toList()..sort();
      if (sortedKeys.length <= 10) return;

      final keysToDelete = sortedKeys.sublist(0, sortedKeys.length - 10);
      for (final key in keysToDelete) {
        await ref.child(key).remove();
      }
      debugPrint('Pruned ${keysToDelete.length} old backups.');
    } catch (e) {
      debugPrint('Error pruning backups: $e');
    }
  }

  Future<bool> deleteCloudBackup(String userId, String backupKey) async {
    try {
      final ref = FirebaseDatabase.instance.ref('backups/$userId/$backupKey');
      await ref.remove();
      debugPrint('Successfully deleted backup with key: $backupKey');
      return true;
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      return false;
    }
  }

  Future<void> clearAllLocalData() async {
    _isRestoring = true;
    try {
      await accountBox.clear();
      await categoryBox.clear();
      await transactionBox.clear();
      await todoBox.clear();
      await workoutBox.clear();
      await settingsBox.delete('last_firebase_backup_time');
      await settingsBox.delete('last_backup');
      await settingsBox.put('auto_backup', false);
      await settingsBox.delete('security_enabled');
      await settingsBox.delete('security_pin');
    } finally {
      _isRestoring = false;
    }
  }

  Future<bool> _performRestore(Map<String, dynamic> data) async {
    // Validate
    final hasVersion = data.containsKey('version');
    final hasTimestamp = data.containsKey('timestamp');
    final hasCoreData = data.containsKey('accounts') ||
        data.containsKey('categories') ||
        data.containsKey('transactions') ||
        data.containsKey('settings') ||
        data.containsKey('todos') ||
        data.containsKey('workouts');

    if (!hasVersion && !hasTimestamp && !hasCoreData) {
      throw Exception('Invalid backup format');
    }

    _isRestoring = true;
    try {
      // Clear Existing Data
      await accountBox.clear();
      await categoryBox.clear();
      await transactionBox.clear();
      await todoBox.clear();
      await workoutBox.clear();

      // Restore Accounts
      final List rawAccounts = _extractList(data['accounts']);
      for (var item in rawAccounts) {
        if (item is Map) {
          final casted = Map<String, dynamic>.from(item);
          final model = _jsonToAccount(casted);
          await accountBox.put(model.id, model);
        }
      }

      // Restore Categories
      final List rawCategories = _extractList(data['categories']);
      for (var item in rawCategories) {
        if (item is Map) {
          final casted = Map<String, dynamic>.from(item);
          final model = _jsonToCategory(casted);
          await categoryBox.put(model.id, model);
        }
      }

      // Restore Transactions
      final List rawTransactions = _extractList(data['transactions']);
      for (var item in rawTransactions) {
        if (item is Map) {
          final casted = Map<String, dynamic>.from(item);
          final model = _jsonToTransaction(casted);
          await transactionBox.put(model.id, model);
        }
      }

      // Restore To-Dos
      if (data.containsKey('todos')) {
        final List rawTodos = _extractList(data['todos']);
        for (var item in rawTodos) {
          if (item is Map) {
            final casted = Map<String, dynamic>.from(item);
            final model = _jsonToTodo(casted);
            await todoBox.put(model.id, model);
          }
        }
      }

      // Restore Workouts
      if (data.containsKey('workouts')) {
        final List rawWorkouts = _extractList(data['workouts']);
        for (var item in rawWorkouts) {
          if (item is Map) {
            final casted = Map<String, dynamic>.from(item);
            final model = _jsonToWorkout(casted);
            await workoutBox.put(model.id, model);
          }
        }
      }

      // Restore Settings
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;
        for (var entry in settings.entries) {
          await settingsBox.put(entry.key, entry.value);
        }
      }

      return true;
    } finally {
      _isRestoring = false;
    }
  }

  // Helpers
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
              id: s['id'] ?? '',
              name: s['name'] ?? '',
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

  Map<String, dynamic> _todoToJson(TodoModel t) {
    return {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'isCompleted': t.isCompleted,
      'dueDate': t.dueDate?.toIso8601String(),
      'priority': t.priority,
      'isDeleted': t.isDeleted,
    };
  }

  TodoModel _jsonToTodo(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> _workoutToJson(WorkoutModel w) {
    return {
      'id': w.id,
      'title': w.title,
      'date': w.date.toIso8601String(),
      'durationMinutes': w.durationMinutes,
      'exercises': w.exercises,
      'notes': w.notes,
      'isDeleted': w.isDeleted,
    };
  }

  WorkoutModel _jsonToWorkout(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
      exercises: List<String>.from(json['exercises'] ?? []),
      notes: json['notes'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}
