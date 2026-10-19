import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Safely initializes Firebase, gracefully catching configurations where
  /// google-services.json or FirebaseOptions hasn't been generated yet.
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        return;
      }
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('[FirebaseService] Firebase inicializado com sucesso.');
    } catch (e) {
      _isInitialized = false;
      debugPrint(
        '[FirebaseService] Firebase não configurado localmente ($e). '
        'Iniciando no modo híbrido/offline resiliente.',
      );
    }
  }
}

