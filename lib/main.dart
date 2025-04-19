import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:talenthub_mobilee/pages/splash_page.dart';
import 'package:talenthub_mobilee/pages/login_page.dart';
import 'package:talenthub_mobilee/pages/register_page.dart';
import 'package:talenthub_mobilee/pages/dashboard_page.dart';
import 'package:talenthub_mobilee/pages/forgot_password_page.dart';
import 'package:talenthub_mobilee/pages/reset_password_page.dart'; // ✅ yeni sayfa
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TalentHub Mobile',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) {
          final token = Uri.base.queryParameters['token'];
          return token == null
              ? const Scaffold(
                  body: Center(child: Text("Geçersiz veya eksik bağlantı.")),
                )
              : ResetPasswordPage(token: token);
        },
      },
    );
  }
}
