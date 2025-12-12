import 'package:asterixia/core/services/permission_service.dart';
import 'package:asterixia/widgets/location_permission_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asterixia/core/services/location_service.dart';
import 'package:asterixia/core/services/sensor_service.dart';
import 'package:asterixia/features/ar_view/ar_view_page.dart';
import 'package:asterixia/features/star_map/star_map_page.dart';
import 'package:asterixia/features/settings/settings_page.dart';
import 'package:asterixia/theme/app_theme.dart';

void main() {
  runApp(const AsterixiaApp());
}

class AsterixiaApp extends StatelessWidget {
  const AsterixiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => SensorService()),
      ],
      child: MaterialApp(
        title: 'Asterixia',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainNavigationPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const ARViewPage(),
    const StarMapPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationPermissionSheet.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'AR View',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Star Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
