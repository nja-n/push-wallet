import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/pin_pad.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  // Shows a modal sheet for PIN entry.
  // If isSetup is true, it handles the "Create -> Confirm" flow.
  // If isSetup is false, it just checks against the stored PIN.
  void _showPinSheet({
    required BuildContext context,
    required bool isSetup,
    Function(String)? onSetupComplete,
    Function()? onCheckSuccess,
    String? titleOverride,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return _PinSheetContent(
          isSetup: isSetup,
          onSetupComplete: onSetupComplete,
          onCheckSuccess: onCheckSuccess,
          titleOverride: titleOverride,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            final isEnabled = state.isSecurityEnabled;

            return ListView(
              children: [
                SwitchListTile(
                  title: const Text('App Lock'),
                  subtitle: const Text('Require PIN on startup'),
                  value: isEnabled,
                  onChanged: (value) {
                    if (value) {
                      // Turning ON: Setup new PIN
                      _showPinSheet(
                        context: context,
                        isSetup: true,
                        titleOverride: 'Create PIN',
                        onSetupComplete: (pin) {
                          context.read<SettingsCubit>().setSecurityPin(pin);
                          context.read<SettingsCubit>().toggleSecurity(true);
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Close sheet
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Security Enabled')),
                          );
                        },
                      );
                    } else {
                      // Turning OFF: Verify current PIN first
                      _showPinSheet(
                        context: context,
                        isSetup: false,
                        titleOverride: 'Enter PIN to Disable',
                        onCheckSuccess: () {
                          context.read<SettingsCubit>().toggleSecurity(false);
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Close sheet
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Security Disabled')),
                          );
                        },
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Change PIN'),
                  enabled: isEnabled,
                  onTap: isEnabled
                      ? () {
                          // Verify old PIN first
                          _showPinSheet(
                            context: context,
                            isSetup: false,
                            titleOverride: 'Enter Current PIN',
                            onCheckSuccess: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context); // Close check sheet
                              }
                              // Open setup sheet
                              // Wait a frame to ensure sheet is closed before opening new one
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  if (context.mounted) {
                                    _showPinSheet(
                                      context: context,
                                      isSetup: true,
                                      titleOverride: 'Enter New PIN',
                                      onSetupComplete: (newPin) {
                                        context
                                            .read<SettingsCubit>()
                                            .setSecurityPin(newPin);
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(
                                            context,
                                          ); // Close setup sheet
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('PIN Changed'),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                      : null,
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _PinSheetContent extends StatefulWidget {
  final bool isSetup;
  final Function(String)? onSetupComplete;
  final Function()? onCheckSuccess;
  final String? titleOverride;

  const _PinSheetContent({
    required this.isSetup,
    this.onSetupComplete,
    this.onCheckSuccess,
    this.titleOverride,
  });

  @override
  State<_PinSheetContent> createState() => _PinSheetContentState();
}

class _PinSheetContentState extends State<_PinSheetContent> {
  String _title = 'Enter PIN';
  String? _firstPin; // For setup flow

  @override
  void initState() {
    super.initState();
    if (widget.titleOverride != null) {
      _title = widget.titleOverride!;
    } else if (widget.isSetup) {
      _title = 'Create PIN';
    }
  }

  void _handlePin(String pin, BuildContext context) {
    if (widget.isSetup) {
      if (_firstPin == null) {
        // First entry done, ask for confirmation
        setState(() {
          _firstPin = pin;
          _title = 'Confirm PIN';
        });
      } else {
        // Confirmation entry
        if (pin == _firstPin) {
          widget.onSetupComplete?.call(pin);
        } else {
          // Mismatch
          setState(() {
            _firstPin = null;
            _title = 'PIN Mismatch. Try again.';
          });
          // Ideally clear pin pad state, but PinPad clears itself on complete call if we rebuilt it?
          // Actually PinPad holds local state. We might need to force a rebuild or show error.
          // For now, resetting the flow by changing title is a visual cue.
          // TODO: Add error animation or better reset.
        }
      }
    } else {
      // Validation flow
      // We need to check against the actual stored PIN.
      // Since this widget is inside the sheet, we can access Cubit.
      final isValid = context.read<SettingsCubit>().verifyPin(pin);
      if (isValid) {
        widget.onCheckSuccess?.call();
      } else {
        setState(() {
          _title = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a Key to force rebuild PinPad when title changes (e.g., to clear input)
    // if we want to reset inputs. But PinPad handles its own state.
    // To reset PinPad input on retry, we can use a Key.
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: PinPad(
            key: ValueKey(_title), // Reset state when step changes
            title: _title,
            onCompleted: (pin) => _handlePin(pin, context),
          ),
        ),
      ),
    );
  }
}
