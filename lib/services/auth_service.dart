// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';

class AuthService with ChangeNotifier {
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;
  bool _initialized = false;
  String? _initError;
  
  AuthService() {
    _initializeAuth();
    // initialize notification service (fire-and-forget)
    NotificationService().init();
  }
  
  /// Inisialisasi FirebaseAuth dan GoogleSignIn
  /// Dijalankan di constructor untuk memastikan semua service siap digunakan
  /// Set _initialized = true jika sukses, dan simpan error jika gagal
  void _initializeAuth() {
    try {
      _auth = FirebaseAuth.instance;
      
      // GoogleSignIn hanya untuk non-web (web menggunakan redirect flow)
      if (!kIsWeb) {
        _googleSignIn = GoogleSignIn();
      }
      
      _initialized = true;
      _initError = null;
      if (kDebugMode) print('AuthService initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Error initializing AuthService: $e');
      _initialized = false;
      _initError = e.toString();
    }
  }
  
  bool get isInitialized => _initialized;
  String? get initError => _initError;
  
  /// Stream yang mendengarkan perubahan auth state dari Firebase
  /// Mengembalikan User? (null jika belum login)
  /// Digunakan untuk menentukan UI yang ditampilkan (LoginScreen atau HomeScreen)
  Stream<User?> get user {
    try {
      if (!_initialized) {
        return Stream.value(null);
      }
      return _auth.authStateChanges();
    } catch (e) {
      if (kDebugMode) print('Error in user stream: $e');
      return Stream.value(null);
    }
  }
  
  /// Login menggunakan email dan password
  /// Melemparkan error jika email/password salah atau tidak terdaftar
  /// Mengembalikan User jika sukses
  Future<User?> login(String email, String password) async {
    if (!_initialized) {
      throw Exception('Auth service not initialized');
    }
    
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        await NotificationService().showImmediateNotification(
          'Login Berhasil',
          'Selamat datang ${result.user?.email ?? ''}',
        );
      } catch (_) {}
      return result.user;
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      rethrow;
    }
  }
  
  /// Daftar akun baru dengan email, password, dan nama
  /// Update displayName setelah akun dibuat
  /// Melemparkan error jika email sudah terdaftar atau format tidak valid
  Future<User?> register(String email, String password, String name) async {
    if (!_initialized) {
      throw Exception('Auth service not initialized');
    }
    
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set nama pengguna untuk profile Firebase
      await result.user?.updateDisplayName(name);
      try {
        await NotificationService().showImmediateNotification(
          'Akun Dibuat',
          'Halo $name, akun berhasil dibuat',
        );
      } catch (_) {}
      return result.user;
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      rethrow;
    }
  }
  
  /// Logout user dari Firebase Authentication
  /// Juga sign out dari GoogleSignIn jika bukan web platform
  /// Triggered saat user klik logout di home screen
  Future<void> logout() async {
    if (!_initialized) return;
    
    try {
      await _auth.signOut();
      
      // GoogleSignIn hanya untuk non-web
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      try {
        await NotificationService().showImmediateNotification(
          'Logout',
          'Kamu telah logout',
        );
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('Logout error: $e');
      rethrow;
    }
  }
  
  User? getCurrentUser() {
    if (!_initialized) return null;
    return _auth.currentUser;
  }
}