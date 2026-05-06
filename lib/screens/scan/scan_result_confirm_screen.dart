import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/health_constants.dart';
import '../../models/health_record.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ScanResultConfirmScreen extends StatefulWidget {
  final Map<String, double> initialIndicators;
  final RecordType type;

  const ScanResultConfirmScreen({
    super.key,
    required this.initialIndicators,
    required this.type,
  });

  @override
  State<ScanResultConfirmScreen> createState() =>
      _ScanResultConfirmScreenState();
}

class _ScanResultConfirmScreenState extends State<ScanResultConfirmScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all defined indicators
    final config = HealthConstants.scanIndicators;
    config.forEach((key, value) {
      _controllers[key] = TextEditingController(
        text: widget.initialIndicators.containsKey(key)
            ? widget.initialIndicators[key]!.toString()
            : '',
      );
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final indicators = <String, double>{};
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        final val = double.tryParse(controller.text);
        if (val != null) indicators[key] = val;
      }
    });

    if (indicators.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final record = HealthRecord(
        id: '',
        userId: user.uid,
        date: DateTime.now(),
        type: widget.type,
        indicators: indicators,
      );
      await FirestoreService().addHealthRecord(record);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu dữ liệu thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
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
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show groups that have at least one indicator present in either initial scan OR user might want to fill.
    // In "Xác nhận", we usually show all related to the RecordType, or all that were scanned.
    // Let's show common ones that are in our _controllers map if they belong to the type.
    
    // For simplicity, we just check if we have controllers for them.
    final bool hasBp = _controllers.containsKey('systolic') && _controllers.containsKey('diastolic');
    final bool hasGlucose = _controllers.containsKey('glucose');
    final bool hasHeartRate = _controllers.containsKey('heart_rate');
    final bool hasCholesterol = _controllers.containsKey('cholesterol');
    final bool hasOtherLipids = _controllers.containsKey('hdl') || _controllers.containsKey('ldl') || _controllers.containsKey('triglycerides');
    final bool hasBody = _controllers.containsKey('weight') || _controllers.containsKey('height');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'HealthPulse VN',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập / Xác nhận chỉ số',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra và nhập các chỉ số sức khỏe của bạn để hệ thống theo dõi.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Detected Banner (if we came from scan)
            if (widget.initialIndicators.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI đã nhận diện ${widget.initialIndicators.length} chỉ số',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Text(
                            'Hãy kiểm tra lại độ chính xác.',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Bento Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.8,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                if (hasBp)
                  _buildBentoCard(
                    icon: Icons.favorite,
                    title: 'Huyết áp',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Tâm thu',
                              controller: _controllers['systolic']!,
                              placeholder: '120',
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                            child: Text('/', style: TextStyle(fontSize: 24, color: AppTheme.borderColor)),
                          ),
                          Expanded(
                            child: _buildInputField(
                              label: 'Tâm trương',
                              controller: _controllers['diastolic']!,
                              placeholder: '80',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text('mmHg', style: TextStyle(color: AppTheme.secondaryTextColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                if (hasGlucose)
                  _buildBentoCard(
                    icon: Icons.water_drop,
                    title: 'Đường huyết',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Chỉ số',
                              controller: _controllers['glucose']!,
                              placeholder: '5.5',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text('mmol/L', style: TextStyle(color: AppTheme.secondaryTextColor)),
                          ),
                        ],
                      ),
                    ],
                  ),

                if (hasHeartRate)
                  _buildBentoCard(
                    icon: Icons.monitor_heart,
                    title: 'Nhịp tim',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Nhịp',
                              controller: _controllers['heart_rate']!,
                              placeholder: '72',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text('bpm', style: TextStyle(color: AppTheme.secondaryTextColor)),
                          ),
                        ],
                      ),
                    ],
                  ),

                if (hasCholesterol)
                  _buildBentoCard(
                    icon: Icons.science,
                    title: 'Cholesterol',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Tổng',
                              controller: _controllers['cholesterol']!,
                              placeholder: '5.0',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text('mmol/L', style: TextStyle(color: AppTheme.secondaryTextColor)),
                          ),
                        ],
                      ),
                    ],
                  ),

                if (hasOtherLipids)
                  _buildBentoCard(
                    icon: Icons.bloodtype,
                    title: 'Bộ mỡ máu khác',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_controllers.containsKey('hdl'))
                            Expanded(
                              child: _buildInputField(
                                label: 'HDL',
                                controller: _controllers['hdl']!,
                                placeholder: '1.2',
                              ),
                            ),
                          if (_controllers.containsKey('hdl') && _controllers.containsKey('ldl'))
                            const SizedBox(width: 8),
                          if (_controllers.containsKey('ldl'))
                            Expanded(
                              child: _buildInputField(
                                label: 'LDL',
                                controller: _controllers['ldl']!,
                                placeholder: '2.5',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                
                if (hasBody)
                  _buildBentoCard(
                    icon: Icons.accessibility_new,
                    title: 'Chỉ số cơ thể',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_controllers.containsKey('weight'))
                            Expanded(
                              child: _buildInputField(
                                label: 'Cân nặng (kg)',
                                controller: _controllers['weight']!,
                                placeholder: '60',
                              ),
                            ),
                          if (_controllers.containsKey('weight') && _controllers.containsKey('height'))
                            const SizedBox(width: 8),
                          if (_controllers.containsKey('height'))
                            Expanded(
                              child: _buildInputField(
                                label: 'Chiều cao (cm)',
                                controller: _controllers['height']!,
                                placeholder: '170',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Lưu kết quả',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
