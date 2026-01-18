import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/expense.dart';
import 'package:myapp/services/hive_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box<Expense> _expenseBox;

  @override
  void initState() {
    super.initState();
    _expenseBox = HiveService().getExpenseBox();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'By Category'),
              Tab(text: 'Trends'),
            ],
          ),
          title: const Text('Dashboard'),
        ),
        body: ValueListenableBuilder(
          valueListenable: _expenseBox.listenable(),
          builder: (context, Box<Expense> box, _) {
            final expenses = box.values.toList();
            return TabBarView(
              children: [
                _buildSummary(expenses),
                _buildCategoryPieChart(expenses),
                _buildTrendsChart(expenses),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(List<Expense> expenses) {
    final monthlyExpenses = <String, double>{};
    for (var expense in expenses) {
      final month = DateFormat.yMMM().format(expense.date);
      monthlyExpenses.update(month, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    final barGroups = monthlyExpenses.entries.map((entry) {
      final month = entry.key;
      final total = entry.value;
      final monthIndex = monthlyExpenses.keys.toList().indexOf(month);
      return BarChartGroupData(
        x: monthIndex,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Theme.of(context).colorScheme.primary,
            width: 16,
          ),
        ],
      );
    }).toList();

    final currentMonth = DateFormat.yMMM().format(DateTime.now());
    final currentMonthTotal = monthlyExpenses[currentMonth] ?? 0.0;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Expenses for $currentMonth', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8.0),
                Text('₹${currentMonthTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyExpenses.keys.length) {
                          return Text(monthlyExpenses.keys.toList()[index]);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(List<Expense> expenses) {
    final categoryExpenses = <String, double>{};
    for (var expense in expenses) {
      categoryExpenses.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final totalExpenses = categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    final pieChartSections = categoryExpenses.entries.map((entry) {
      final percentage = (entry.value / totalExpenses) * 100;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart(List<Expense> expenses) {
    final dailyExpenses = <int, double>{};
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) => e.date.month == now.month && e.date.year == now.year).toList();

    for (var expense in currentMonthExpenses) {
      dailyExpenses.update(expense.date.day, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }

    final spots = dailyExpenses.entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Simple color mapping for categories
    switch (category) {
      case 'Food':
        return Colors.red;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.green;
      case 'Bills':
        return Colors.orange;
      case 'Entertainment':
        return Colors.purple;
      case 'Other':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
