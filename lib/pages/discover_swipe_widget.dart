import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/video_player_widget.dart';

class DiscoverSwipeWidget extends StatefulWidget {
  const DiscoverSwipeWidget({Key? key}) : super(key: key);

  @override
  State<DiscoverSwipeWidget> createState() => _DiscoverSwipeWidgetState();
}

class _DiscoverSwipeWidgetState extends State<DiscoverSwipeWidget> {
  List<dynamic> videos = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    try {
      final res = await http.get(
        Uri.parse("${dotenv.env['API_BASE_URL']}/api/explore"),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Sadece video olanları filtrele (mp4, mov, avi, mkv)
        List<dynamic> onlyVideos = data.where((item) {
          final url = item['mediaUrl']?.toString().toLowerCase() ?? '';
          return url.endsWith('.mp4') ||
              url.endsWith('.mov') ||
              url.endsWith('.avi') ||
              url.endsWith('.mkv');
        }).toList();
        onlyVideos.shuffle(); // Random sırala
        setState(() {
          videos = onlyVideos;
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bir hata oluştu.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: fetchVideos,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    if (videos.isEmpty) {
      return const Center(child: Text('Hiç video yok.'));
    }
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final String videoUrl =
            "${dotenv.env['API_BASE_URL']}${video['mediaUrl']}";
        final String caption = video['caption'] ?? '';
        final userObj = video['user'];
        final String username =
            userObj?['userName'] ?? userObj?['username'] ?? 'Bilinmeyen';
        final String? profilePic =
            userObj?['profilePic']; // Profil fotoğrafı varsa
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Video
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: VideoPlayerWidget(url: videoUrl),
                    ),
                  ),
                  // Kullanıcı adı: sol alt köşe, küçük, sade, arka plansız
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  ),
                  // Açıklama: kullanıcı adının hemen altında, küçük ve sade
                  if (caption.isNotEmpty)
                    Positioned(
                      left: 12,
                      bottom: 32,
                      right: 12,
                      child: Text(
                        caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 2)
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
