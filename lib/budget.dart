import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final int year;

  @HiveField(2)
  final int month;

  Budget({
    required this.amount,
    required this.year,
    required this.month,
  });
}
