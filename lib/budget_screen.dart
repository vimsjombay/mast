import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/budget.dart';
import 'package:myapp/expense.dart';
import 'package:myapp/services/hive_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final HiveService _hiveService = HiveService();
  DateTime _selectedMonth = DateTime.now();

  // Helper to generate the specific key for a budget month
  String _getBudgetKey(int year, int month) {
    return 'budget_${year}_$month';
  }

  Future<void> _setBudget(double amount) async {
    // No need for setState here, ValueListenableBuilder will handle it
    await _hiveService.saveBudget(amount, _selectedMonth.year, _selectedMonth.month);
  }

  void _showSetBudgetDialog(Budget? currentBudget) {
    showDialog(
      context: context,
      builder: (context) {
        return SetBudgetForm(
          onSetBudget: _setBudget,
          initialAmount: currentBudget?.amount ?? 0.0,
        );
      },
    );
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate the key for the currently selected month.
    final String budgetKey = _getBudgetKey(_selectedMonth.year, _selectedMonth.month);

    // Use a ValueListenableBuilder that listens to a SPECIFIC key in the budget box.
    // This is the most efficient and reliable way to ensure the UI updates.
    return ValueListenableBuilder(
      valueListenable: _hiveService.getBudgetBox().listenable(keys: [budgetKey]),
      builder: (context, Box<Budget> budgetBox, _) {
        final currentBudget = budgetBox.get(budgetKey);

        return Scaffold(
          body: ValueListenableBuilder(
            valueListenable: _hiveService.getExpenseBox().listenable(),
            builder: (context, Box<Expense> expenseBox, _) {
              final totalExpenses = expenseBox.values
                  .where((e) => e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month)
                  .fold(0.0, (sum, item) => sum + item.amount);

              final budgetAmount = currentBudget?.amount ?? 0.0;
              final remainingAmount = budgetAmount - totalExpenses;
              final hasBudget = budgetAmount > 0;

              return Column(
                children: [
                  _buildMonthSelector(),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hasBudget
                                  ? 'Budget for ${DateFormat.yMMMM().format(_selectedMonth)}'
                                  : 'No budget set for ${DateFormat.yMMMM().format(_selectedMonth)}',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (hasBudget)
                              _buildBudgetIndicator(budgetAmount, totalExpenses),
                            const SizedBox(height: 30),
                            if (hasBudget) ...[
                              Text(
                                'Total Spent: '
                                '₹${totalExpenses.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Remaining: '
                                '₹${remainingAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: remainingAmount >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 30),
                            ],
                            ElevatedButton(
                              onPressed: () => _showSetBudgetDialog(currentBudget),
                              child: Text(hasBudget ? 'Edit Budget' : 'Set Budget'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBudgetIndicator(double budgetAmount, double totalExpenses) {
    final double percentage =
        budgetAmount > 0 ? (totalExpenses / budgetAmount).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 20,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage < 0.5
                  ? Colors.green
                  : percentage < 0.9
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹0.00', style: Theme.of(context).textTheme.bodySmall),
            Text('₹${budgetAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormat.yMMMM().format(_selectedMonth),
            style: TextStyle(
                fontFamily: 'PTSans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }
}

class SetBudgetForm extends StatefulWidget {
  final Future<void> Function(double) onSetBudget;
  final double initialAmount;

  const SetBudgetForm({super.key, required this.onSetBudget, required this.initialAmount});

  @override
  State<SetBudgetForm> createState() => _SetBudgetFormState();
}

class _SetBudgetFormState extends State<SetBudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.initialAmount > 0 ? widget.initialAmount.toStringAsFixed(2) : '');
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      await widget.onSetBudget(amount);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Monthly Budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixText: '₹ ',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a positive number';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Set'),
        ),
      ],
    );
  }
}
