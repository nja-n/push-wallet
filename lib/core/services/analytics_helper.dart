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

  Map<String, double> get categoryExpenses {
    final map = <String, double>{};
    for (var t in transactions) {
      if (t.type == TransactionType.expense && t.categoryId != null) {
        // Find category name
        final catName = categories
            .firstWhere(
              (c) => c.id == t.categoryId,
              orElse: () => CategoryEntity(
                id: 'unknown',
                name: 'Unknown',
                icon: '',
                color: 0,
                isIncome: false,
                subCategories: [],
              ),
            )
            .name;
        map[catName] = (map[catName] ?? 0) + t.amount;
      }
    }
    return map;
  }
}
