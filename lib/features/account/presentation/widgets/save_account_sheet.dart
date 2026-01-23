import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:push_wallet/features/account/domain/entities/account.dart';
import 'package:push_wallet/features/account/presentation/bloc/account_cubit.dart';
import 'package:uuid/uuid.dart';

class SaveAccountSheet extends StatefulWidget {
  final Account? account; // If null, create mode.
  const SaveAccountSheet({super.key, this.account});

  @override
  State<SaveAccountSheet> createState() => _SaveAccountSheetState();
}

class _SaveAccountSheetState extends State<SaveAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  String _type = 'Cash';
  int _selectedColor = 0xFF2196F3;
  String _selectedIcon = '🏦';

  final List<int> _colors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFFC107, // Amber
    0xFFFF5722, // Deep Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFF607D8B, // Blue Grey
  ];

  final List<String> _icons = [
    '🏦',
    '💵',
    '💳',
    '👛',
    '💰',
    '📉',
    '📈',
    '🏠',
    '🚗',
    '🍔',
    '✈️',
    '🎮',
    '💡',
    '🏥',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _type = widget.account!.type;
      _selectedColor = widget.account!.color;
      _selectedIcon = widget.account!.icon;
      if (widget.account!.creditLimit != null) {
        _creditLimitController.text = widget.account!.creditLimit.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Account' : 'New Account',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Icon Picker
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(_selectedColor).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(_selectedColor), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedIcon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon
                            ? Colors.grey.shade200
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Color Picker
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: CircleAvatar(
                      backgroundColor: Color(color),
                      radius: 20,
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),

            if (!isEdit && _type == 'Card') ...[
              TextField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Current Owed Amount',
                  prefixIcon: Icon(Icons.money_off),
                  helperText: 'Enter positive amount for debt',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
            ] else if (!isEdit) ...[
              TextField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
            ],

            if (_type == 'Card') ...[
              TextField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'Credit Limit',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
            ],

            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                'Cash',
                'Bank',
                'Wallet',
                'Card',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _type = val!),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty) return;

                final balance = double.tryParse(_balanceController.text) ?? 0.0;
                final creditLimit = _type == 'Card'
                    ? double.tryParse(_creditLimitController.text)
                    : null;

                if (isEdit) {
                  final updated = Account(
                    id: widget.account!.id,
                    name: _nameController.text,
                    type: _type,
                    balance: widget.account!.balance, // Keep current balance
                    color: _selectedColor,
                    icon: _selectedIcon,
                    creditLimit: creditLimit,
                  );
                  context.read<AccountCubit>().editAccount(updated);
                } else {
                  final newAccount = Account(
                    id: const Uuid().v4(),
                    name: _nameController.text,
                    type: _type,
                    balance: balance,
                    color: _selectedColor,
                    icon: _selectedIcon,
                    creditLimit: creditLimit,
                  );
                  context.read<AccountCubit>().createAccount(newAccount);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Save Changes' : 'Create Account'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
