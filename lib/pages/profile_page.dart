import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talenthub_mobilee/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  List<dynamic> userUploads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserUploads();
  }

  Future<void> fetchUserUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse("${dotenv.env['API_BASE_URL']}/api/my-uploads"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          userUploads = data["uploads"];
          isLoading = false;
        });
      } else {
        debugPrint("Yüklemeler alınamadı: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("⛔ Hata: $e");
    }
  }

  bool isImage(String url) {
    final ext = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  bool isVideo(String url) {
    final ext = url.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 ${user?['fullName'] ?? '-'}",
                      style: const TextStyle(fontSize: 18)),
                  Text("📛 @${user?['userName'] ?? '-'}"),
                  Text("📧 ${user?['email'] ?? '-'}"),
                  const SizedBox(height: 20),
                  const Text("🎯 Yüklenen Yetenekler:",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: userUploads.length,
                      itemBuilder: (context, index) {
                        final item = userUploads[index];
                        final mediaUrl =
                            "${dotenv.env['API_BASE_URL']}${item["mediaUrl"]}";
                        final caption = item["caption"] ?? "Açıklama yok";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isImage(mediaUrl))
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    mediaUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (isVideo(mediaUrl))
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: SizedBox(
                                    height: 250,
                                    width: double.infinity,
                                    child:
                                        VideoPlayerWidget(videoUrl: mediaUrl),
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text("🎞 Dosya önizlemesi yok"),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(caption),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ✅ Video gösterimi için ayrı widget
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("⚠️ Video yüklenemedi"),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
