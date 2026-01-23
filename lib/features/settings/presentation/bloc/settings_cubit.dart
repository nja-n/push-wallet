import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter/widgets.dart';
import '../../../../core/services/backup_service.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final Box settingsBox;
  final BackupService backupService;

  static const String currencyKey = 'currency_symbol';
  static const String autoBackupKey = 'auto_backup';
  static const String lastBackupKey = 'last_backup';

  SettingsCubit({required this.settingsBox, required this.backupService})
    : super(SettingsInitial()) {
    loadSettings();
  }

  void loadSettings() {
    final currency = settingsBox.get(currencyKey, defaultValue: '\$');
    final autoBackup = settingsBox.get(autoBackupKey, defaultValue: false);
    final lastBackup = settingsBox.get(lastBackupKey);

    emit(
      SettingsLoaded(
        currencySymbol: currency,
        autoBackup: autoBackup,
        lastBackup: lastBackup,
      ),
    );
  }

  Future<void> updateCurrency(String symbol) async {
    await settingsBox.put(currencyKey, symbol);
    if (state is SettingsLoaded) {
      emit((state as SettingsLoaded).copyWith(currencySymbol: symbol));
    }
  }

  Future<void> toggleAutoBackup(bool value) async {
    await settingsBox.put(autoBackupKey, value);
    if (state is SettingsLoaded) {
      emit((state as SettingsLoaded).copyWith(autoBackup: value));
    }
  }

  Future<void> createBackup(BuildContext context) async {
    await backupService.createBackup(context);
    final now = DateTime.now().toIso8601String();
    await settingsBox.put(lastBackupKey, now);
    if (state is SettingsLoaded) {
      emit((state as SettingsLoaded).copyWith(lastBackup: now));
    }
  }

  Future<bool> restoreBackup() async {
    final success = await backupService.restoreBackup();
    if (success) {
      // Reload settings as they might have been overwritten
      loadSettings();
    }
    return success;
  }
}
