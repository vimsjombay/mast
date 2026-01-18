import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/expense.dart';
import 'package:myapp/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => ExpensesScreenState();
}

class ExpensesScreenState extends State<ExpensesScreen> {
  final HiveService _hiveService = HiveService();
  late Box<Expense> _expenseBox;
  late Box<String> _categoryBox;
  DateTime _selectedMonth = DateTime.now();

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.fastfood,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt,
    'Entertainment': Icons.movie,
    'Other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _expenseBox = _hiveService.getExpenseBox();
    _categoryBox = _hiveService.getCategoryBox();
    if (_categoryBox.isEmpty) {
      _categoryBox.addAll([
        'Food',
        'Transport',
        'Shopping',
        'Bills',
        'Entertainment',
        'Other',
      ]);
    }
  }

  Future<void> _addOrUpdateExpense(Expense expense) async {
    if (_expenseBox.containsKey(expense.id)) {
      await _hiveService.updateExpense(expense);
    } else {
      await _hiveService.addExpense(expense);
    }
  }

  Future<void> _deleteExpense(String id) async {
    await _hiveService.deleteExpense(id);
  }

  Future<void> _addCategory(String category) async {
    if (!_categoryBox.values.contains(category)) {
      await _hiveService.addCategory(category);
      if (mounted) {
        setState(() {
          _categoryIcons.putIfAbsent(category, () => Icons.category);
        });
      }
    }
  }

  void _showAddExpenseDialog({Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddExpenseForm(
            onAddExpense: _addOrUpdateExpense,
            categories: _categoryBox.values.toList(),
            onAddCategory: _addCategory,
            expense: expense,
            selectedMonth: _selectedMonth,
          ),
        );
      },
    );
  }

  void _showExpensePreviewSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ExpensePreviewSheet(
          expense: expense,
          onEdit: () {
            Navigator.of(context).pop();
            _showAddExpenseDialog(expense: expense);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _showDeleteConfirmation(expense.id);
          },
        );
      },
    );
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + increment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _expenseBox.listenable(),
              builder: (context, Box<Expense> box, _) {
                final filteredExpenses = box.values
                    .where((expense) =>
                        expense.date.year == _selectedMonth.year &&
                        expense.date.month == _selectedMonth.month)
                    .toList();

                if (filteredExpenses.isEmpty) {
                  return Center(
                    child: Text(
                      'No expenses for this month.',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withAlpha(153)),
                    ),
                  );
                }

                final groupedExpenses = groupBy<Expense, int>(
                  filteredExpenses,
                  (expense) => expense.date.day,
                );

                final sortedDays = groupedExpenses.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: sortedDays.length,
                  itemBuilder: (context, index) {
                    final day = sortedDays[index];
                    final dayExpenses = groupedExpenses[day]!;
                    final dayTotal =
                        dayExpenses.fold(0.0, (sum, item) => sum + item.amount);
                    final date = dayExpenses.first.date;

                    return Card(
                      margin: const EdgeInsets.only(
                          left: 4.0, right: 4.0, bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          '${DateFormat.MMMMd().format(date)} - ${DateFormat.EEEE().format(date)}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.color),
                        ),
                        subtitle: Text(
                          'Total: \$${dayTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color
                                  ?.withAlpha(153),
                              fontWeight: FontWeight.w600),
                        ),
                        initiallyExpanded: true,
                        children: dayExpenses.map<Widget>((expense) {
                          return ListTile(
                            onTap: () => _showExpensePreviewSheet(expense),
                            leading: Icon(
                              _categoryIcons[expense.category] ?? Icons.category,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              expense.category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              '\$${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                _deleteExpense(id);
                navigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: DateTime.now().year == _selectedMonth.year &&
                    DateTime.now().month == _selectedMonth.month
                ? null
                : () => _changeMonth(1),
          ),
        ],
      ),
    );
  }
}

class ExpensePreviewSheet extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpensePreviewSheet({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expense Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('Category: ${expense.category}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Amount: \$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Date: ${DateFormat.yMMMd().format(expense.date)}', style: const TextStyle(fontSize: 18)),
            if (expense.description != null && expense.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text('Description: ${expense.description}', style: const TextStyle(fontSize: 18)),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onEdit,
                  child: const Text('Edit', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Delete', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddExpenseForm extends StatefulWidget {
  final Future<void> Function(Expense) onAddExpense;
  final List<String> categories;
  final Future<void> Function(String) onAddCategory;
  final Expense? expense;
  final DateTime selectedMonth;

  const AddExpenseForm({
    super.key,
    required this.onAddExpense,
    required this.categories,
    required this.onAddCategory,
    required this.selectedMonth,
    this.expense,
  });

  @override
  State<AddExpenseForm> createState() => AddExpenseFormState();
}

class AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late List<String> _categories;
  String? _selectedCategory;
  late DateTime _selectedDate;
  late String _expenseId;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
    _amountController = TextEditingController(
        text: widget.expense != null
            ? widget.expense!.amount.toStringAsFixed(2)
            : '');
    _descriptionController =
        TextEditingController(text: widget.expense?.description ?? '');
    _selectedCategory = widget.expense?.category;
    _selectedDate = widget.expense?.date ?? _getInitialDatePickerDate();
    _expenseId = widget.expense?.id ?? const Uuid().v4();
  }

  DateTime _getInitialDatePickerDate() {
    final now = DateTime.now();
    if (widget.selectedMonth.year == now.year &&
        widget.selectedMonth.month == now.month) {
      return now;
    }
    return DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final navigator = Navigator.of(context);
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final newExpense = Expense(
        id: _expenseId,
        category: _selectedCategory!,
        amount: amount,
        date: _selectedDate,
        description: _descriptionController.text,
      );
      await widget.onAddExpense(newExpense);
      navigator.pop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCreateCategoryDialog() {
    final newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Create New Category',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: newCategoryController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCategory = newCategoryController.text;
                if (newCategory.isNotEmpty &&
                    !_categories.contains(newCategory)) {
                  await widget.onAddCategory(newCategory);
                  if (mounted) {
                    setState(() {
                      _categories.add(newCategory);
                      _selectedCategory = newCategory;
                    });
                    navigator.pop();
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.expense == null ? 'Add Expense' : 'Edit Expense',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: [
                    ..._categories.map((category) {
                      return DropdownMenuItem(
                          value: category, child: Text(category));
                    }),
                    const DropdownMenuItem(
                      value: '__CREATE_NEW__',
                      child: Text('+ Create New',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == '__CREATE_NEW__') {
                      _showCreateCategoryDialog();
                    } else {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixText: '\$ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                      widget.expense == null ? 'Add Expense' : 'Save Changes',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
