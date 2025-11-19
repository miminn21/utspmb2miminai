import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Mimin AI',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF6366F1),
            scaffoldBackgroundColor: const Color(0xFFF8FAFD),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF1F2937)),
            ),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: MaterialColor(0xFF6366F1, {
                50: Color(0xFFEEF2FF),
                100: Color(0xFFE0E7FF),
                200: Color(0xFFC7D2FE),
                300: Color(0xFFA5B4FC),
                400: Color(0xFF818CF8),
                500: Color(0xFF6366F1),
                600: Color(0xFF4F46E5),
                700: Color(0xFF4338CA),
                800: Color(0xFF3730A3),
                900: Color(0xFF312E81),
              }),
            ).copyWith(secondary: Color(0xFF8B5CF6)),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF6366F1),
            scaffoldBackgroundColor: const Color(0xFF0A0E21),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1F35),
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSwatch(
              brightness: Brightness.dark,
              primarySwatch: MaterialColor(0xFF6366F1, {
                50: Color(0xFFEEF2FF),
                100: Color(0xFFE0E7FF),
                200: Color(0xFFC7D2FE),
                300: Color(0xFFA5B4FC),
                400: Color(0xFF818CF8),
                500: Color(0xFF6366F1),
                600: Color(0xFF4F46E5),
                700: Color(0xFF4338CA),
                800: Color(0xFF3730A3),
                900: Color(0xFF312E81),
              }),
            ).copyWith(secondary: Color(0xFF8B5CF6)),
          ),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Tampilkan loading screen saat mengecek status login
    if (authProvider.isLoading) {
      return _buildLoadingScreen();
    }

    // Jika sudah login, arahkan ke ChatScreen
    if (authProvider.isLoggedIn) {
      return const ChatScreen();
    }

    // Jika belum login, arahkan ke LoginScreen
    return const LoginScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mimin AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
