import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class IndicatorField extends StatefulWidget {
  final String label;
  final String unit;
  final double? min;
  final double? max;
  final TextEditingController controller;
  final Function(double)? onChanged;

  const IndicatorField({
    super.key,
    required this.label,
    required this.unit,
    this.min,
    this.max,
    required this.controller,
    this.onChanged,
  });

  @override
  State<IndicatorField> createState() => _IndicatorFieldState();
}

class _IndicatorFieldState extends State<IndicatorField> {
  Color _getStatusColor(String text) {
    if (text.isEmpty) return AppTheme.borderColor;
    final value = double.tryParse(text);
    if (value == null) return AppTheme.borderColor;
    if (widget.min != null && value < widget.min!) return AppTheme.warningColor;
    if (widget.max != null && value > widget.max!) return AppTheme.criticalColor;
    return AppTheme.normalColor;
  }

  String _getStatusLabel(String text) {
    if (text.isEmpty) return '';
    final value = double.tryParse(text);
    if (value == null) return '';
    if (widget.min != null && value < widget.min!) return 'Thấp';
    if (widget.max != null && value > widget.max!) return 'Cao';
    return 'Bình thường';
  }

  IconData _getStatusIcon(String text) {
    if (text.isEmpty) return Icons.remove;
    final value = double.tryParse(text);
    if (value == null) return Icons.remove;
    if (widget.min != null && value < widget.min!) return Icons.arrow_downward_rounded;
    if (widget.max != null && value > widget.max!) return Icons.arrow_upward_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.controller.text);
    final statusLabel = _getStatusLabel(widget.controller.text);
    final hasValue = widget.controller.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? statusColor.withValues(alpha: 0.4)
              : AppTheme.borderColor.withValues(alpha: 0.4),
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (hasValue)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
              if (widget.min != null && widget.max != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.min} – ${widget.max} ${widget.unit}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? statusColor : AppTheme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    suffixText: widget.unit,
                    suffixStyle: TextStyle(
                      color: AppTheme.mutedTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasValue
                            ? statusColor.withValues(alpha: 0.3)
                            : AppTheme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: hasValue
                        ? statusColor.withValues(alpha: 0.04)
                        : AppTheme.surfaceColor,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (widget.onChanged != null) {
                      final d = double.tryParse(value);
                      if (d != null) widget.onChanged!(d);
                    }
                  },
                ),
              ),
              if (hasValue && statusLabel.isNotEmpty) ...[
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(widget.controller.text),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
