class HealthConstants {
  // Blood Test Indicators
  static const Map<String, dynamic> bloodIndicators = {
    'glucose': {'name': 'Glucose', 'unit': 'mmol/L', 'min': 3.9, 'max': 6.4},
    'cholesterol': {
      'name': 'Cholesterol',
      'unit': 'mmol/L',
      'min': 0.0,
      'max': 5.2,
    },
    'hdl': {'name': 'HDL', 'unit': 'mmol/L', 'min': 1.0, 'max': 2.0},
    'ldl': {'name': 'LDL', 'unit': 'mmol/L', 'min': 0.0, 'max': 3.4},
    'triglycerides': {
      'name': 'Triglycerides',
      'unit': 'mmol/L',
      'min': 0.0,
      'max': 1.7,
    },
  };

  // Vital Signs
  static const Map<String, dynamic> vitalsIndicators = {
    'systolic': {
      'name': 'Huyết áp tâm thu',
      'unit': 'mmHg',
      'min': 90,
      'max': 120,
    },
    'diastolic': {
      'name': 'Huyết áp tâm trương',
      'unit': 'mmHg',
      'min': 60,
      'max': 80,
    },
    'heart_rate': {'name': 'Nhịp tim', 'unit': 'bpm', 'min': 60, 'max': 100},
    'spO2': {'name': 'SpO2', 'unit': '%', 'min': 95, 'max': 100},
  };

  // Body Metrics
  static const Map<String, dynamic> bodyIndicators = {
    'weight': {'name': 'Cân nặng', 'unit': 'kg', 'min': 40, 'max': 100},
    'height': {'name': 'Chiều cao', 'unit': 'cm', 'min': 100, 'max': 250},
  };

  static const Map<String, dynamic> scanIndicators = {
    ...bloodIndicators,
    ...vitalsIndicators,
    ...bodyIndicators,
  };
}
