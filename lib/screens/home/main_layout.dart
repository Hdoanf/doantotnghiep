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

  // Index 1 (ScanScreen) không cache — camera khởi động/tắt theo tab
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  Widget _screenFor(int index) {
    if (index == 1) return const ScanScreen();
    return _screens[index] ??= switch (index) {
      0 => const HomeScreen(),
      2 => const AIChatScreen(),
      3 => const HistoryScreen(),
      4 => const ProfileScreen(),
      _ => const HomeScreen(),
    };
  }

  // Index trong IndexedStack không tính slot scan (index 1)
  // Screens: 0=Home, 1=AI, 2=History, 3=Profile
  static const _nonScanIndices = [0, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final isScan = _selectedIndex == 1;
    final nonScanIndex = isScan ? 0 : _nonScanIndices.indexOf(_selectedIndex);

    return Scaffold(
      body: Stack(
        children: [
          // Các tab không phải camera — giữ state qua IndexedStack
          Offstage(
            offstage: isScan,
            child: IndexedStack(
              index: nonScanIndex.clamp(0, 3),
              children: _nonScanIndices
                  .map((i) => _screens[i] ?? _screenFor(i))
                  .toList(),
            ),
          ),
          // Camera tab — chỉ build khi active, tự dispose khi rời tab
          if (isScan) const ScanScreen(),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: selected
              ? BoxDecoration(
                  color: AppTheme.primaryLightColor.withValues(alpha: 0.1),
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
                  color: selected ? AppTheme.primaryLightColor : AppTheme.mutedTextColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primaryLightColor : AppTheme.mutedTextColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
