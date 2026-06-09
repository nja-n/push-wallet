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
  final bool isSecurityEnabled;
  final bool autoLimitBackups;

  const SettingsLoaded({
    required this.currencySymbol,
    this.autoBackup = false,
    this.lastBackup,
    this.isSecurityEnabled = false,
    this.autoLimitBackups = false,
  });

  SettingsLoaded copyWith({
    String? currencySymbol,
    bool? autoBackup,
    String? lastBackup,
    bool? isSecurityEnabled,
    bool? autoLimitBackups,
  }) {
    return SettingsLoaded(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      autoBackup: autoBackup ?? this.autoBackup,
      lastBackup: lastBackup ?? this.lastBackup,
      isSecurityEnabled: isSecurityEnabled ?? this.isSecurityEnabled,
      autoLimitBackups: autoLimitBackups ?? this.autoLimitBackups,
    );
  }

  @override
  List<Object?> get props => [
    currencySymbol,
    autoBackup,
    lastBackup,
    isSecurityEnabled,
    autoLimitBackups,
  ];
}
