import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:todo_list_app/firebase_options.dart';
import 'package:todo_list_app/services/auth_service.dart';
import 'package:todo_list_app/services/firestore_service.dart';
import 'package:todo_list_app/services/notification_service.dart';
import 'package:todo_list_app/screens/auth/login_screen.dart';  
import 'package:todo_list_app/screens/home_screen.dart';

void main() async {
  // Pastikan Flutter binding diinisialisasi sebelum akses platform-specific code
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Firebase dengan konfigurasi platform-specific
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Initialize notification service (local notifications)
  try {
    await NotificationService().init();
    debugPrint('NotificationService initialized');
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Sediakan AuthService dan FirestoreService ke seluruh widget tree
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Todo List App',
        // Tema aplikasi dengan warna vibrant (purple primary, cyan FAB)
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C3AED), 
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF9F6FB),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF6D28D9),
            iconTheme: const IconThemeData(color: Color(0xFF6D28D9)),
            titleTextStyle: const TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF06B6D4), // Vibrant cyan
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 8,
            enableFeedback: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), // Purple
              foregroundColor: Colors.white,
              elevation: 6,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
          ),
        ),
        // AuthWrapper menentukan apakah user sudah login atau belum
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    debugPrint('AuthWrapper initialized');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building AuthWrapper');
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Jika Firebase belum terinialisasi, tampilkan error screen
      if (!authService.isInitialized) {
        final errorMsg = authService.initError ?? 'Firebase initialization failed';
        
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 64),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Firebase Initialization Error',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    errorMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      // StreamBuilder mendengarkan perubahan auth state dari Firebase
      return StreamBuilder<User?>(
        stream: authService.user,
        builder: (context, snapshot) {
          debugPrint('StreamBuilder - ConnectionState: ${snapshot.connectionState}');
          debugPrint('StreamBuilder - HasData: ${snapshot.hasData}');
          debugPrint('StreamBuilder - Data: ${snapshot.data}');
          debugPrint('StreamBuilder - Error: ${snapshot.error}');
          
          // Tampilkan loading indicator saat Firebase menghubungkan
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Showing loading...');
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          }
          
          // Tampilkan error jika ada masalah koneksi Firebase
          if (snapshot.hasError) {
            debugPrint('Showing error: ${snapshot.error}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 20),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Jika user sudah login, tampilkan HomeScreen
          if (snapshot.hasData && snapshot.data != null) {
            debugPrint('User logged in: ${snapshot.data?.email}');
            return HomeScreen(user: snapshot.data!);
          }
          
          // Jika user belum login, tampilkan LoginScreen
          debugPrint('No user, showing login');
          return const LoginScreen();
        },
      );
    } catch (e) {
      debugPrint('Exception in build: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              Text('Exception: $e'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
