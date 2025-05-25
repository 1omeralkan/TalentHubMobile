import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talenthub_mobilee/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:talenthub_mobilee/services/api_service.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshUserInfo();
  }

  Future<void> _refreshUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token != null) {
      final userInfo = await ApiService().fetchUserInfo(token);
      if (userInfo != null && mounted) {
        ref.read(userProvider.notifier).state = userInfo;
        print('userProvider: ' + userInfo.toString());
        print('Profil fotoğrafı URL: ' +
            (userInfo['profilePhotoUrl'] != null
                ? '${dotenv.env['API_BASE_URL']}${userInfo['profilePhotoUrl']}?v=${DateTime.now().millisecondsSinceEpoch}'
                : 'YOK'));
      }
    }
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

  void _openMediaDetail(BuildContext context, String mediaUrl, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaDetailPage(mediaUrl: mediaUrl, isVideo: isVideo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Renkler ve stiller
    const Color primary = Color(0xFF00E0E0);
    const Color accent = Color(0xFFFF2C5D);
    const Color textColor = Color(0xFF212530);
    const Color background = Color(0xFFF0F0F0);

    final user = ref.watch(userProvider);
    print("userProvider içeriği: $user");

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text("Profil", style: TextStyle(color: textColor)),
        iconTheme: const IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profil üst kısmı: fotoğraf + sayılar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profil fotoğrafı baloncuğu
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/edit-profile');
                          },
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: primary.withOpacity(0.15),
                            backgroundImage: user?['profilePhotoUrl'] != null
                                ? NetworkImage(
                                    '${dotenv.env['API_BASE_URL']}${user!['profilePhotoUrl']}?v=${DateTime.now().millisecondsSinceEpoch}')
                                : null,
                            child: user?['profilePhotoUrl'] == null
                                ? const Icon(Icons.person,
                                    size: 44, color: Color(0xFFB0B0B0))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 28),
                        // Gönderi, Takipçi, Takip
                        Row(
                          children: [
                            Column(
                              children: const [
                                Text('4',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                SizedBox(height: 2),
                                Text('Gönderi', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                            SizedBox(width: 18),
                            Column(
                              children: const [
                                Text('0',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                SizedBox(height: 2),
                                Text('Takipçi', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                            SizedBox(width: 18),
                            Column(
                              children: const [
                                Text('0',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                SizedBox(height: 2),
                                Text('Takip', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("👤 ${user?['fullName'] ?? '-'}",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        const SizedBox(height: 4),
                        Text("📛 @${user?['userName'] ?? '-'}",
                            style: const TextStyle(color: accent)),
                        const SizedBox(height: 2),
                        Text("📧 ${user?['email'] ?? '-'}",
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Icon(Icons.bolt, color: accent, size: 22),
                      SizedBox(width: 8),
                      Text("Yüklenen Yetenekler:",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio:
                              0.8, // Daha kareye yakın ve eşit oran
                        ),
                        itemCount: userUploads.length,
                        itemBuilder: (context, index) {
                          final item = userUploads[index];
                          final mediaUrl =
                              "${dotenv.env['API_BASE_URL']}${item["mediaUrl"]}";
                          final isImg = isImage(mediaUrl);
                          final isVid = isVideo(mediaUrl);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                _openMediaDetail(context, mediaUrl, isVid);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: SizedBox.expand(
                                        child: isImg
                                            ? Image.network(
                                                mediaUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : isVid
                                                ? VideoThumbnailWidget(
                                                    videoUrl: mediaUrl,
                                                    borderRadius: 18,
                                                    forceFill: true,
                                                  )
                                                : const Center(
                                                    child: Icon(
                                                        Icons.insert_drive_file,
                                                        size: 32)),
                                      ),
                                    ),
                                    // Sağ üstte üç nokta menüsü
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'delete') {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title:
                                                    const Text('Yetenek Sil'),
                                                content: const Text(
                                                    'Bu yeteneği silmek istediğine emin misin?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child: const Text('Vazgeç'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: const Text('Sil'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              final prefs =
                                                  await SharedPreferences
                                                      .getInstance();
                                              final token =
                                                  prefs.getString("token");
                                              final res = await http.delete(
                                                Uri.parse(
                                                    "${dotenv.env['API_BASE_URL']}/api/uploads/${item['id']}"),
                                                headers: {
                                                  "Authorization":
                                                      "Bearer $token"
                                                },
                                              );
                                              if (res.statusCode == 200) {
                                                setState(() {
                                                  userUploads.removeAt(index);
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Yetenek silindi.')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Silme başarısız!')),
                                                );
                                              }
                                            }
                                          } else if (value == 'edit') {
                                            // Düzenle özelliği için altyapı (şimdilik boş)
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Düzenle'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

// Tam ekran medya detay sayfası
class MediaDetailPage extends StatelessWidget {
  final String mediaUrl;
  final bool isVideo;
  const MediaDetailPage(
      {Key? key, required this.mediaUrl, required this.isVideo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: isVideo
            ? _FullScreenVideoPlayer(url: mediaUrl)
            : InteractiveViewer(
                child: Image.network(mediaUrl, fit: BoxFit.contain),
              ),
      ),
    );
  }
}

class _FullScreenVideoPlayer extends StatefulWidget {
  final String url;
  const _FullScreenVideoPlayer({Key? key, required this.url}) : super(key: key);

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url);
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
        child:
            Text("⚠️ Video yüklenemedi", style: TextStyle(color: Colors.white)),
      );
    }
    if (!_isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

// Video için ilk frame'den thumbnail gösteren widget
class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double borderRadius;
  final bool forceFill;

  const VideoThumbnailWidget(
      {Key? key,
      required this.videoUrl,
      this.borderRadius = 14,
      this.forceFill = false})
      : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.pause(); // İlk frame'de dursun
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              widget.forceFill
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
              const Icon(Icons.play_circle_fill,
                  size: 48, color: Colors.white70),
            ],
          )
        : Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          );
  }
}
