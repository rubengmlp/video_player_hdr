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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
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
  VideoViewType _currentViewType = VideoViewType.platformView;
  bool _isChangingViewType = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // HDR video included in example assets
    _controller = VideoPlayerHdrController.asset('assets/videos/01.MOV')
      ..initialize(
        viewType: _currentViewType,
      ).then((_) {
        setState(() {
          _isInitialized = true;
          _isChangingViewType = false;
        });
      }).catchError((e) {
        setState(() {
          _error = 'Error charging video: $e';
          _isChangingViewType = false;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _switchViewType() async {
    if (_isChangingViewType) return;

    setState(() {
      _isChangingViewType = true;
      _isInitialized = false;
      _error = null;
    });

    final currentPosition = _controller.value.position;
    final wasPlaying = _controller.value.isPlaying;

    await _controller.dispose();

    _currentViewType = _currentViewType == VideoViewType.platformView
        ? VideoViewType.textureView
        : VideoViewType.platformView;

    _initializeController();

    late VoidCallback listener;
    listener = () {
      if (_controller.value.isInitialized && _isInitialized) {
        _controller.removeListener(listener);

        _controller.seekTo(currentPosition).then((_) {
          if (wasPlaying) {
            _controller.play();
          }
        });
      }
    };
    _controller.addListener(listener);
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Video Player HDR Example',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'View Type: ${_currentViewType == VideoViewType.platformView ? "Platform View" : "Texture View"}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton(
                        onPressed: _isChangingViewType ? null : _switchViewType,
                        child: _isChangingViewType
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_currentViewType == VideoViewType.platformView
                                ? 'Switch to Texture View'
                                : 'Switch to Platform View'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_isInitialized && !_isChangingViewType)
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width,
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: AspectRatio(
                      aspectRatio: (_controller.value.rotationCorrection == 90 ||
                              _controller.value.rotationCorrection == 270)
                          ? 1 / _controller.value.aspectRatio
                          : _controller.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayerHdr(_controller),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_isChangingViewType)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Changing view type...'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay),
                    onPressed: _isInitialized && !_isChangingViewType
                        ? () {
                            _controller.seekTo(Duration.zero);
                          }
                        : null,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _isInitialized && !_isChangingViewType
                        ? () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isInitialized && !_isChangingViewType ? _checkHdrSupported : null,
                child: const Text('Supports HDR?'),
              ),
              if (_isHdrSupported != null) Text('Supports HDR: ${_isHdrSupported! ? "Yes" : "No"}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isInitialized && !_isChangingViewType ? _getSupportedHdrFormats : null,
                child: const Text('Get supported HDR formats'),
              ),
              if (_supportedHdrFormats != null)
                Text('Supported HDR formats: ${_supportedHdrFormats!.join(", ")}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    _isInitialized && !_isChangingViewType ? _checkWideColorGamutSupported : null,
                child: const Text('Check wide color gamut supported'),
              ),
              if (_isWideColorGamutSupported != null)
                Text('Wide color gamut supported: ${_isWideColorGamutSupported! ? "Yes" : "No"}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isInitialized && !_isChangingViewType ? _getVideoMetadata : null,
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
