import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:myapp/expense.dart';
import 'package:myapp/services/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final HiveService _hiveService = HiveService();
  late Box<Expense> _expenseBox;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _expenseBox = _hiveService.getExpenseBox();
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
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _expenseBox.listenable(),
              builder: (context, Box<Expense> box, _) {
                final expenses = box.values
                    .where((expense) =>
                        expense.date.year == _selectedMonth.year &&
                        expense.date.month == _selectedMonth.month)
                    .toList();

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expenses for this month',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final dataMap = <String, double>{};
                for (var expense in expenses) {
                  final category = expense.category;
                  dataMap[category] = (dataMap[category] ?? 0) + expense.amount;
                }

                final pieChartSections = dataMap.entries.map((entry) {
                  return PieChartSectionData(
                    color: _getColorForCategory(entry.key),
                    value: entry.value,
                    title: '${entry.key}\n${entry.value.toStringAsFixed(2)}',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList();

                final groupedExpenses = <String, List<Expense>>{};
                for (var expense in expenses) {
                  final category = expense.category;
                  if (!groupedExpenses.containsKey(category)) {
                    groupedExpenses[category] = [];
                  }
                  groupedExpenses[category]!.add(expense);
                }

                // FIX: Replaced SingleChildScrollView with a Column and Expanded ListView
                return Column(
                  children: [
                    const SizedBox(height: 5),
                    const Text(
                      'Spending by Category',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Expense Breakdown',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // FIX: Wrapped the ListView in an Expanded widget
                    Expanded(
                      child: ListView.builder(
                        itemCount: groupedExpenses.length,
                        itemBuilder: (context, index) {
                          final category =
                              groupedExpenses.keys.elementAt(index);
                          final categoryExpenses = groupedExpenses[category]!;
                          final categoryTotal = categoryExpenses.fold(
                              0.0, (sum, item) => sum + item.amount);

                          return ExpansionTile(
                            title: Text(
                              '$category: ${categoryTotal.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: categoryExpenses.map((expense) {
                              return ListTile(
                                title: Text(
                                    expense.description ?? 'No description'),
                                trailing: Text(
                                  expense.amount.toStringAsFixed(2),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    DateFormat.yMMMd().format(expense.date)),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
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

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }
}
