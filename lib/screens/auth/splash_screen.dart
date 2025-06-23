import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../students/student_list_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      debugPrint('Starting authentication check');
      await Future.delayed(const Duration(milliseconds: 2000)); // 2 seconds delay
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      debugPrint('Current user: \\${user?.email}');

      if (mounted) {
        if (user != null) {
          debugPrint('Navigating to student list screen');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentListScreen()),
            (route) => false,
          );
        } else {
          debugPrint('Navigating to login screen');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error in auth check: \\${e}');
      // If there's any error, navigate to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 120, // Adjust size as needed
              height: 120,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 