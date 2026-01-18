import 'package:flutter/material.dart';
import 'package:myapp/analytics_screen.dart';
import 'package:myapp/budget_screen.dart';
import 'package:myapp/dashboard_screen.dart';
import 'package:myapp/expenses_screen.dart';
import 'package:myapp/services/hive_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService().init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ExpensesScreen(),
    DashboardScreen(),
    BudgetScreen(),
    AnalyticsScreen(),
  ];

  static const List<String> _widgetTitles = <String>[
    'Expenses',
    'Dashboard',
    'Budget',
    'Analytics',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex], style: const TextStyle(fontFamily: 'PTSans', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  static final TextTheme _textTheme = const TextTheme(
    displayLarge: TextStyle(fontFamily: 'PTSans', fontSize: 57, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontFamily: 'PTSans', fontSize: 22, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontFamily: 'PTSans', fontSize: 14),
    bodyLarge: TextStyle(fontFamily: 'PTSans', fontSize: 16),
    headlineMedium: TextStyle(fontFamily: 'PTSans', fontSize: 24, fontWeight: FontWeight.bold),
  );

  static final TextTheme _darkTextTheme = const TextTheme(
    displayLarge: TextStyle(fontFamily: 'PTSans', fontSize: 57, fontWeight: FontWeight.bold, color: Colors.white),
    titleLarge: TextStyle(fontFamily: 'PTSans', fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
    bodyMedium: TextStyle(fontFamily: 'PTSans', fontSize: 14, color: Colors.white),
    bodyLarge: TextStyle(fontFamily: 'PTSans', fontSize: 16, color: Colors.white),
    headlineMedium: TextStyle(fontFamily: 'PTSans', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
  );

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'PTSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      shadowColor: Colors.black12,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: Colors.deepPurple,
      textColor: Colors.deepPurple,
      collapsedIconColor: Colors.grey[600],
      collapsedTextColor: Colors.black87,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.deepPurple,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'PTSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black87,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.deepPurple[300],
      unselectedItemColor: Colors.grey[500],
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 6,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: Colors.deepPurple[300],
      textColor: Colors.deepPurple[300],
      collapsedIconColor: Colors.grey[400],
      collapsedTextColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: Colors.deepPurple[300],
      tileColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurple[400],
      foregroundColor: Colors.black,
      elevation: 8,
      highlightElevation: 12,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.deepPurple[300]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple[400],
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
}
