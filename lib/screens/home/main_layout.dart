import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'home_screen.dart';
import '../scan/scan_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  Widget _screenFor(int index) {
    return _screens[index] ??= switch (index) {
      0 => const HomeScreen(),
      1 => const ScanScreen(),
      2 => const AIChatScreen(),
      3 => const HistoryScreen(),
      4 => const ProfileScreen(),
      _ => const HomeScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    _screenFor(_selectedIndex);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            _screens[i] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderColor.withValues(alpha: 0.3),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Tổng quan'),
                _navItem(1, Icons.document_scanner_rounded, Icons.document_scanner_outlined, 'Quét'),
                _navItem(2, Icons.auto_awesome, Icons.auto_awesome_outlined, 'AI Tư vấn'),
                _navItem(3, Icons.history_rounded, Icons.history_outlined, 'Lịch sử'),
                _navItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Hồ sơ'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData icon, String label) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: selected
              ? BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  color: selected ? AppTheme.primaryColor : AppTheme.mutedTextColor,
                  size: selected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primaryColor : AppTheme.mutedTextColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: selected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
