import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_app/concept/scan_page.dart';
import 'package:smooth_app/concept/profile_page.dart';
import 'package:smooth_app/concept/history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Widget> _pages = <Widget>[
    HistoryPage(),
    ScanPage(),
    ProfilePage(),
  ];
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    // TODO(slava-sh): Add intro screen.
    return Scaffold(
      body: _pages[_currentPage],
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 24.0 * 2),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentPage,
        selectedItemColor: Colors.amber[800],
        onTap: _onTap,
      ),
    );
  }

  void _onTap(int index) {
    setState(() {
      _currentPage = index;
    });
  }
}
