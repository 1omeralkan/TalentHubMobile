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
    final picked = await picker.pickImage(
        source: ImageSource.gallery); // İsteğe bağlı: ImageSource.camera

    if (picked != null) {
      setState(() {
        _file = File(picked.path);
      });
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
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

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
    return Scaffold(
      appBar: AppBar(title: const Text("Yetenek Yükle")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickMedia,
              child: const Text("📂 Dosya Seç"),
            ),
            if (_file != null) ...[
              const SizedBox(height: 16),
              Image.file(_file!, height: 150),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: "Açıklama",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _upload,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("🚀 Gönder"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
