import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? fullName;
  String? userName;
  String? email;
  String? message;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print("📦 Token ne geldi: $token");

    if (token == null) {
      _logout(); // Token yoksa login’e yönlendir
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("${dotenv.env['API_BASE_URL']}/api/dashboard"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final user = data["user"];

        setState(() {
          fullName = user["fullName"] ?? "-";
          userName = user["userName"] ?? "-";
          email = user["email"] ?? "-";
          message = data["message"] ?? "Hoş geldin!";
          isLoading = false;
        });
      } else {
        _logout(); // Token geçersizse logout
      }
    } catch (e) {
      debugPrint("❌ Hata: $e");
      _logout(); // Hata olursa logout
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👋 $message",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  Text("👤 Ad Soyad: $fullName",
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("📛 Kullanıcı Adı: @$userName",
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("📧 Email: $email",
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
    );
  }
}
