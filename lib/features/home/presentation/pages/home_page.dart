import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/settings/presentation/pages/settings_page.dart';
import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';
import '../../../todo/presentation/pages/todo_list_page.dart';
import '../../../todo/presentation/bloc/todo_cubit.dart';
import '../../../workout/presentation/pages/workout_list_page.dart';
import '../../../workout/presentation/bloc/workout_cubit.dart';
import '../../../account/presentation/bloc/account_cubit.dart';
import '../../../qr_scanner/presentation/pages/qr_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:push_wallet/features/security/presentation/pages/auth_page.dart';
import '../widgets/vault_wrapper.dart';
import 'package:push_wallet/features/settings/presentation/widgets/firebase_sync_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Pre-load data to ensure cells show live numbers immediately
    context.read<TodoCubit>().loadTodos();
    context.read<WorkoutCubit>().loadWorkouts();
    context.read<AccountCubit>().loadAccounts();
  }

  void _showCloudSyncOptions(BuildContext context) {
    final bool isAuth = FirebaseAuth.instance.currentUser != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Cloud Sync Options',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                enabled: isAuth,
                leading: Icon(Icons.cloud_upload_outlined, color: isAuth ? Colors.blue : Colors.grey),
                title: Text(
                  'Backup to Firebase Cloud',
                  style: TextStyle(color: isAuth ? null : Colors.grey),
                ),
                onTap: isAuth
                    ? () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const FirebaseSyncDialog(isBackupMode: true),
                        );
                      }
                    : null,
              ),
              ListTile(
                enabled: isAuth,
                leading: Icon(Icons.cloud_download_outlined, color: isAuth ? Colors.blue : Colors.grey),
                title: Text(
                  'Restore from Firebase Cloud',
                  style: TextStyle(color: isAuth ? null : Colors.grey),
                ),
                onTap: isAuth
                    ? () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => const FirebaseSyncDialog(isBackupMode: false),
                        );
                      }
                    : null,
              ),
              ListTile(
                leading: Icon(
                  isAuth ? Icons.logout : Icons.login,
                  color: isAuth ? Colors.red : Colors.blue,
                ),
                title: Text(isAuth ? 'Log Out' : 'Log In / Sign Up'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isAuth) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                        (route) => false,
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOMO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your personal hub',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.cloud_sync_outlined, color: Colors.blue),
                          onPressed: () => _showCloudSyncOptions(context),
                          tooltip: 'Firebase Cloud Sync',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: Colors.black87),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsPage()),
                          ),
                          tooltip: 'Settings',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 2x2 Grid View
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                    // Cell 1: To-Do
                    BlocBuilder<TodoCubit, TodoState>(
                      builder: (context, state) {
                        String subtitle = 'Manage tasks';
                        if (state is TodoLoaded) {
                          final count = state.todos.where((t) => !t.isCompleted).length;
                          subtitle = count == 1 ? '1 task pending' : '$count tasks pending';
                        }
                        return _GridCard(
                          title: 'To-Do',
                          subtitle: subtitle,
                          icon: Icons.check_circle_outline,
                          gradientColors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TodoListPage()),
                          ),
                        );
                      },
                    ),

                    // Cell 2: Workout
                    BlocBuilder<WorkoutCubit, WorkoutState>(
                      builder: (context, state) {
                        String subtitle = 'Track workouts';
                        if (state is WorkoutLoaded) {
                          final count = state.workouts.length;
                          subtitle = count == 1 ? '1 log entries' : '$count logs recorded';
                        }
                        return _GridCard(
                          title: 'Workout',
                          subtitle: subtitle,
                          icon: Icons.fitness_center_rounded,
                          gradientColors: const [Color(0xFFD84315), Color(0xFFFF8A65)],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WorkoutListPage()),
                          ),
                        );
                      },
                    ),

                    // Cell 3: Account
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsState) {
                        final String currency;
                        if (settingsState is SettingsLoaded) {
                          currency = settingsState.currencySymbol;
                        } else {
                          currency = '\$';
                        }
                        return BlocBuilder<AccountCubit, AccountState>(
                          builder: (context, accountState) {
                            String subtitle = 'Financial Vault';
                            if (accountState is AccountLoaded) {
                              double totalBalance = 0;
                              for (var acc in accountState.accounts) {
                                if (acc.type == 'Card' || acc.type == 'Loan') {
                                  totalBalance -= acc.balance;
                                } else {
                                  totalBalance += acc.balance;
                                }
                              }
                              subtitle = '$currency${totalBalance.toStringAsFixed(0)} Net Total';
                            }
                            return _GridCard(
                              title: 'Account',
                              subtitle: subtitle,
                              icon: Icons.account_balance_wallet_outlined,
                              gradientColors: const [Color(0xFF00695C), Color(0xFF009688)],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const VaultWrapper()),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Cell 4: Scan QR
                    _GridCard(
                      title: 'Scan QR',
                      subtitle: 'Pay via UPI',
                      icon: Icons.qr_code_scanner_rounded,
                      gradientColors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QrHomePage()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          elevation: _isPressed ? 1 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Icon Circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                // Text details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
