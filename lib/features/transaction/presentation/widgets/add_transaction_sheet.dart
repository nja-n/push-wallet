// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:push_wallet/features/category/presentation/bloc/category_cubit.dart';
import 'package:push_wallet/features/transaction/presentation/bloc/transaction_cubit.dart';
import 'package:push_wallet/features/transaction/domain/entities/transaction_entity.dart';
import 'package:uuid/uuid.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionEntity? transaction;

  const AddTransactionSheet({super.key, this.transaction});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  String? _subCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descController.text = t.description;
      _amountController.text = t.amount.toString();
      _type = t.type;
      _accountId = t.accountId;
      _toAccountId = t.toAccountId;
      _categoryId = t.categoryId;
      _subCategoryId = t.subCategoryId;
      _selectedDate = t.date;
      _selectedTime = TimeOfDay.fromDateTime(t.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.transaction == null
                    ? 'Add Transaction'
                    : 'Edit Transaction',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Transaction Type Segmented Control style
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: TransactionType.transfer,
                label: Text('Transfer'),
                icon: Icon(Icons.swap_horiz),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (Set<TransactionType> newSelection) {
              setState(() {
                _type = newSelection.first;
                // Only reset category if switching type generally, but for edit we might want to keep?
                // If editing, user might change type intentionally.
                // Resetting is safer to avoid invalid states.
                if (widget.transaction?.type != _type) {
                  _categoryId = null;
                  _subCategoryId = null;
                }
              });
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Date & Time
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Account Dropdown
          BlocBuilder<AccountCubit, AccountState>(
            builder: (context, state) {
              var accounts = <dynamic>[];
              if (state is AccountLoaded) accounts = state.accounts;

              return DropdownButtonFormField<String>(
                value: _accountId,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: accounts.map<DropdownMenuItem<String>>((e) {
                  return DropdownMenuItem(value: e.id, child: Text(e.name));
                }).toList(),
                onChanged: (val) => setState(() => _accountId = val),
              );
            },
          ),
          const SizedBox(height: 12),

          if (_type == TransactionType.transfer)
            BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                var accounts = <dynamic>[];
                if (state is AccountLoaded) accounts = state.accounts;

                return DropdownButtonFormField<String>(
                  value: _toAccountId,
                  decoration: const InputDecoration(
                    labelText: 'To Account',
                    prefixIcon: Icon(Icons.arrow_forward),
                  ),
                  items: accounts
                      .where((e) => e.id != _accountId)
                      .map<DropdownMenuItem<String>>((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        );
                      })
                      .toList(),
                  onChanged: (val) => setState(() => _toAccountId = val),
                );
              },
            ),

          if (_type != TransactionType.transfer)
            BlocBuilder<CategoryCubit, CategoryState>(
              builder: (context, state) {
                var categories = <dynamic>[];
                if (state is CategoryLoaded) {
                  categories = state.categories
                      .where(
                        (c) => c.isIncome == (_type == TransactionType.income),
                      )
                      .toList();
                }

                // Find selected category object to check for subcategories
                final selectedCategory =
                    (state is CategoryLoaded && _categoryId != null)
                    ? state.categories
                          .where((c) => c.id == _categoryId)
                          .firstOrNull
                    : null;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories.map<DropdownMenuItem<String>>((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _categoryId = val;
                          _subCategoryId = null;
                        });
                      },
                    ),
                    if (selectedCategory != null &&
                        selectedCategory.subCategories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _subCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                          prefixIcon: Icon(Icons.subdirectory_arrow_right),
                        ),
                        items: selectedCategory.subCategories
                            .map<DropdownMenuItem<String>>((e) {
                              return DropdownMenuItem(
                                value: e.id,
                                child: Text(e.name),
                              );
                            })
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _subCategoryId = val),
                      ),
                    ],
                  ],
                );
              },
            ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveTransaction,
            child: Text(
              widget.transaction == null
                  ? 'Save Transaction'
                  : 'Update Transaction',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _saveTransaction() async {
    if (_accountId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final transaction = TransactionEntity(
      id: widget.transaction?.id ?? const Uuid().v4(),
      amount: amount,
      date: dateTime,
      description: _descController.text,
      type: _type,
      accountId: _accountId!,
      toAccountId: _toAccountId,
      categoryId: _categoryId,
      subCategoryId: _subCategoryId,
    );

    if (widget.transaction != null) {
      await context.read<TransactionCubit>().updateTransaction(transaction);
    } else {
      await context.read<TransactionCubit>().addTransaction(transaction);
    }

    if (!mounted) return;
    context.read<AccountCubit>().loadAccounts(); // Refresh accounts
    Navigator.pop(context);
  }
}
