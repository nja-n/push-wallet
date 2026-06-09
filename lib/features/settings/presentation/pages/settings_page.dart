import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_cubit.dart';
import '../../../account/presentation/bloc/account_cubit.dart';
import '../../../category/presentation/bloc/category_cubit.dart';
import '../../../transaction/presentation/bloc/transaction_cubit.dart';
import '../../../todo/presentation/bloc/todo_cubit.dart';
import '../../../workout/presentation/bloc/workout_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../security/presentation/pages/security_settings_page.dart';
import '../../../security/presentation/pages/auth_page.dart';
import '../widgets/firebase_sync_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final settingsCubit = context.read<SettingsCubit>();
    final settingsState = settingsCubit.state;
    final bool autoBackup = settingsState is SettingsLoaded && settingsState.autoBackup;

    final accountCubit = context.read<AccountCubit>();
    final categoryCubit = context.read<CategoryCubit>();
    final transactionCubit = context.read<TransactionCubit>();
    final todoCubit = context.read<TodoCubit>();
    final workoutCubit = context.read<WorkoutCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isBackingUp = false;
        String backupStatus = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Confirm Logout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Logging out will clear all local data from this device to protect your security. Any data not backed up will be lost.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    if (autoBackup)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto Backup is enabled. Your latest changes should be secure on the cloud.',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto Backup is disabled. Please backup your data to avoid data loss.',
                              style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    if (isBackingUp) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        backupStatus,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: isBackingUp
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      if (!autoBackup)
                        ElevatedButton.icon(
                          onPressed: () async {
                            setDialogState(() {
                              isBackingUp = true;
                              backupStatus = 'Backing up to cloud...';
                            });
                            final success = await settingsCubit.backupToFirebase();
                            if (success) {
                              setDialogState(() {
                                backupStatus = 'Backup successful! Logging out...';
                              });
                              await Future.delayed(const Duration(milliseconds: 500));
                              // Log out and clear
                              await FirebaseAuth.instance.signOut();
                              await settingsCubit.backupService.clearAllLocalData();
                              
                              // Reload cubits
                              accountCubit.loadAccounts();
                              categoryCubit.loadCategories();
                              transactionCubit.loadTransactions();
                              todoCubit.loadTodos();
                              workoutCubit.loadWorkouts();
                              settingsCubit.loadSettings();

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx); // pop dialog
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const AuthPage()),
                                  (route) => false,
                                );
                              }
                            } else {
                              setDialogState(() {
                                isBackingUp = false;
                                backupStatus = 'Backup failed.';
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Backup failed. Please try again or log out without backup.')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.cloud_upload, size: 16),
                          label: const Text('Backup & Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      TextButton(
                        onPressed: () async {
                          // Perform logout and clear data directly
                          await FirebaseAuth.instance.signOut();
                          await settingsCubit.backupService.clearAllLocalData();
                          
                          // Reload cubits
                          accountCubit.loadAccounts();
                          categoryCubit.loadCategories();
                          transactionCubit.loadTransactions();
                          todoCubit.loadTodos();
                          workoutCubit.loadWorkouts();
                          settingsCubit.loadSettings();

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx); // pop dialog
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthPage()),
                              (route) => false,
                            );
                          }
                        },
                        child: Text(
                          autoBackup ? 'Log Out' : 'Log Out Anyway',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencies = {
      '\$': 'Dollar (\$)',
      '€': 'Euro (€)',
      '₹': 'Rupee (₹)',
      '£': 'Pound (£)',
      '¥': 'Yen (¥)',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(FirebaseAuth.instance.currentUser?.email ?? 'Guest User'),
              subtitle: Text(FirebaseAuth.instance.currentUser != null
                  ? 'Authenticated via Firebase'
                  : 'Log in to sync data to the cloud'),
              trailing: FirebaseAuth.instance.currentUser != null
                  ? TextButton(
                      onPressed: () => _showLogoutDialog(context),
                      child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                    )
                  : TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        );
                      },
                      child: const Text('Log In', style: TextStyle(color: Colors.blue)),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'General',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: Colors.red),
              ),
              title: const Text('Security'),
              subtitle: const Text('App Lock & PIN'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SecuritySettingsPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_exchange,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Currency'),
              subtitle: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  if (state is SettingsLoaded) {
                    final symbol = state.currencySymbol;
                    return Text(currencies[symbol] ?? symbol);
                  }
                  return const Text('');
                },
              ),
              onTap: () => _showCurrencyPicker(context, currencies),
            ),
          ),
          const SizedBox(height: 16),
          // Internal Data Section
          Text(
            'Internal Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final loaded = state as SettingsLoaded;
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Colors.green,
                        ),
                      ),
                      title: const Text('Backup Data'),
                      subtitle: Text(
                        loaded.lastBackup != null
                            ? 'Last: ${_formatDate(loaded.lastBackup!)}'
                            : 'No backup yet',
                      ),
                      onTap: () async {
                        await context.read<SettingsCubit>().createBackup(
                          context,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download, color: Colors.orange),
                      ),
                      title: const Text('Restore Data'),
                      subtitle: const Text('Import from backup file'),
                      onTap: () async {
                        final success = await context
                            .read<SettingsCubit>()
                            .restoreBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Data restored successfully!'
                                    : 'Restore cancelled or failed.',
                              ),
                            ),
                          );
                          if (success) {
                            if (context.mounted) {
                              context.read<AccountCubit>().loadAccounts();
                              context.read<CategoryCubit>().loadCategories();
                              context
                                  .read<TransactionCubit>()
                                  .loadTransactions();
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Cloud Data Section
          Text(
            'Cloud Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final loaded = state as SettingsLoaded;
              final bool isAuth = FirebaseAuth.instance.currentUser != null;

              return Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Auto Backup to Cloud',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        isAuth
                            ? 'Automatically sync database changes to Firebase'
                            : 'Log in required to enable auto backup',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey[500],
                        ),
                      ),
                      value: isAuth ? loaded.autoBackup : false,
                      onChanged: isAuth
                          ? (val) {
                              context.read<SettingsCubit>().toggleAutoBackup(val);
                            }
                          : null,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isAuth ? Theme.of(context).colorScheme.secondary : Colors.grey).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.backup,
                          color: isAuth ? Theme.of(context).colorScheme.secondary : Colors.grey,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      enabled: isAuth,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isAuth ? Colors.blue : Colors.grey).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: isAuth ? Colors.blue : Colors.grey,
                        ),
                      ),
                      title: Text(
                        'Backup to Firebase Cloud',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        'Sync backup data to Realtime Database',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey[500],
                        ),
                      ),
                      onTap: isAuth
                          ? () {
                              showDialog(
                                context: context,
                                builder: (_) => const FirebaseSyncDialog(isBackupMode: true),
                              );
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      enabled: isAuth,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isAuth ? Colors.blue : Colors.grey).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_download_outlined,
                          color: isAuth ? Colors.blue : Colors.grey,
                        ),
                      ),
                      title: Text(
                        'Restore from Firebase Cloud',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        'Retrieve backup data from Realtime Database',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey[500],
                        ),
                      ),
                      onTap: isAuth
                          ? () {
                              showDialog(
                                context: context,
                                builder: (_) => const FirebaseSyncDialog(isBackupMode: false),
                              );
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Auto Limit to 10 Backups',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        isAuth
                            ? 'Keep only the 10 most recent backups in the cloud'
                            : 'Log in required to enable limit',
                        style: TextStyle(
                          color: isAuth ? null : Colors.grey[500],
                        ),
                      ),
                      value: isAuth ? loaded.autoLimitBackups : false,
                      onChanged: isAuth
                          ? (val) {
                              context.read<SettingsCubit>().toggleAutoLimitBackups(val);
                            }
                          : null,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isAuth ? Theme.of(context).colorScheme.secondary : Colors.grey).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cleaning_services,
                          color: isAuth ? Theme.of(context).colorScheme.secondary : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _showCurrencyPicker(
    BuildContext context,
    Map<String, String> currencies,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Currency',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            ...currencies.entries.map(
              (e) => ListTile(
                title: Text(e.value),
                onTap: () {
                  context.read<SettingsCubit>().updateCurrency(e.key);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
