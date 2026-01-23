import 'package:hive/hive.dart';

import '../models/account_model.dart';

abstract class AccountLocalDataSource {
  Future<List<AccountModel>> getAccounts();
  Future<void> cacheAccount(AccountModel account);
  Future<void> deleteAccount(String id);
  Future<void> updateAccount(AccountModel account);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  final Box<AccountModel> accountBox;

  AccountLocalDataSourceImpl(this.accountBox);

  @override
  Future<List<AccountModel>> getAccounts() async {
    return accountBox.values.toList();
  }

  @override
  Future<void> cacheAccount(AccountModel account) async {
    await accountBox.put(account.id, account);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await accountBox.delete(id);
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    await accountBox.put(account.id, account);
  }
}
