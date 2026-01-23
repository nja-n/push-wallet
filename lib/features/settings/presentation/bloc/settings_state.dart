part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String currencySymbol;
  final bool autoBackup;
  final String? lastBackup;

  const SettingsLoaded({
    required this.currencySymbol,
    this.autoBackup = false,
    this.lastBackup,
  });

  SettingsLoaded copyWith({
    String? currencySymbol,
    bool? autoBackup,
    String? lastBackup,
  }) {
    return SettingsLoaded(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      autoBackup: autoBackup ?? this.autoBackup,
      lastBackup: lastBackup ?? this.lastBackup,
    );
  }

  @override
  List<Object?> get props => [currencySymbol, autoBackup, lastBackup];
}
