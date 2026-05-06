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
        : email?.split('@')[0] ?? 'Nguyễn Văn A';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'N';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppTheme.surfaceColor,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: HPV-${user?.uid.substring(0, 4).toUpperCase() ?? "8492"}-401',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: AppTheme.mutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đã xác thực',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: AppTheme.primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Metrics Grid (Bento Style)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _buildMetricCard('Tuổi', '58', 'tuổi'),
                _buildMetricCard('Chiều cao', '168', 'cm'),
                _buildMetricCard('Cân nặng', '72', 'kg'),
                _buildMetricCard('Nhóm máu', 'O+', '', isHighlighted: true),
              ],
            ),
            const SizedBox(height: 24),

            // Medical Conditions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tình trạng bệnh lý',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          textStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildConditionItem(
                    title: 'Cao huyết áp',
                    subtitle: 'Chẩn đoán: 2019',
                    status: 'Đang điều trị',
                    icon: Icons.favorite,
                    iconBg: AppTheme.criticalLightColor,
                    iconColor: AppTheme.criticalColor,
                  ),
                  const SizedBox(height: 12),
                  _buildConditionItem(
                    title: 'Tiểu đường tuýp 2',
                    subtitle: 'Chẩn đoán: 2021',
                    status: 'Kiểm soát tốt',
                    icon: Icons.water_drop,
                    iconBg: AppTheme.primaryColor.withValues(alpha: 0.1),
                    iconColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Settings
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Cài đặt tài khoản',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSettingItem(
                    icon: Icons.security,
                    title: 'Bảo mật & Mật khẩu',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSettingItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Cài đặt thông báo',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSettingItem(
                    icon: Icons.language,
                    title: 'Ngôn ngữ',
                    trailingText: 'Tiếng Việt',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => authService.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppTheme.criticalColor,
                  backgroundColor: AppTheme.surfaceColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppTheme.criticalColor.withValues(alpha: 0.2),
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Phiên bản ứng dụng: 2.4.1 (Build 842)',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: AppTheme.mutedTextColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: AppTheme.mutedTextColor,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? AppTheme.primaryColor : AppTheme.textColor,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem({
    required String title,
    required String subtitle,
    required String status,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.mutedTextColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: AppTheme.mutedTextColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppTheme.mutedTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
