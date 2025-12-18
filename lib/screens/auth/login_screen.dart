import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list_app/services/auth_service.dart';
// import 'package:todo_list_app/services/notification_service.dart';
import 'package:todo_list_app/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // clear previous server-side errors
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    // Check if Firebase is initialized
    if (!authService.isInitialized) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase Error: ${authService.initError ?? "Unknown error"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login gagal. Periksa email dan password Anda.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
        if (e is FirebaseAuthException) {
          if (!mounted) return;
          setState(() => _isLoading = false);

          // If user not found, show a dialog suggesting registration
          if (e.code == 'user-not-found') {
            setState(() => _emailError = 'Email tidak terdaftar');
            final goRegister = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Email tidak terdaftar'),
                content: const Text('Email ini belum terdaftar. Apakah Anda ingin membuat akun sekarang?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Daftar')),
                ],
              ),
            );

            if (goRegister == true) {
              if (!mounted) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
            }

            return;
          }

          switch (e.code) {
            case 'wrong-password':
              setState(() => _passwordError = 'Password Anda salah');
              break;
            case 'invalid-email':
              setState(() => _emailError = 'Format email tidak valid');
              break;
            case 'user-disabled':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Akun ini telah dinonaktifkan'), backgroundColor: Colors.red),
              );
              break;
            case 'too-many-requests':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terlalu banyak percobaan. Coba lagi nanti.'), backgroundColor: Colors.red),
              );
              break;
            default:
              // Generic user-friendly message instead of raw technical error
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login gagal. Periksa email dan password Anda.'),
                  backgroundColor: Colors.red,
                ),
              );
          }
        } else {
          // Handle other exceptions
          if (!mounted) return;
          setState(() => _isLoading = false);

          // Show a consistent friendly message for unexpected errors
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login gagal. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // App logo (place your downloaded icon at assets/icons/todo.png)
              Center(
                child: Image.asset(
                  'assets/icons/todo.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.check_box_outlined,
                    size: 96,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: 'Selamat Datang! ',
                      style: TextStyle(color: Colors.blue),
                    ),
                    TextSpan(
                      text: 'MindTask App',
                      style: TextStyle(color: Colors.purple),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  children: const [
                    TextSpan(text: 'Siap untuk lebih produktif? Pindahkan beban pikiran Anda ke '),
                    TextSpan(
                      text: 'MindTask', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    TextSpan(text: ' dan mulai eksekusi sekarang.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              /// FORM LOGIN
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        errorText: _emailError,
                      ),
                      onChanged: (v) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      onChanged: (v) {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    /// BUTTON LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              /// LINK REGISTER
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('Belum punya akun? Daftar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
