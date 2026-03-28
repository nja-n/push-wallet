import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../../security/presentation/pages/app_lock_screen.dart';
import '../pages/home_page.dart';

class VaultWrapper extends StatefulWidget {
  const VaultWrapper({super.key});

  @override
  State<VaultWrapper> createState() => _VaultWrapperState();
}

class _VaultWrapperState extends State<VaultWrapper> {
  // We handle the "unlocked" state locally for the current session
  bool _isUnlocked = false;

  void _onAuthenticated() {
    setState(() {
      _isUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoaded) {
          final isEnabled = state.isSecurityEnabled;
          
          if (isEnabled && !_isUnlocked) {
            // Use AppLockScreen but with a way to handle completion.
            // Since AppLockScreen in the project currently does Navigator.pushReplacement
            // we might need to modify it or handle it.
            // For now, we wrap it.
            return AppLockScreen(onSuccess: _onAuthenticated);
          }
          
          // Show the main app
          return ShowCaseWidget(
            builder: (context) => const HomePage(),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
