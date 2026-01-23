import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;
import 'features/account/data/models/account_model.dart';
import 'features/category/data/category_data.dart';
import 'features/transaction/data/transaction_data.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:push_wallet/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:push_wallet/features/home/presentation/pages/home_page.dart';
import 'package:push_wallet/features/security/presentation/pages/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(SubCategoryModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<SettingsCubit>(),
        ), // Register Settings
        BlocProvider(create: (_) => di.sl<AccountCubit>()..loadAccounts()),
        BlocProvider(create: (_) => di.sl<CategoryCubit>()..loadCategories()),
        BlocProvider(
          create: (_) => di.sl<TransactionCubit>()..loadTransactions(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        // Rebuild on settings change
        builder: (context, state) {
          return MaterialApp(
            title: 'Push Wallet',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(), // Custom Light Theme
            themeMode: ThemeMode.light, // Enforce Light Mode
            home: state is SettingsLoaded
                ? (state.isSecurityEnabled
                      ? const AppLockScreen()
                      : const HomePage())
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F3A43), // Brand Dark Blue-Grey
        surface: const Color(0xFFF8FAFC), // Soft gray background
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
