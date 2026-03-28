import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../widgets/pin_pad.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AppLockScreen({super.key, this.onSuccess});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _title = 'Enter PIN';

  void _onPinCompleted(String pin) {
    // Check PIN against SettingsCubit
    final isValid = context.read<SettingsCubit>().verifyPin(pin);
    if (isValid) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        // Fallback for root auth if needed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
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
