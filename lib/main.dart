import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    initError = e;
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    initError != null
        ? MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Firebase initialization failed:\n$initError',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        : MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => AuthService())],
            child: const HealthApp(),
          ),
  );
}
