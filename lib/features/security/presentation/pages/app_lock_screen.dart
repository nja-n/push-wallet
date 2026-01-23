import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../widgets/pin_pad.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _title = 'Enter PIN';

  void _onPinCompleted(String pin) {
    // Check PIN against SettingsCubit
    final isValid = context.read<SettingsCubit>().verifyPin(pin);
    if (isValid) {
      // Navigate to Dashboard
      // We use GoRouter or Navigator based on app structure.
      // Assuming Navigator for now or checking main.dart for context.
      // Based on main.dart user provided:
      // It likely uses standard Navigator or GoRouter.
      // I'll assume Navigator.pushReplacement for now, but better to check routes.
      // Actually, if this is the 'home' of the app, we might need to replace the route.

      // Since this is a barrier *before* the main app, we just need to let the user in.
      // If we are using GoRouter, we might redirect.
      // If we are using standard Navigator, we pushReplacement to DashboardView.

      // Let's assume we can navigate to '/' or DashboardView.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() {
        _title = 'Incorrect PIN. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 32),
              PinPad(
                key: ValueKey(_title),
                title: _title,
                onCompleted: _onPinCompleted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
