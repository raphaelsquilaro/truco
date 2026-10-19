import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class AppUser {
  final String id;
  final String? email;
  final String displayName;
  final String avatar;
  final bool isAnonymous;

  const AppUser({
    required this.id,
    this.email,
    required this.displayName,
    this.avatar = '🤠',
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatar': avatar,
      'isAnonymous': isAnonymous,
    };
  }
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth? _firebaseAuth;
  final StreamController<AppUser?> _userStreamController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  Stream<AppUser?> get userStream => _userStreamController.stream;

  AuthService()
      : _firebaseAuth = FirebaseService.instance.isInitialized
            ? FirebaseAuth.instance
            : null {
    _initAuthListener();
  }

  void _initAuthListener() {
    if (_firebaseAuth != null) {
      _firebaseAuth.authStateChanges().listen((user) {
        if (user != null) {
          _currentUser = AppUser(
            id: user.uid,
            email: user.email,
            displayName: user.displayName ?? user.email?.split('@').first ?? 'Truqueiro',
            isAnonymous: user.isAnonymous,
          );
        } else {
          _currentUser = null;
        }
        _userStreamController.add(_currentUser);
        notifyListeners();
      });
    }
  }

  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    if (_firebaseAuth != null) {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      _currentUser = AppUser(
        id: user.uid,
        email: user.email,
        displayName: user.displayName ?? email.split('@').first,
      );
      _userStreamController.add(_currentUser);
      notifyListeners();
      return _currentUser!;
    } else {
      // Local fallback mode when Firebase isn't initialized yet
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = AppUser(
        id: 'local_${email.hashCode.abs()}',
        email: email.trim(),
        displayName: email.split('@').first,
      );
      _userStreamController.add(_currentUser);
      notifyListeners();
      return _currentUser!;
    }
  }

  Future<AppUser> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final cleanName = displayName.trim().isEmpty ? 'Truqueiro' : displayName.trim();

    if (_firebaseAuth != null) {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(cleanName);
      _currentUser = AppUser(
        id: user.uid,
        email: user.email,
        displayName: cleanName,
      );
      _userStreamController.add(_currentUser);
      notifyListeners();
      return _currentUser!;
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = AppUser(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        displayName: cleanName,
      );
      _userStreamController.add(_currentUser);
      notifyListeners();
      return _currentUser!;
    }
  }

  Future<AppUser> signInAnonymously([String? displayName]) async {
    final cleanName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : 'Convidado_${(DateTime.now().millisecondsSinceEpoch % 1000)}';

    if (_firebaseAuth != null) {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user!;
      await user.updateDisplayName(cleanName);
      _currentUser = AppUser(
        id: user.uid,
        displayName: cleanName,
        isAnonymous: true,
      );
      _userStreamController.add(_currentUser);
      notifyListeners();
      return _currentUser!;
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentUser = AppUser(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: cleanName,
        isAnonymous: true,
      );
      _userStreamController.add(_currentUser);
      notifyListeners();
      return _currentUser!;
    }
  }

  Future<void> signOut() async {
    if (_firebaseAuth != null) {
      await _firebaseAuth.signOut();
    }
    _currentUser = null;
    _userStreamController.add(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _userStreamController.close();
    super.dispose();
  }
}

