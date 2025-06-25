import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/student_provider.dart';
import 'providers/performance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/section_provider.dart';
import 'screens/auth/splash_screen.dart'; // Import the SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => SectionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sabaq Tracker',
        theme: ThemeData(
          // Define a custom color scheme
          colorScheme: ColorScheme.light(
            // Use light theme
            primary: Colors.teal.shade700, // A calming primary color
            onPrimary: Colors.white,
            primaryContainer: Colors.teal.shade100,
            onPrimaryContainer: Colors.teal.shade900,
            secondary: Colors.cyan.shade600, // A complementary accent color
            onSecondary: Colors.white,
            secondaryContainer: Colors.cyan.shade100,
            onSecondaryContainer: Colors.cyan.shade900,
            surface: Colors.white, // Background for cards, sheets etc.
            onSurface: Colors.black87,
            background: Colors.teal.shade50, // Light background
            onBackground: Colors.black87,
            error: Colors.red.shade700, // Error color
            onError: Colors.white,
          ),
          // Define typography
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ), // For AppBar titles
            bodyMedium: TextStyle(fontSize: 14.0), // Default text
          ),
          // Customize AppBar theme
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white, // Color of icons and title
            centerTitle: true, // Center the title by default
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: const IconThemeData(
              color: Colors.white, // Color of the back button and other icons
            ),
          ),
          // Customize ElevatedButton theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Customize Input Decoration theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none, // No border initially
            ),
            filled: true,
            fillColor: Colors.teal.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 15,
            ),
            hintStyle: TextStyle(color: Colors.teal.shade700.withOpacity(0.6)),
            labelStyle: TextStyle(color: Colors.teal.shade700),
          ),

          useMaterial3: true,
        ),
        home: const SplashScreen(), // Set SplashScreen as the home widget
      ),
    );
  }
}
