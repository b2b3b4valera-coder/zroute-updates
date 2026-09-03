import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

import 'package:audioplayers/audioplayers.dart';

import '../utils/helpers.dart'; // Подключаем скачивание файлов



// --- ВИДЕОПЛЕЕР ---

class VideoPlayerDialog extends StatefulWidget {

  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});



  @override

  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();

}



class _VideoPlayerDialogState extends State<VideoPlayerDialog> {

  late VideoPlayerController _controller;

  bool _isInitialized = false;



  @override

  void initState() {

    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))

      ..initialize().then((_) {

        setState(() => _isInitialized = true);

        _controller.play();

      });

  }



  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Dialog(

      backgroundColor: Colors.black,

      insetPadding: const EdgeInsets.all(12),

      child: Stack(

        alignment: Alignment.center,

        children: [

          if (_isInitialized)

            AspectRatio(

              aspectRatio: _controller.value.aspectRatio,

              child: Stack(

                alignment: Alignment.bottomCenter,

                children: [

                  VideoPlayer(_controller),

                  VideoProgressIndicator(_controller, allowScrubbing: true),

                  Center(

                    child: IconButton(

                      icon: Icon(

                        _controller.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,

                        color: Colors.white.withOpacity(0.8),

                        size: 56,

                      ),

                      onPressed: () {

                        setState(() {

                          _controller.value.isPlaying ? _controller.pause() : _controller.play();

                        });

                      },

                    ),

                  ),

                ],

              ),

            )

          else

            const SizedBox(

              height: 200,

              child: Center(child: CircularProgressIndicator(color: Colors.white)),

            ),

          Positioned(

            top: 10,

            right: 10,

            child: Row(

              children: [

                IconButton(

                  icon: const Icon(Icons.download, color: Colors.white, size: 28),

                  tooltip: 'Скачать видео',

                  onPressed: () => downloadMediaFile(context, widget.videoUrl),

                ),

                IconButton(

                  icon: const Icon(Icons.close, color: Colors.white, size: 30),

                  onPressed: () => Navigator.pop(context),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}



// --- АУДИОПЛЕЕР ---

class AudioMessagePlayer extends StatefulWidget {

  final String audioUrl;

  const AudioMessagePlayer({super.key, required this.audioUrl});



  @override

  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();

}



class _AudioMessagePlayerState extends State<AudioMessagePlayer> {

  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;



  @override

  void initState() {

    super.initState();

    _player.onPlayerStateChanged.listen((state) {

      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);

    });

  }



  @override

  void dispose() {

    _player.dispose();

    super.dispose();

  }



  Future<void> _toggleAudio() async {

    if (_isPlaying) {

      await _player.pause();

    } else {

      await _player.play(UrlSource(widget.audioUrl));

    }

  }



  @override

  Widget build(BuildContext context) {

    return Row(

      mainAxisSize: MainAxisSize.min,

      children: [

        IconButton(

          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 36, color: Theme.of(context).colorScheme.primary),

          onPressed: _toggleAudio,

        ),

        const Text('Голосовое сообщение', style: TextStyle(fontWeight: FontWeight.w500)),

      ],

    );

  }

}



