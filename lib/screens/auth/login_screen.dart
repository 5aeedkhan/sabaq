import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../students/student_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        debugPrint(
          'Attempting to sign in with email: ${_emailController.text.trim()}',
        );

        // First, try to sign out any existing user
        await FirebaseAuth.instance.signOut();

        // Then attempt to sign in
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Wait for auth state to settle
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check if we have a valid user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Authentication failed - no user found');
        }

        debugPrint('Successfully authenticated user: ${user.email}');

        if (mounted) {
          // Navigate to student list screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentListScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage =
                  'No user found with this email. Please register first.';
              break;
            case 'wrong-password':
              _errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'invalid-email':
              _errorMessage = 'Please enter a valid email address.';
              break;
            case 'user-disabled':
              _errorMessage =
                  'This account has been disabled. Please contact support.';
              break;
            case 'too-many-requests':
              _errorMessage =
                  'Too many failed attempts. Please try again later.';
              break;
            default:
              _errorMessage = e.message ?? 'An error occurred during login.';
          }
        });
      } catch (e) {
        debugPrint('General Error during login: $e');

        // If we get the PigeonUserDetails error, try a different approach
        if (e.toString().contains('PigeonUserDetails')) {
          try {
            debugPrint('Attempting alternative login method');

            // Try to get the current user directly
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              debugPrint('Found authenticated user: ${user.email}');
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentListScreen(),
                  ),
                  (route) => false,
                );
                return;
              }
            }
          } catch (retryError) {
            debugPrint('Alternative login failed: $retryError');
          }
        }

        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Image.asset('assets/logo.png', width: 200, height: 200),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final TextEditingController resetEmailController = TextEditingController();
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Reset Password'),
                            content: TextField(
                              controller: resetEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Enter your email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final email = resetEmailController.text.trim();
                                  if (email.isEmpty || !email.contains('@')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid email.')),
                                    );
                                    return;
                                  }
                                  try {
                                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
                                    );
                                    Navigator.of(context).pop(true);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: \\${e.toString()}')),
                                    );
                                  }
                                },
                                child: const Text('Send'),
                              ),
                            ],
                          );
                        },
                      );
                      // If cancelled, just return to login screen (do nothing)
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
