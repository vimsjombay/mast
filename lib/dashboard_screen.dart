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
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _expenseBox = HiveService().getExpenseBox();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'By Category'),
              Tab(text: 'Trends'),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder(
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
        ],
      ),
    );
  }

  Widget _buildSummary(List<Expense> expenses) {
    final monthlyExpenses = <String, double>{};
    for (var expense in expenses) {
      final month = DateFormat.yMMM().format(expense.date);
      monthlyExpenses.update(month, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
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
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
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
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Expenses for $currentMonth',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Text('\u20b9${currentMonthTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(monthlyExpenses.keys.toList()[index],
                                style: Theme.of(context).textTheme.bodySmall),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(),
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
      categoryExpenses.update(
          expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final totalExpenses =
        categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);

    int i = 0;
    final pieChartSections = categoryExpenses.entries.map((entry) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 110.0 : 100.0;
      final percentage = (entry.value / totalExpenses) * 100;
      i++;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Spending by Category',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                }),
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
              duration: const Duration(milliseconds: 150), // Optional
              curve: Curves.linear, // Optional
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: categoryExpenses.entries.map((entry) {
              return _buildLegend(
                  entry.key, _getCategoryColor(entry.key), entry.value);
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String category, Color color, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text('$category: \u20b9${amount.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildTrendsChart(List<Expense> expenses) {
    final dailyExpenses = <int, double>{};
    final now = DateTime.now();
    final currentMonthExpenses = expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .toList();

    for (var expense in currentMonthExpenses) {
      dailyExpenses.update(expense.date.day, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final spots = dailyExpenses.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(),
          ),
        ),
        duration: const Duration(milliseconds: 250), // Optional
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Simple color mapping for categories
    switch (category) {
      case 'Food':
        return Colors.red.shade400;
      case 'Transport':
        return Colors.blue.shade400;
      case 'Shopping':
        return Colors.green.shade400;
      case 'Bills':
        return Colors.orange.shade400;
      case 'Entertainment':
        return Colors.purple.shade400;
      case 'Other':
        return Colors.grey.shade400;
      default:
        return Colors.black;
    }
  }
}
