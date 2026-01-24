import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/category/domain/entities/category_entity.dart';
import 'package:push_wallet/features/transaction/domain/entities/transaction_entity.dart';

class AnalyticsHelper {
  final List<TransactionEntity> transactions;
  final List<Account> accounts;
  final List<CategoryEntity> categories;

  AnalyticsHelper({
    required this.transactions,
    required this.accounts,
    required this.categories,
  });

  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<CategoryEntity, double> get categoryExpenses {
    final map = <CategoryEntity, double>{};
    for (var t in transactions) {
      if (t.type == TransactionType.expense && t.categoryId != null) {
        // Find category
        final category = categories.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => CategoryEntity(
            id: 'unknown',
            name: 'Unknown',
            icon: '',
            color: 0,
            isIncome: false,
            subCategories: [],
          ),
        );
        map[category] = (map[category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Map<Account, double> get accountIncome {
    final map = <Account, double>{};
    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        final account = accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(
            id: 'unknown',
            name: 'Unknown',
            type: '',
            color: 0,
            icon: '',
            balance: 0,
          ),
        );
        map[account] = (map[account] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Map<Account, double> get accountExpenses {
    final map = <Account, double>{};
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        final account = accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(
            id: 'unknown',
            name: 'Unknown',
            type: '',
            color: 0,
            icon: '',
            balance: 0,
          ),
        );
        map[account] = (map[account] ?? 0) + t.amount;
      }
    }
    return map;
  }
}
