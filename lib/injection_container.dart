import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'features/account/data/datasources/account_local_datasource.dart';
import 'features/account/data/models/account_model.dart';
import 'features/account/data/repositories/account_repository_impl.dart';
import 'features/account/domain/repositories/account_repository.dart';
import 'package:push_wallet/features/account/domain/usecases/account_usecases.dart';
import 'features/category/data/category_data.dart';
import 'features/category/domain/usecases/category_usecases.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'core/services/backup_service.dart';

import 'features/account/presentation/bloc/account_cubit.dart';
import 'features/category/presentation/bloc/category_cubit.dart';
import 'features/transaction/presentation/bloc/transaction_cubit.dart';
import 'features/transaction/data/transaction_data.dart';
import 'features/transaction/domain/repositories/transaction_repository.dart';
import 'features/transaction/domain/usecases/add_transaction.dart';
import 'features/transaction/domain/usecases/delete_transaction.dart';
import 'package:push_wallet/features/transaction/domain/usecases/update_transaction.dart';

import 'features/todo/data/todo_data.dart';
import 'features/todo/domain/usecases/todo_usecases.dart';
import 'features/todo/presentation/bloc/todo_cubit.dart';

import 'features/workout/data/workout_data.dart';
import 'features/workout/domain/usecases/workout_usecases.dart';
import 'features/workout/presentation/bloc/workout_cubit.dart';

// Blocs will be added later

final sl = GetIt.instance;

Future<void> init() async {
  final settingsBox = await Hive.openBox('settings');

  // Features - Account
  // Bloc
  sl.registerFactory(
    () => AccountCubit(
      getAccounts: sl(),
      addAccount: sl(),
      deleteAccount: sl(),
      updateAccount: sl(),
      settingsBox: settingsBox,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAccounts(sl()));
  sl.registerLazySingleton(() => AddAccount(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));
  sl.registerLazySingleton(() => UpdateAccount(sl()));

  // Repository
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<AccountLocalDataSource>(
    () => AccountLocalDataSourceImpl(sl()),
  );

  // Features - Category
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => AddCategory(sl()));
  sl.registerLazySingleton(() => DeleteCategory(sl()));
  sl.registerLazySingleton(() => UpdateCategory(sl()));

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(sl()),
  );

  sl.registerFactory(
    () => CategoryCubit(
      getCategories: sl(),
      addCategory: sl(),
      deleteCategory: sl(),
      updateCategory: sl(),
      settingsBox: settingsBox,
    ),
  );

  // Features - Transaction
  sl.registerFactory(
    () => TransactionCubit(
      repository: sl(),
      addTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
      updateTransactionUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => AddTransaction(sl(), sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl(), sl()));
  sl.registerLazySingleton(() => UpdateTransaction(sl(), sl()));

  // Features - Settings
  sl.registerLazySingleton<BackupService>(
    () => BackupService(
      accountBox: sl(),
      categoryBox: sl(),
      transactionBox: sl(),
      settingsBox: settingsBox,
      todoBox: sl(),
      workoutBox: sl(),
    ),
  );

  sl.registerFactory(
    () => SettingsCubit(settingsBox: settingsBox, backupService: sl()),
  );

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(sl()),
  );

  // Features - Todo
  sl.registerFactory(
    () => TodoCubit(
      getTodos: sl(),
      addTodo: sl(),
      updateTodo: sl(),
      deleteTodo: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetTodos(sl()));
  sl.registerLazySingleton(() => AddTodo(sl()));
  sl.registerLazySingleton(() => UpdateTodo(sl()));
  sl.registerLazySingleton(() => DeleteTodo(sl()));
  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TodoLocalDataSource>(
    () => TodoLocalDataSourceImpl(sl()),
  );

  // Features - Workout
  sl.registerFactory(
    () => WorkoutCubit(
      getWorkouts: sl(),
      addWorkout: sl(),
      updateWorkout: sl(),
      deleteWorkout: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetWorkouts(sl()));
  sl.registerLazySingleton(() => AddWorkout(sl()));
  sl.registerLazySingleton(() => UpdateWorkout(sl()));
  sl.registerLazySingleton(() => DeleteWorkout(sl()));
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<WorkoutLocalDataSource>(
    () => WorkoutLocalDataSourceImpl(sl()),
  );

  // External
  final accountBox = await Hive.openBox<AccountModel>('accounts');
  sl.registerLazySingleton(() => accountBox);

  final categoryBox = await Hive.openBox<CategoryModel>('categories');
  sl.registerLazySingleton(() => categoryBox);

  final transactionBox = await Hive.openBox<TransactionModel>('transactions');
  sl.registerLazySingleton(() => transactionBox);

  final todoBox = await Hive.openBox<TodoModel>('todos');
  sl.registerLazySingleton(() => todoBox);

  final workoutBox = await Hive.openBox<WorkoutModel>('workouts');
  sl.registerLazySingleton(() => workoutBox);
}
