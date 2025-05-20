import 'package:flutter/material.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player HDR Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoPlayerHdrExample(),
    );
  }
}

class VideoPlayerHdrExample extends StatefulWidget {
  const VideoPlayerHdrExample({super.key});

  @override
  State<VideoPlayerHdrExample> createState() => _VideoPlayerHdrExampleState();
}

class _VideoPlayerHdrExampleState extends State<VideoPlayerHdrExample> {
  late VideoPlayerHdrController _controller;
  bool _isInitialized = false;
  bool? _isHdrSupported;
  List<String>? _supportedHdrFormats;
  String? _error;
  bool? _isWideColorGamutSupported;
  Map<String, dynamic> _metadata = {};

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerHdrController.networkUrl(Uri.parse(
        'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4'))
      ..initialize(
        viewType: VideoViewType.platformView,
      ).then((_) {
        setState(() {
          _isInitialized = true;
        });
      }).catchError((e) {
        setState(() {
          _error = 'Error charging video: $e';
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkHdrSupported() async {
    try {
      final result = await _controller.isHdrSupported();
      setState(() {
        _isHdrSupported = result;
      });
    } catch (e) {
      setState(() {
        _isHdrSupported = null;
        _error = 'Error checking HDR: $e';
      });
    }
  }

  Future<void> _getVideoMetadata() async {
    try {
      final result = await _controller.getVideoMetadata();
      setState(() {
        _metadata = result;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting video metadata: $e';
      });
    }
  }

  Future<void> _getSupportedHdrFormats() async {
    try {
      final result = await _controller.getSupportedHdrFormats();
      setState(() {
        _supportedHdrFormats = result;
      });
    } catch (e) {
      setState(() {
        _supportedHdrFormats = null;
        _error = 'Error getting HDR formats: $e';
      });
    }
  }

  Future<void> _checkWideColorGamutSupported() async {
    try {
      final result = await _controller.isWideColorGamutSupported();
      setState(() {
        _isWideColorGamutSupported = result;
      });
    } catch (e) {
      setState(() {
        _isWideColorGamutSupported = null;
        _error = 'Error checking wide color gamut: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player HDR Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_isInitialized)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayerHdr(_controller),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkHdrSupported,
                child: const Text('Supports HDR?'),
              ),
              if (_isHdrSupported != null) Text('Supports HDR: ${_isHdrSupported! ? "Yes" : "No"}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _getSupportedHdrFormats,
                child: const Text('Get supported HDR formats'),
              ),
              if (_supportedHdrFormats != null)
                Text('Supported HDR formats: ${_supportedHdrFormats!.join(", ")}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _checkWideColorGamutSupported,
                child: const Text('Check wide color gamut supported'),
              ),
              if (_isWideColorGamutSupported != null)
                Text('Wide color gamut supported: ${_isWideColorGamutSupported! ? "Yes" : "No"}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _getVideoMetadata,
                child: const Text('Get video metadata'),
              ),
              if (_metadata.isNotEmpty) Text('Video metadata: $_metadata'),
            ],
          ),
        ),
      ),
    );
  }
}
