import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final Box settingsBox;
  static const String currencyKey = 'currency_symbol';

  SettingsCubit(this.settingsBox) : super(SettingsInitial()) {
    loadSettings();
  }

  void loadSettings() {
    final currency = settingsBox.get(currencyKey, defaultValue: '\$');
    emit(SettingsLoaded(currencySymbol: currency));
  }

  Future<void> updateCurrency(String symbol) async {
    await settingsBox.put(currencyKey, symbol);
    emit(SettingsLoaded(currencySymbol: symbol));
  }
}
