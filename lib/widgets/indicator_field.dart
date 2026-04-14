import 'package:flutter/material.dart';

class IndicatorField extends StatelessWidget {
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

  Color _getStatusColor(String text) {
    if (text.isEmpty) return Colors.grey;
    final value = double.tryParse(text);
    if (value == null) return Colors.grey;
    if (min != null && value < min!) return Colors.orange;
    if (max != null && value > max!) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (min != null && max != null)
                Text('BT: $min - $max $unit', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _getStatusColor(controller.text)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _getStatusColor(controller.text), width: 2),
              ),
            ),
            onChanged: (value) {
              if (onChanged != null) {
                final d = double.tryParse(value);
                if (d != null) onChanged!(d);
              }
            },
          ),
        ],
      ),
    );
  }
}
