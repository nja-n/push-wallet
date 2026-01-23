part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String currencySymbol;
  const SettingsLoaded({required this.currencySymbol});
  @override
  List<Object> get props => [currencySymbol];
}
