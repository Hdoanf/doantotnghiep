import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.user;
    final displayName = user?.displayName;
    final email = user?.email;
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : email?.split('@')[0] ?? 'Người dùng';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'H';

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar with gradient ring
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 47,
                backgroundColor: AppTheme.surfaceColor,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Menu items
            _menuSection(
              title: 'Tài khoản',
              items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Chỉnh sửa thông tin',
                  iconColor: AppTheme.primaryColor,
                  iconBg: AppTheme.accentLightColor,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  iconColor: AppTheme.infoColor,
                  iconBg: AppTheme.infoLightColor,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _menuSection(
              title: 'Cài đặt',
              items: [
                _MenuItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Chế độ tối',
                  iconColor: const Color(0xFF8B5CF6),
                  iconBg: const Color(0xFFF5F3FF),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo',
                  iconColor: AppTheme.warningColor,
                  iconBg: AppTheme.warningLightColor,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Về ứng dụng',
                  iconColor: AppTheme.mutedTextColor,
                  iconBg: AppTheme.surface2Color,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Logout
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.criticalColor.withValues(alpha: 0.15),
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.criticalLightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.criticalColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: AppTheme.criticalColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.criticalColor,
                ),
                onTap: () => authService.signOut(),
              ),
            ),
            const SizedBox(height: 32),
            // App version
            const Text(
              'HF Health v1.0.0',
              style: TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: AppTheme.textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.mutedTextColor,
                    ),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: AppTheme.borderColor.withValues(alpha: 0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });
}
