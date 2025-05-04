import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _file;
  final TextEditingController _captionController = TextEditingController();
  bool isLoading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _file = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir dosya seçin.")),
      );
      return;
    }

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final uri = Uri.parse("${dotenv.env['API_BASE_URL']}/api/upload");
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = "Bearer $token";

    request.files.add(await http.MultipartFile.fromPath('media', _file!.path));
    request.fields['caption'] = _captionController.text;

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Yükleme başarılı!")),
      );
      setState(() {
        _file = null;
        _captionController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Yükleme başarısız!")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF00E0E0);
    const Color accent = Color(0xFFFF2C5D);
    const Color textColor = Color(0xFF212530);
    const Color background = Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text("Yetenek Yükle", style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.folder_open),
                label: const Text("Dosya Seç"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              if (_file != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _file!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: "Yetenek açıklaması giriniz...",
                  alignLabelWithHint: true,
                  labelStyle: const TextStyle(color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("🚀 Gönder"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
