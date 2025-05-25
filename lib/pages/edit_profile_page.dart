import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talenthub_mobilee/providers/auth_provider.dart';
import 'dart:convert';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  File? _profileImage;
  bool _isUploading = false;

  Future<Map<String, dynamic>?> fetchUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['user'];
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_profileImage == null) return;
    setState(() => _isUploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş yapmanız gerekiyor.")),
        );
        setState(() => _isUploading = false);
        return;
      }
      final uri = Uri.parse("${dotenv.env['API_BASE_URL']}/api/profile-photo");
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = "Bearer $token";
      request.files
          .add(await http.MultipartFile.fromPath('media', _profileImage!.path));
      // Profil fotoğrafı için caption göndermiyoruz
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil fotoğrafı başarıyla yüklendi!")),
        );
        // Kullanıcı bilgisini güncelle
        final userInfo = await fetchUserInfo(token);
        if (userInfo != null) {
          if (mounted) {
            ref.read(userProvider.notifier).state = userInfo;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yükleme başarısız: $respStr")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProfilePhoto() async {
    setState(() => _isUploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş yapmanız gerekiyor.")),
        );
        setState(() => _isUploading = false);
        return;
      }
      final uri = Uri.parse("${dotenv.env['API_BASE_URL']}/api/profile-photo");
      final response = await http.delete(uri, headers: {
        "Authorization": "Bearer $token",
      });
      if (response.statusCode == 200) {
        setState(() {
          _profileImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil fotoğrafı silindi!")),
        );
        // Kullanıcı bilgisini güncelle
        final userInfo = await fetchUserInfo(token);
        if (userInfo != null) {
          if (mounted) {
            ref.read(userProvider.notifier).state = userInfo;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme başarısız: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 36),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(userProvider);
                    return CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (user?['profilePhotoUrl'] != null
                              ? NetworkImage(
                                      '${dotenv.env['API_BASE_URL']}${user!['profilePhotoUrl']}?v=${DateTime.now().millisecondsSinceEpoch}')
                                  as ImageProvider
                              : null),
                      child: _profileImage == null &&
                              (user?['profilePhotoUrl'] == null)
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.grey)
                          : null,
                    );
                  },
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.black87, size: 22),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Profil fotoğrafını değiştirmek için daireye tıkla',
                style: TextStyle(fontSize: 15)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _profileImage == null || _isUploading
                  ? null
                  : _uploadProfilePhoto,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _deleteProfilePhoto,
              icon: const Icon(Icons.delete),
              label: const Text('Profil Fotoğrafını Sil'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
