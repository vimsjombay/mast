import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/budget.dart';
import 'package:myapp/expense.dart';

/// A service class to manage all interactions with the Hive database.
/// This class follows the singleton pattern to ensure a single instance
/// throughout the application.
class HiveService {
  // Singleton instance
  static HiveService? _instance;

  // Private constructor
  HiveService._internal();

  // Public factory constructor
  factory HiveService() {
    _instance ??= HiveService._internal();
    return _instance!;
  }

  // Check if the service has been initialized
  bool _isInitialized = false;

  // Box names
  static const String _expenseBoxName = 'expenses';
  static const String _categoryBoxName = 'categories';
  static const String _budgetBoxName = 'budgets';

  /// Initializes the Hive database, registers adapters, and opens boxes.
  /// This must be called once at application startup.
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(BudgetAdapter());
    await Hive.openBox<Expense>(_expenseBoxName);
    await Hive.openBox<String>(_categoryBoxName);
    await Hive.openBox<Budget>(_budgetBoxName);

    _isInitialized = true;
  }

  // --- Box Getters ---
  Box<Expense> getExpenseBox() => Hive.box<Expense>(_expenseBoxName);
  Box<String> getCategoryBox() => Hive.box<String>(_categoryBoxName);
  Box<Budget> getBudgetBox() => Hive.box<Budget>(_budgetBoxName);

  // --- Key Generation ---

  /// Generates a unique key for a budget based on year and month.
  String getBudgetKey(int year, int month) {
    return 'budget_${year}_$month';
  }

  // --- Expense Methods ---
  Future<void> addExpense(Expense expense) async {
    await getExpenseBox().put(expense.id, expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await getExpenseBox().put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    await getExpenseBox().delete(id);
  }

  List<Expense> getAllExpenses() {
    return getExpenseBox().values.toList();
  }

  // --- Category Methods ---
  Future<void> addCategory(String category) async {
    await getCategoryBox().add(category);
  }

  List<String> getAllCategories() {
    return getCategoryBox().values.toList();
  }

  // --- Budget Methods ---

  /// Saves or updates the budget for a specific month.
  /// This will trigger any listeners for the corresponding budget key.
  Future<void> saveBudget(double amount, int year, int month) async {
    final key = getBudgetKey(year, month);
    final budget = Budget(amount: amount, year: year, month: month);
    await getBudgetBox().put(key, budget);
  }

  /// Retrieves the budget for a specific month.
  /// Note: This is a non-reactive way to get the budget. For UI that needs
  /// to update on changes, use `getBudgetBox().listenable(keys: [key])`.
  Budget? getBudgetForMonth(int year, int month) {
    final key = getBudgetKey(year, month);
    return getBudgetBox().get(key);
  }
}
