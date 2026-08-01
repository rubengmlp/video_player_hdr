// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_hdr/video_player_hdr.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

// TODO(FirentisTFW): Remove the ignore and rename parameters when adding support for platform views.
// ignore_for_file: avoid_renaming_method_parameters

const String _localhost = 'https://127.0.0.1';
final Uri _localhostUri = Uri.parse(_localhost);

class FakeController extends ValueNotifier<VideoPlayerHdrValue>
    implements VideoPlayerHdrController {
  FakeController() : super(const VideoPlayerHdrValue(duration: Duration.zero));

  FakeController.value(super.value);

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  int playerId = VideoPlayerHdrController.kUninitializedPlayerId;

  @override
  String get dataSource => '';

  @override
  Map<String, String> get httpHeaders => <String, String>{};

  @override
  DataSourceType get dataSourceType => DataSourceType.file;

  @override
  String get package => '';

  @override
  Future<Duration> get position async => value.position;

  @override
  Future<void> seekTo(Duration moment) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  VideoViewType get viewType => VideoViewType.platformView;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(bool prevents) async {}

  @override
  Future<List<VideoAudioTrack>> getAudioTracks() async {
    return <VideoAudioTrack>[
      const VideoAudioTrack(id: 'track_1', label: 'English', language: 'en', isSelected: true),
      const VideoAudioTrack(
        id: 'track_2',
        label: 'Spanish',
        language: 'es',
        isSelected: false,
        bitrate: 128000,
        sampleRate: 44100,
        channelCount: 2,
        codec: 'aac',
      ),
    ];
  }

  @override
  Future<void> selectAudioTrack(String trackId) async {
    // Store the selected track ID for verification in tests
    selectedAudioTrackId = trackId;
  }

  @override
  bool isAudioTrackSupportAvailable() => true;

  String? selectedAudioTrackId;

  @override
  Future<List<VideoTrack>> getVideoTracks() async {
    return <VideoTrack>[
      const VideoTrack(id: '0_0', isSelected: true, label: '1080p', width: 1920, height: 1080),
    ];
  }

  @override
  Future<void> selectVideoTrack(VideoTrack? track) async {
    selectedVideoTrack = track;
  }

  @override
  bool isVideoTrackSupportAvailable() => true;

  VideoTrack? selectedVideoTrack;

  @override
  VideoFormat? get formatHint => null;

  @override
  Future<ClosedCaptionFile> get closedCaptionFile => _loadClosedCaption();

  @override
  VideoPlayerOptions? get videoPlayerOptions => null;

  @override
  void setCaptionOffset(Duration delay) {}

  @override
  Future<void> setClosedCaptionFile(
    Future<ClosedCaptionFile>? closedCaptionFile,
  ) async {}

  @override
  Future<List<String>> getSupportedHdrFormats() {
    return Future.value(['hdr10', 'hlg', 'dolby_vision']);
  }

  @override
  Future<bool> isHdrSupported() {
    return Future.value(true);
  }

  @override
  Future<bool> isWideColorGamutSupported() {
    return Future.value(true);
  }

  @override
  Future<Map<String, dynamic>> getVideoMetadata({String? path}) {
    return Future.value({
      'width': 1920,
      'height': 1080,
      'duration': 10000,
      'frameRate': 30,
      'colorStandard': 'BT2020',
      'colorTransfer': 'HLG',
      'colorRange': 'FULL',
    });
  }
}

Future<ClosedCaptionFile> _loadClosedCaption() async => _FakeClosedCaptionFile();

class _FakeClosedCaptionFile extends ClosedCaptionFile {
  @override
  List<Caption> get captions {
    return <Caption>[
      const Caption(
        text: 'one',
        number: 0,
        start: Duration(milliseconds: 100),
        end: Duration(milliseconds: 200),
      ),

      const Caption(
        text: 'two',
        number: 1,
        start: Duration(milliseconds: 300),
        end: Duration(milliseconds: 400),
      ),

      /// out of order subs to test sorting
      const Caption(
        text: 'three',
        number: 1,
        start: Duration(milliseconds: 500),
        end: Duration(milliseconds: 600),
      ),

      const Caption(
        text: 'five',
        number: 0,
        start: Duration(milliseconds: 700),
        end: Duration(milliseconds: 800),
      ),
      const Caption(
        text: 'four',
        number: 0,
        start: Duration(milliseconds: 600),
        end: Duration(milliseconds: 700),
      ),
    ];
  }
}

void main() {
  late FakeVideoPlayerPlatform fakeVideoPlayerPlatform;

  setUp(() {
    fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;
  });

  void verifyPlayStateRespondsToLifecycle(
    VideoPlayerHdrController controller, {
    required bool shouldPlayInBackground,
  }) {
    expect(controller.value.isPlaying, true);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(controller.value.isPlaying, shouldPlayInBackground);
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(controller.value.isPlaying, true);
  }

  testWidgets('update texture', (WidgetTester tester) async {
    final FakeController controller = FakeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(VideoPlayerHdr(controller));
    expect(find.byType(Texture), findsNothing);

    controller.playerId = 123;
    controller.value = controller.value.copyWith(
      duration: const Duration(milliseconds: 100),
      isInitialized: true,
    );

    await tester.pump();
    expect(find.byType(Texture), findsOneWidget);
  });

  testWidgets('update controller', (WidgetTester tester) async {
    final FakeController controller1 = FakeController();
    addTearDown(controller1.dispose);
    controller1.playerId = 101;
    await tester.pumpWidget(VideoPlayerHdr(controller1));
    expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Texture && widget.textureId == 101,
        ),
        findsOneWidget);

    final FakeController controller2 = FakeController();
    addTearDown(controller2.dispose);
    controller2.playerId = 102;
    await tester.pumpWidget(VideoPlayerHdr(controller2));
    expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Texture && widget.textureId == 102,
        ),
        findsOneWidget);
  });

  testWidgets(
    'VideoPlayerHdr still listens for texture updates after reparenting',
    (WidgetTester tester) async {
      final FakeController controller = FakeController();
      addTearDown(controller.dispose);
      final GlobalKey videoKey = GlobalKey();
      final Widget videoPlayer = KeyedSubtree(
        key: videoKey,
        child: VideoPlayerHdr(controller),
      );

      await tester.pumpWidget(videoPlayer);
      expect(find.byType(Texture), findsNothing);

      // The VideoPlayerHdr is reparented in the widget tree, before the
      // underlying player is initialized.
      await tester.pumpWidget(SizedBox(child: videoPlayer));
      controller.playerId = 321;
      controller.value = controller.value.copyWith(
        duration: const Duration(milliseconds: 100),
        isInitialized: true,
      );

      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Texture && widget.textureId == 321,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'VideoProgressIndicator still listens for controller changes after reparenting',
    (WidgetTester tester) async {
      final FakeController controller = FakeController();
      addTearDown(controller.dispose);
      final GlobalKey key = GlobalKey();
      final Widget progressIndicator = VideoProgressIndicator(
        key: key,
        controller,
        allowScrubbing: false,
      );

      controller.value = controller.value.copyWith(
        duration: const Duration(milliseconds: 100),
        position: const Duration(milliseconds: 50),
        isInitialized: true,
      );
      await tester.pumpWidget(MaterialApp(home: progressIndicator));
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(home: SizedBox(child: progressIndicator)),
      );
      expect((key.currentContext! as Element).dirty, isFalse);
      // Verify that changing value dirties the widget tree.
      controller.value = controller.value.copyWith(
        position: const Duration(milliseconds: 100),
      );
      expect((key.currentContext! as Element).dirty, isTrue);
    },
  );

  testWidgets('VideoPlayerHdr does not crash after loading 0-duration videos',
      (WidgetTester tester) async {
    final FakeController controller = FakeController();
    addTearDown(controller.dispose);
    controller.value = controller.value.copyWith(
      duration: Duration.zero,
      isInitialized: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VideoProgressIndicator(controller, allowScrubbing: false),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-zero rotationCorrection value is used', (WidgetTester tester) async {
    final FakeController controller = FakeController.value(
        const VideoPlayerHdrValue(duration: Duration.zero, rotationCorrection: 180));
    addTearDown(controller.dispose);
    controller.playerId = 1;
    await tester.pumpWidget(VideoPlayerHdr(controller));
    final RotatedBox actualRotationCorrection =
        find.byType(RotatedBox).evaluate().single.widget as RotatedBox;
    final int actualQuarterTurns = actualRotationCorrection.quarterTurns;
    expect(actualQuarterTurns, equals(2));
  });

  testWidgets('no RotatedBox when rotationCorrection is zero', (WidgetTester tester) async {
    final FakeController controller =
        FakeController.value(const VideoPlayerHdrValue(duration: Duration.zero));
    addTearDown(controller.dispose);
    controller.playerId = 1;
    await tester.pumpWidget(VideoPlayerHdr(controller));
    expect(find.byType(RotatedBox), findsNothing);
  });

  group('ClosedCaption widget', () {
    testWidgets('uses a default text style', (WidgetTester tester) async {
      const String text = 'foo';
      await tester.pumpWidget(const MaterialApp(home: ClosedCaption(text: text)));

      final Text textWidget = tester.widget<Text>(find.text(text));
      expect(textWidget.style!.fontSize, 36.0);
      expect(textWidget.style!.color, Colors.white);
    });

    testWidgets('uses given text and style', (WidgetTester tester) async {
      const String text = 'foo';
      const TextStyle textStyle = TextStyle(fontSize: 14.725);
      await tester.pumpWidget(const MaterialApp(
        home: ClosedCaption(
          text: text,
          textStyle: textStyle,
        ),
      ));
      expect(find.text(text), findsOneWidget);

      final Text textWidget = tester.widget<Text>(find.text(text));
      expect(textWidget.style!.fontSize, textStyle.fontSize);
    });

    testWidgets('handles null text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ClosedCaption()));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('handles empty text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ClosedCaption(text: '')));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Passes text contrast ratio guidelines', (WidgetTester tester) async {
      const String text = 'foo';
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: ClosedCaption(text: text),
        ),
      ));
      expect(find.text(text), findsOneWidget);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }, skip: isBrowser);
  });

  group('VideoPlayerHdrController', () {
    group('legacy initialize', () {
      test('network', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.network(
          'https://127.0.0.1',
        );
        await controller.initialize();

        expect(
          fakeVideoPlayerPlatform.dataSources[0].uri,
          'https://127.0.0.1',
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].formatHint,
          null,
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{},
        );
      });

      test('network with hint', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.network(
          'https://127.0.0.1',
          formatHint: VideoFormat.dash,
        );
        await controller.initialize();

        expect(
          fakeVideoPlayerPlatform.dataSources[0].uri,
          'https://127.0.0.1',
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].formatHint,
          VideoFormat.dash,
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{},
        );
      });

      test('network with some headers', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.network(
          'https://127.0.0.1',
          httpHeaders: <String, String>{'Authorization': 'Bearer token'},
        );
        await controller.initialize();

        expect(
          fakeVideoPlayerPlatform.dataSources[0].uri,
          'https://127.0.0.1',
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].formatHint,
          null,
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{'Authorization': 'Bearer token'},
        );
      });
    });
    group('initialize', () {
      test('started app lifecycle observing', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          Uri.parse('https://127.0.0.1'),
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        await controller.play();
        verifyPlayStateRespondsToLifecycle(controller, shouldPlayInBackground: false);
      });

      test('asset', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.asset(
          'a.avi',
        );
        await controller.initialize();

        expect(fakeVideoPlayerPlatform.dataSources[0].asset, 'a.avi');
        expect(fakeVideoPlayerPlatform.dataSources[0].package, null);
      });

      test('network url', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(Uri.parse('https://127.0.0.1'));
        addTearDown(controller.dispose);
        await controller.initialize();

        expect(
          fakeVideoPlayerPlatform.dataSources[0].uri,
          'https://127.0.0.1',
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].formatHint,
          null,
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{},
        );
      });

      test('network url with hint', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          Uri.parse('https://127.0.0.1'),
          formatHint: VideoFormat.dash,
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        expect(
          fakeVideoPlayerPlatform.dataSources[0].uri,
          'https://127.0.0.1',
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].formatHint,
          VideoFormat.dash,
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{},
        );
      });

      test('network url with some headers', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          Uri.parse('https://127.0.0.1'),
          httpHeaders: <String, String>{'Authorization': 'Bearer token'},
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        expect(
          fakeVideoPlayerPlatform.dataSources[0].uri,
          'https://127.0.0.1',
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].formatHint,
          null,
        );
        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{'Authorization': 'Bearer token'},
        );
      });

      test('when controller is initialized with invalid url it should throw VideoError', () async {
        final Uri invalidUrl = Uri.parse('http://testing.com/invalid_url');

        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(invalidUrl);
        addTearDown(controller.dispose);

        late Object error;
        fakeVideoPlayerPlatform.forceInitError = true;
        await controller.initialize().catchError((Object e) => error = e);
        final PlatformException platformEx = error as PlatformException;
        expect(platformEx.code, equals('VideoError'));
      });

      test('file', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.file(File('a.avi'));
        await controller.initialize();

        final String uri = fakeVideoPlayerPlatform.dataSources[0].uri!;
        expect(uri.startsWith('file:///'), true, reason: 'Actual string: $uri');
        expect(uri.endsWith('/a.avi'), true, reason: 'Actual string: $uri');
      }, skip: kIsWeb /* Web does not support file assets. */);

      test('file with special characters', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.file(File('A #1 Hit.avi'));
        await controller.initialize();

        final String uri = fakeVideoPlayerPlatform.dataSources[0].uri!;
        expect(uri.startsWith('file:///'), true, reason: 'Actual string: $uri');
        expect(uri.endsWith('/A%20%231%20Hit.avi'), true, reason: 'Actual string: $uri');
      }, skip: kIsWeb /* Web does not support file assets. */);

      test('file with headers (m3u8)', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.file(
          File('a.avi'),
          httpHeaders: <String, String>{'Authorization': 'Bearer token'},
        );
        await controller.initialize();

        final String uri = fakeVideoPlayerPlatform.dataSources[0].uri!;
        expect(uri.startsWith('file:///'), true, reason: 'Actual string: $uri');
        expect(uri.endsWith('/a.avi'), true, reason: 'Actual string: $uri');

        expect(
          fakeVideoPlayerPlatform.dataSources[0].httpHeaders,
          <String, String>{'Authorization': 'Bearer token'},
        );
      }, skip: kIsWeb /* Web does not support file assets. */);
      test('successful initialize on controller with error clears error', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.network(
          'https://127.0.0.1',
        );
        fakeVideoPlayerPlatform.forceInitError = true;
        await controller.initialize().catchError((dynamic e) {});
        expect(controller.value.hasError, equals(true));
        fakeVideoPlayerPlatform.forceInitError = false;
        await controller.initialize();
        expect(controller.value.hasError, equals(false));
      });

      test('given controller with error when initialization succeeds it should clear error',
          () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        fakeVideoPlayerPlatform.forceInitError = true;
        await controller.initialize().catchError((dynamic e) {});
        expect(controller.value.hasError, equals(true));
        fakeVideoPlayerPlatform.forceInitError = false;
        await controller.initialize();
        expect(controller.value.hasError, equals(false));
      });
    });

    test('contentUri', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.contentUri(Uri.parse('content://video'));
      await controller.initialize();

      expect(fakeVideoPlayerPlatform.dataSources[0].uri, 'content://video');
    });

    test('dispose', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(controller.playerId, VideoPlayerHdrController.kUninitializedPlayerId);
      expect(await controller.position, Duration.zero);
      await controller.initialize();

      await controller.dispose();

      expect(controller.playerId, 0);
      expect(await controller.position, isNull);
    });

    test('calling dispose() on disposed controller does not throw', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.dispose();

      expect(() async => controller.dispose(), returnsNormally);
    });

    test('play', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(Uri.parse('https://127.0.0.1'));
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.value.isPlaying, isFalse);
      await controller.play();

      expect(controller.value.isPlaying, isTrue);

      // The two last calls will be "play" and then "setPlaybackSpeed". The
      // reason for this is that "play" calls "setPlaybackSpeed" internally.
      expect(fakeVideoPlayerPlatform.calls[fakeVideoPlayerPlatform.calls.length - 2], 'play');
      expect(fakeVideoPlayerPlatform.calls.last, 'setPlaybackSpeed');
    });

    test('play before initialized does not call platform', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(controller.value.isInitialized, isFalse);

      await controller.play();

      expect(fakeVideoPlayerPlatform.calls, isEmpty);
    });

    test('play restarts from beginning if video is at end', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      const Duration nonzeroDuration = Duration(milliseconds: 100);
      controller.value = controller.value.copyWith(duration: nonzeroDuration);
      await controller.seekTo(nonzeroDuration);
      expect(controller.value.isPlaying, isFalse);
      expect(controller.value.position, nonzeroDuration);

      await controller.play();

      expect(controller.value.isPlaying, isTrue);
      expect(controller.value.position, Duration.zero);
    });

    test('setLooping', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.value.isLooping, isFalse);
      await controller.setLooping(true);

      expect(controller.value.isLooping, isTrue);
    });

    test('pause', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.play();
      expect(controller.value.isPlaying, isTrue);

      await controller.pause();

      expect(controller.value.isPlaying, isFalse);
      expect(fakeVideoPlayerPlatform.calls.last, 'pause');
    });

    group('seekTo', () {
      test('works', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(await controller.position, Duration.zero);

        await controller.seekTo(const Duration(milliseconds: 500));

        expect(await controller.position, const Duration(milliseconds: 500));
      });

      test('before initialized does not call platform', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        expect(controller.value.isInitialized, isFalse);

        await controller.seekTo(const Duration(milliseconds: 500));

        expect(fakeVideoPlayerPlatform.calls, isEmpty);
      });

      test('clamps values that are too high or low', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(await controller.position, Duration.zero);

        await controller.seekTo(const Duration(seconds: 100));
        expect(await controller.position, const Duration(seconds: 1));

        await controller.seekTo(const Duration(seconds: -100));
        expect(await controller.position, Duration.zero);
      });
    });

    group('setVolume', () {
      test('works', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.value.volume, 1.0);

        const double volume = 0.5;
        await controller.setVolume(volume);

        expect(controller.value.volume, volume);
      });

      test('clamps values that are too high or low', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.value.volume, 1.0);

        await controller.setVolume(-1);
        expect(controller.value.volume, 0.0);

        await controller.setVolume(11);
        expect(controller.value.volume, 1.0);
      });
    });

    group('setPlaybackSpeed', () {
      test('works', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.value.playbackSpeed, 1.0);

        const double speed = 1.5;
        await controller.setPlaybackSpeed(speed);

        expect(controller.value.playbackSpeed, speed);
      });

      test('rejects negative values', () async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.value.playbackSpeed, 1.0);

        expect(() => controller.setPlaybackSpeed(-1), throwsArgumentError);
      });
    });

    group('scrubbing', () {
      testWidgets('restarts on release if already playing', (WidgetTester tester) async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);

        await controller.initialize();
        final VideoProgressIndicator progressWidget =
            VideoProgressIndicator(controller, allowScrubbing: true);

        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: progressWidget,
        ));

        await controller.play();
        expect(controller.value.isPlaying, isTrue);

        final Rect progressRect = tester.getRect(find.byWidget(progressWidget));
        await tester.dragFrom(progressRect.center, const Offset(1.0, 0.0));
        await tester.pumpAndSettle();

        expect(controller.value.position, lessThan(controller.value.duration));
        expect(controller.value.isPlaying, isTrue);

        await controller.pause();
        await tester.runAsync(controller.dispose);
      });

      testWidgets('does not restart when dragging to end', (WidgetTester tester) async {
        final VideoPlayerHdrController controller =
            VideoPlayerHdrController.networkUrl(_localhostUri);

        await controller.initialize();
        final VideoProgressIndicator progressWidget =
            VideoProgressIndicator(controller, allowScrubbing: true);

        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: progressWidget,
        ));

        await controller.play();
        expect(controller.value.isPlaying, isTrue);

        final Rect progressRect = tester.getRect(find.byWidget(progressWidget));
        await tester.dragFrom(progressRect.center, progressRect.centerRight);
        await tester.pumpAndSettle();

        expect(controller.value.position, controller.value.duration);
        expect(controller.value.isPlaying, isFalse);
        await tester.runAsync(controller.dispose);
      });
    });

    group('caption', () {
      test('works when position updates', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );

        await controller.initialize();
        await controller.play();

        // Optionally record caption changes for later verification.
        final Map<int, String> recordedCaptions = <int, String>{};

        controller.addListener(() {
          // Record the caption for the current position (in milliseconds).
          final int ms = controller.value.position.inMilliseconds;
          recordedCaptions[ms] = controller.value.caption.text;
        });

        const Duration updateInterval = Duration(milliseconds: 100);
        const int totalDurationMs = 350;

        // Simulate continuous playback by incrementing in 50ms steps.
        for (int ms = 0; ms <= totalDurationMs; ms += 50) {
          fakeVideoPlayerPlatform._positions[controller.playerId] = Duration(milliseconds: ms);
          await Future<void>.delayed(updateInterval);
        }

        // Now, given your closed caption file and the 100ms update interval,
        // you expect:
        //   • at 100ms: caption should be 'one'
        //   • at 250ms: no caption (i.e. '')
        //   • at 300ms: caption should be 'two'
        expect(recordedCaptions[100], 'one');
        expect(recordedCaptions[250], '');
        expect(recordedCaptions[300], 'two');
      });

      test('makes sure the input captions are unsorted', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );

        await controller.initialize();
        final List<Caption> captions = (await controller.closedCaptionFile)!
            .captions
            .toList();

        // Check that captions are not in sorted order.
        var isSorted = true;
        for (var i = 0; i < captions.length - 1; i++) {
          if (captions[i].start.compareTo(captions[i + 1].start) > 0) {
            isSorted = false;
            break;
          }
        }

        expect(isSorted, false, reason: 'Expected captions to be unsorted');
        expect(
          captions.map((Caption c) => c.text).toList(),
          <String>['one', 'two', 'three', 'five', 'four'],
          reason: 'Captions should be in original unsorted order',
        );
      });

      test('works when seeking, includes all captions', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.value.position, Duration.zero);
        expect(controller.value.caption.text, '');

        await controller.seekTo(const Duration(milliseconds: 100));
        expect(controller.value.caption.text, 'one');

        await controller.seekTo(const Duration(milliseconds: 250));
        expect(controller.value.caption.text, '');

        await controller.seekTo(const Duration(milliseconds: 300));
        expect(controller.value.caption.text, 'two');

        await controller.seekTo(const Duration(milliseconds: 301));
        expect(controller.value.caption.text, 'two');

        await controller.seekTo(const Duration(milliseconds: 400));
        expect(controller.value.caption.text, 'two');

        await controller.seekTo(const Duration(milliseconds: 401));
        expect(controller.value.caption.text, '');

        await controller.seekTo(const Duration(milliseconds: 500));
        expect(controller.value.caption.text, 'three');

        await controller.seekTo(const Duration(milliseconds: 601));
        expect(controller.value.caption.text, 'four');

        await controller.seekTo(const Duration(milliseconds: 701));
        expect(controller.value.caption.text, 'five');

        await controller.seekTo(const Duration(milliseconds: 800));
        expect(controller.value.caption.text, 'five');
        await controller.seekTo(const Duration(milliseconds: 801));
        expect(controller.value.caption.text, '');

        // Test going back
        await controller.seekTo(const Duration(milliseconds: 300));
        expect(controller.value.caption.text, 'two');
      });

      test(
        'works when seeking with captionOffset positive, includes all captions',
        () async {
          final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
            _localhostUri,
            closedCaptionFile: _loadClosedCaption(),
          );
          addTearDown(controller.dispose);

          await controller.initialize();
          controller.setCaptionOffset(const Duration(milliseconds: 100));
          expect(controller.value.position, Duration.zero);
          expect(controller.value.caption.text, '');

          await controller.seekTo(const Duration(milliseconds: 99));
          expect(controller.value.caption.text, 'one');

          await controller.seekTo(const Duration(milliseconds: 100));
          expect(controller.value.caption.text, 'one');

          await controller.seekTo(const Duration(milliseconds: 101));
          expect(controller.value.caption.text, '');

          await controller.seekTo(const Duration(milliseconds: 150));
          expect(controller.value.caption.text, '');

          await controller.seekTo(const Duration(milliseconds: 200));
          expect(controller.value.caption.text, 'two');

          await controller.seekTo(const Duration(milliseconds: 201));
          expect(controller.value.caption.text, 'two');

          await controller.seekTo(const Duration(milliseconds: 400));
          expect(controller.value.caption.text, 'three');

          await controller.seekTo(const Duration(milliseconds: 500));
          expect(controller.value.caption.text, 'three');

          await controller.seekTo(const Duration(milliseconds: 600));
          expect(controller.value.caption.text, 'five');

          await controller.seekTo(const Duration(milliseconds: 700));
          expect(controller.value.caption.text, 'five');

          await controller.seekTo(const Duration(milliseconds: 800));
          expect(controller.value.caption.text, '');
        },
      );

      test(
        'works when seeking with captionOffset negative, includes all captions',
        () async {
          final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
            _localhostUri,
            closedCaptionFile: _loadClosedCaption(),
          );
          addTearDown(controller.dispose);

          await controller.initialize();
          controller.setCaptionOffset(const Duration(milliseconds: -100));
          expect(controller.value.position, Duration.zero);
          expect(controller.value.caption.text, '');

          await controller.seekTo(const Duration(milliseconds: 100));
          expect(controller.value.caption.text, '');

          await controller.seekTo(const Duration(milliseconds: 200));
          expect(controller.value.caption.text, 'one');

          await controller.seekTo(const Duration(milliseconds: 250));
          expect(controller.value.caption.text, 'one');

          await controller.seekTo(const Duration(milliseconds: 300));
          expect(controller.value.caption.text, 'one');

          await controller.seekTo(const Duration(milliseconds: 301));
          expect(controller.value.caption.text, '');

          await controller.seekTo(const Duration(milliseconds: 400));
          expect(controller.value.caption.text, 'two');

          await controller.seekTo(const Duration(milliseconds: 500));
          expect(controller.value.caption.text, 'two');

          await controller.seekTo(const Duration(milliseconds: 600));
          expect(controller.value.caption.text, 'three');

          await controller.seekTo(const Duration(milliseconds: 700));
          expect(controller.value.caption.text, 'three');
        },
      );

      test('setClosedCaptionFile loads caption file', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
        );
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.closedCaptionFile, null);

        await controller.setClosedCaptionFile(_loadClosedCaption());
        expect(
          (await controller.closedCaptionFile)!.captions,
          (await _loadClosedCaption()).captions,
        );
      });

      test('setClosedCaptionFile removes/changes caption file', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(
          (await controller.closedCaptionFile)!.captions,
          (await _loadClosedCaption()).captions,
        );

        await controller.setClosedCaptionFile(null);
        expect(controller.closedCaptionFile, null);
      });

      test('binary search handles exact caption start time boundary', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );
        addTearDown(controller.dispose);

        await controller.initialize();

        // Seek to exact start times - should find the caption
        await controller.seekTo(const Duration(milliseconds: 100));
        expect(
          controller.value.caption.text,
          'one',
          reason: 'Should find caption at exact start time (100ms)',
        );

        await controller.seekTo(const Duration(milliseconds: 300));
        expect(
          controller.value.caption.text,
          'two',
          reason: 'Should find caption at exact start time (300ms)',
        );

        await controller.seekTo(const Duration(milliseconds: 500));
        expect(
          controller.value.caption.text,
          'three',
          reason: 'Should find caption at exact start time (500ms)',
        );

        // At 600ms, "three" ends and "four" starts - binary search may find either
        await controller.seekTo(const Duration(milliseconds: 600));
        expect(
          <String>['three', 'four'].contains(controller.value.caption.text),
          true,
          reason:
              'Should find a caption at boundary (600ms) where two captions meet (got "${controller.value.caption.text}")',
        );

        await controller.seekTo(const Duration(milliseconds: 700));
        expect(
          controller.value.caption.text,
          'five',
          reason: 'Should find caption at exact start time (700ms)',
        );
      });

      test('binary search handles exact caption end time boundary', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );
        addTearDown(controller.dispose);

        await controller.initialize();

        // Seek to exact end times - should still find the caption
        await controller.seekTo(const Duration(milliseconds: 200));
        expect(
          controller.value.caption.text,
          'one',
          reason: 'Should find caption at exact end time (200ms)',
        );

        await controller.seekTo(const Duration(milliseconds: 400));
        expect(
          controller.value.caption.text,
          'two',
          reason: 'Should find caption at exact end time (400ms)',
        );

        // At 600ms boundary where "three" ends and "four" starts
        await controller.seekTo(const Duration(milliseconds: 600));
        expect(
          <String>['three', 'four'].contains(controller.value.caption.text),
          true,
          reason:
              'Should find a caption at boundary (600ms) (got "${controller.value.caption.text}")',
        );

        // At 700ms boundary where "four" ends and "five" starts
        await controller.seekTo(const Duration(milliseconds: 700));
        expect(
          <String>['four', 'five'].contains(controller.value.caption.text),
          true,
          reason:
              'Should find a caption at boundary (700ms) (got "${controller.value.caption.text}")',
        );

        await controller.seekTo(const Duration(milliseconds: 800));
        expect(
          controller.value.caption.text,
          'five',
          reason: 'Should find caption at exact end time (800ms)',
        );

        // One millisecond past the end should not find the caption
        await controller.seekTo(const Duration(milliseconds: 201));
        expect(
          controller.value.caption.text,
          '',
          reason:
              'Should not find caption one millisecond past end time (201ms)',
        );

        await controller.seekTo(const Duration(milliseconds: 801));
        expect(
          controller.value.caption.text,
          '',
          reason:
              'Should not find caption one millisecond past end time (801ms)',
        );
      });

      test('binary search handles gaps between captions', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: _loadClosedCaption(),
        );
        addTearDown(controller.dispose);

        await controller.initialize();

        // Test gaps between captions where no caption should be found
        // Gap before first caption
        await controller.seekTo(Duration.zero);
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty for position before first caption',
        );

        await controller.seekTo(const Duration(milliseconds: 99));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty for position before first caption',
        );

        // Gap between caption 1 (ends at 200) and caption 2 (starts at 300)
        await controller.seekTo(const Duration(milliseconds: 250));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty for gap between captions 1 and 2',
        );

        // Gap between caption 2 (ends at 400) and caption 3 (starts at 500)
        await controller.seekTo(const Duration(milliseconds: 450));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty for gap between captions 2 and 3',
        );

        // Gap after last caption
        await controller.seekTo(const Duration(milliseconds: 900));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty for position after last caption',
        );
      });

      test('binary search works with single caption', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: Future<ClosedCaptionFile>.value(
            _SingleCaptionFile(),
          ),
        );
        addTearDown(controller.dispose);

        await controller.initialize();

        // Before caption
        await controller.seekTo(const Duration(milliseconds: 99));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty before single caption',
        );

        // At start
        await controller.seekTo(const Duration(milliseconds: 100));
        expect(
          controller.value.caption.text,
          'only',
          reason: 'Should find single caption at start',
        );

        // In middle
        await controller.seekTo(const Duration(milliseconds: 150));
        expect(
          controller.value.caption.text,
          'only',
          reason: 'Should find single caption in middle',
        );

        // At end
        await controller.seekTo(const Duration(milliseconds: 200));
        expect(
          controller.value.caption.text,
          'only',
          reason: 'Should find single caption at end',
        );

        // After caption
        await controller.seekTo(const Duration(milliseconds: 201));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty after single caption',
        );
      });

      test('binary search handles overlapping captions', () async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
          closedCaptionFile: Future<ClosedCaptionFile>.value(
            _OverlappingCaptionFile(),
          ),
        );
        addTearDown(controller.dispose);

        await controller.initialize();

        // In first caption only
        await controller.seekTo(const Duration(milliseconds: 100));
        expect(
          controller.value.caption.text,
          'first',
          reason: 'Should find first caption',
        );

        // In overlapping region - binary search should find one of them
        // (the exact one depends on sort order, but it should find something)
        await controller.seekTo(const Duration(milliseconds: 250));
        expect(
          <String>['first', 'second'].contains(controller.value.caption.text),
          true,
          reason:
              'Should find a caption in overlapping region (got "${controller.value.caption.text}")',
        );

        // In second caption only
        await controller.seekTo(const Duration(milliseconds: 350));
        expect(
          controller.value.caption.text,
          'second',
          reason: 'Should find second caption',
        );

        // After all captions
        await controller.seekTo(const Duration(milliseconds: 401));
        expect(
          controller.value.caption.text,
          '',
          reason: 'Should return empty after all captions',
        );
      });
    });

    group('Platform callbacks', () {
      testWidgets('playing completed', (WidgetTester tester) async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
        );

        await controller.initialize();
        const Duration nonzeroDuration = Duration(milliseconds: 100);
        controller.value = controller.value.copyWith(duration: nonzeroDuration);
        expect(controller.value.isPlaying, isFalse);
        await controller.play();
        expect(controller.value.isPlaying, isTrue);
        final StreamController<VideoEvent> fakeVideoEventStream =
            fakeVideoPlayerPlatform.streams[controller.playerId]!;

        fakeVideoEventStream.add(VideoEvent(eventType: VideoEventType.completed));
        await tester.pumpAndSettle();

        expect(controller.value.isPlaying, isFalse);
        expect(controller.value.position, nonzeroDuration);
        await tester.runAsync(controller.dispose);
      });

      testWidgets('playback status', (WidgetTester tester) async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.network(
          'https://.0.0.1',
        );
        await controller.initialize();
        expect(controller.value.isPlaying, isFalse);
        final StreamController<VideoEvent> fakeVideoEventStream =
            fakeVideoPlayerPlatform.streams[controller.playerId]!;

        fakeVideoEventStream.add(VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: true,
        ));
        await tester.pumpAndSettle();
        expect(controller.value.isPlaying, isTrue);

        fakeVideoEventStream.add(VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: false,
        ));
        await tester.pumpAndSettle();
        expect(controller.value.isPlaying, isFalse);
        await tester.runAsync(controller.dispose);
      });

      testWidgets('buffering status', (WidgetTester tester) async {
        final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
          _localhostUri,
        );

        await controller.initialize();
        expect(controller.value.isBuffering, false);
        expect(controller.value.buffered, isEmpty);
        final StreamController<VideoEvent> fakeVideoEventStream =
            fakeVideoPlayerPlatform.streams[controller.playerId]!;

        fakeVideoEventStream.add(VideoEvent(eventType: VideoEventType.bufferingStart));
        await tester.pumpAndSettle();
        expect(controller.value.isBuffering, isTrue);

        const Duration bufferStart = Duration.zero;
        const Duration bufferEnd = Duration(milliseconds: 500);
        fakeVideoEventStream
            .add(VideoEvent(eventType: VideoEventType.bufferingUpdate, buffered: <DurationRange>[
          DurationRange(bufferStart, bufferEnd),
        ]));
        await tester.pumpAndSettle();
        expect(controller.value.isBuffering, isTrue);
        expect(controller.value.buffered.length, 1);
        expect(controller.value.buffered[0].toString(),
            DurationRange(bufferStart, bufferEnd).toString());

        fakeVideoEventStream.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
        await tester.pumpAndSettle();
        expect(controller.value.isBuffering, isFalse);
        await tester.runAsync(controller.dispose);
      });
    });
  });

  test('updates position', () async {
    final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
      _localhostUri,
      videoPlayerOptions: VideoPlayerOptions(),
    );

    await controller.initialize();

    const Duration updatesInterval = Duration(milliseconds: 100);

    final List<Duration> positions = <Duration>[];
    final Completer<void> intervalUpdateCompleter = Completer<void>();

    // Listen for position updates
    controller.addListener(() {
      positions.add(controller.value.position);
      if (positions.length >= 3 && !intervalUpdateCompleter.isCompleted) {
        intervalUpdateCompleter.complete();
      }
    });
    await controller.play();
    for (int i = 0; i < 3; i++) {
      await Future<void>.delayed(updatesInterval);
      fakeVideoPlayerPlatform._positions[controller.playerId] =
          Duration(milliseconds: i * updatesInterval.inMilliseconds);
    }

    // Wait for at least 3 position updates
    await intervalUpdateCompleter.future;

    // Verify that the intervals between updates are approximately correct
    expect(positions[1] - positions[0], greaterThanOrEqualTo(updatesInterval));
    expect(positions[2] - positions[1], greaterThanOrEqualTo(updatesInterval));
  });

  group('DurationRange', () {
    test('uses given values', () {
      const Duration start = Duration(seconds: 2);
      const Duration end = Duration(seconds: 8);

      final DurationRange range = DurationRange(start, end);

      expect(range.start, start);
      expect(range.end, end);
      expect(range.toString(), contains('start: $start, end: $end'));
    });

    test('calculates fractions', () {
      const Duration start = Duration(seconds: 2);
      const Duration end = Duration(seconds: 8);
      const Duration total = Duration(seconds: 10);

      final DurationRange range = DurationRange(start, end);

      expect(range.startFraction(total), .2);
      expect(range.endFraction(total), .8);
    });
  });

  group('VideoPlayerHdrValue', () {
    test('uninitialized()', () {
      const VideoPlayerHdrValue uninitialized = VideoPlayerHdrValue.uninitialized();

      expect(uninitialized.duration, equals(Duration.zero));
      expect(uninitialized.position, equals(Duration.zero));
      expect(uninitialized.caption, equals(Caption.none));
      expect(uninitialized.captionOffset, equals(Duration.zero));
      expect(uninitialized.buffered, isEmpty);
      expect(uninitialized.isPlaying, isFalse);
      expect(uninitialized.isLooping, isFalse);
      expect(uninitialized.isBuffering, isFalse);
      expect(uninitialized.volume, 1.0);
      expect(uninitialized.playbackSpeed, 1.0);
      expect(uninitialized.errorDescription, isNull);
      expect(uninitialized.size, equals(Size.zero));
      expect(uninitialized.isInitialized, isFalse);
      expect(uninitialized.hasError, isFalse);
      expect(uninitialized.aspectRatio, 1.0);
    });

    test('erroneous()', () {
      const String errorMessage = 'foo';
      const VideoPlayerHdrValue error = VideoPlayerHdrValue.erroneous(errorMessage);

      expect(error.duration, equals(Duration.zero));
      expect(error.position, equals(Duration.zero));
      expect(error.caption, equals(Caption.none));
      expect(error.captionOffset, equals(Duration.zero));
      expect(error.buffered, isEmpty);
      expect(error.isPlaying, isFalse);
      expect(error.isLooping, isFalse);
      expect(error.isBuffering, isFalse);
      expect(error.volume, 1.0);
      expect(error.playbackSpeed, 1.0);
      expect(error.errorDescription, errorMessage);
      expect(error.size, equals(Size.zero));
      expect(error.isInitialized, isFalse);
      expect(error.hasError, isTrue);
      expect(error.aspectRatio, 1.0);
    });

    test('toString()', () {
      const Duration duration = Duration(seconds: 5);
      const Size size = Size(400, 300);
      const Duration position = Duration(seconds: 1);
      const Caption caption =
          Caption(text: 'foo', number: 0, start: Duration.zero, end: Duration.zero);
      const Duration captionOffset = Duration(milliseconds: 250);
      final List<DurationRange> buffered = <DurationRange>[
        DurationRange(Duration.zero, const Duration(seconds: 4))
      ];
      const bool isInitialized = true;
      const bool isPlaying = true;
      const bool isLooping = true;
      const bool isBuffering = true;
      const double volume = 0.5;
      const double playbackSpeed = 1.5;

      final VideoPlayerHdrValue value = VideoPlayerHdrValue(
        duration: duration,
        size: size,
        position: position,
        caption: caption,
        captionOffset: captionOffset,
        buffered: buffered,
        isInitialized: isInitialized,
        isPlaying: isPlaying,
        isLooping: isLooping,
        isBuffering: isBuffering,
        volume: volume,
        playbackSpeed: playbackSpeed,
      );

      expect(
          value.toString(),
          'VideoPlayerHdrValue(duration: 0:00:05.000000, '
          'size: Size(400.0, 300.0), '
          'position: 0:00:01.000000, '
          'caption: Caption(number: 0, start: 0:00:00.000000, end: 0:00:00.000000, text: foo), '
          'captionOffset: 0:00:00.250000, '
          'buffered: [DurationRange(start: 0:00:00.000000, end: 0:00:04.000000)], '
          'isInitialized: true, '
          'isPlaying: true, '
          'isLooping: true, '
          'isBuffering: true, '
          'volume: 0.5, '
          'playbackSpeed: 1.5, '
          'errorDescription: null, '
          'isCompleted: false, '
          'preventsDisplaySleepDuringVideoPlayback: true),');
    });

    group('copyWith()', () {
      test('exact copy', () {
        const VideoPlayerHdrValue original = VideoPlayerHdrValue.uninitialized();
        final VideoPlayerHdrValue exactCopy = original.copyWith();

        expect(exactCopy.toString(), original.toString());
      });
      test('errorDescription is not persisted when copy with null', () {
        const VideoPlayerHdrValue original = VideoPlayerHdrValue.erroneous('error');
        final VideoPlayerHdrValue copy = original.copyWith(errorDescription: null);

        expect(copy.errorDescription, null);
      });
      test('errorDescription is changed when copy with another error', () {
        const VideoPlayerHdrValue original = VideoPlayerHdrValue.erroneous('error');
        final VideoPlayerHdrValue copy = original.copyWith(errorDescription: 'new error');

        expect(copy.errorDescription, 'new error');
      });
      test('errorDescription is changed when copy with error', () {
        const VideoPlayerHdrValue original = VideoPlayerHdrValue.uninitialized();
        final VideoPlayerHdrValue copy = original.copyWith(errorDescription: 'new error');

        expect(copy.errorDescription, 'new error');
      });
    });

    group('aspectRatio', () {
      test('640x480 -> 4:3', () {
        const VideoPlayerHdrValue value = VideoPlayerHdrValue(
          isInitialized: true,
          size: Size(640, 480),
          duration: Duration(seconds: 1),
        );
        expect(value.aspectRatio, 4 / 3);
      });

      test('no size -> 1.0', () {
        const VideoPlayerHdrValue value = VideoPlayerHdrValue(
          isInitialized: true,
          duration: Duration(seconds: 1),
        );
        expect(value.aspectRatio, 1.0);
      });

      test('height = 0 -> 1.0', () {
        const VideoPlayerHdrValue value = VideoPlayerHdrValue(
          isInitialized: true,
          size: Size(640, 0),
          duration: Duration(seconds: 1),
        );
        expect(value.aspectRatio, 1.0);
      });

      test('width = 0 -> 1.0', () {
        const VideoPlayerHdrValue value = VideoPlayerHdrValue(
          isInitialized: true,
          size: Size(0, 480),
          duration: Duration(seconds: 1),
        );
        expect(value.aspectRatio, 1.0);
      });

      test('negative aspect ratio -> 1.0', () {
        const VideoPlayerHdrValue value = VideoPlayerHdrValue(
          isInitialized: true,
          size: Size(640, -480),
          duration: Duration(seconds: 1),
        );
        expect(value.aspectRatio, 1.0);
      });
    });
  });

  group('audio tracks', () {
    test('getAudioTracks returns list of tracks', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      final List<VideoAudioTrack> tracks = await controller.getAudioTracks();

      expect(tracks.length, 3);
      expect(tracks[0].id, 'track_1');
      expect(tracks[0].label, 'English');
      expect(tracks[0].language, 'en');
      expect(tracks[0].isSelected, true);
      expect(tracks[0].bitrate, null);
      expect(tracks[0].sampleRate, null);
      expect(tracks[0].channelCount, null);
      expect(tracks[0].codec, null);

      expect(tracks[1].id, 'track_2');
      expect(tracks[1].label, 'Spanish');
      expect(tracks[1].language, 'es');
      expect(tracks[1].isSelected, false);
      expect(tracks[1].bitrate, 128000);
      expect(tracks[1].sampleRate, 44100);
      expect(tracks[1].channelCount, 2);
      expect(tracks[1].codec, 'aac');

      expect(tracks[2].id, 'track_3');
      expect(tracks[2].label, 'French');
      expect(tracks[2].language, 'fr');
      expect(tracks[2].isSelected, false);
      expect(tracks[2].bitrate, 96000);
      expect(tracks[2].sampleRate, null);
      expect(tracks[2].channelCount, null);
      expect(tracks[2].codec, null);
    });

    test('getAudioTracks before initialization returns empty list', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      final List<VideoAudioTrack> tracks = await controller.getAudioTracks();
      expect(tracks, isEmpty);
    });

    test('selectAudioTrack works with valid track ID', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.selectAudioTrack('track_2');

      // Verify the platform recorded the selection
      expect(fakeVideoPlayerPlatform.selectedAudioTrackIds[controller.playerId], 'track_2');
    });

    test('selectAudioTrack before initialization throws', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(() => controller.selectAudioTrack('track_1'), throwsA(isA<StateError>()));
    });

    test('selectAudioTrack with empty track ID', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.selectAudioTrack('');

      expect(fakeVideoPlayerPlatform.selectedAudioTrackIds[controller.playerId], '');
    });

    test('multiple track selections update correctly', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();

      await controller.selectAudioTrack('track_1');
      expect(fakeVideoPlayerPlatform.selectedAudioTrackIds[controller.playerId], 'track_1');

      await controller.selectAudioTrack('track_3');
      expect(fakeVideoPlayerPlatform.selectedAudioTrackIds[controller.playerId], 'track_3');
    });

    test('isAudioTrackSupportAvailable delegates to the platform', () {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(controller.isAudioTrackSupportAvailable(), true);
      expect(fakeVideoPlayerPlatform.calls.contains('isAudioTrackSupportAvailable'), true);
    });
  });

  group('video tracks', () {
    test('getVideoTracks returns list of tracks', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      final List<VideoTrack> tracks = await controller.getVideoTracks();

      expect(tracks.length, 2);
      expect(tracks[0].id, '0_0');
      expect(tracks[0].label, '1080p');
      expect(tracks[0].isSelected, true);
      expect(tracks[0].bitrate, 8000000);
      expect(tracks[0].width, 1920);
      expect(tracks[0].height, 1080);

      expect(tracks[1].id, '0_1');
      expect(tracks[1].label, '720p');
      expect(tracks[1].isSelected, false);
    });

    test('getVideoTracks before initialization returns empty list', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      final List<VideoTrack> tracks = await controller.getVideoTracks();
      expect(tracks, isEmpty);
    });

    test('selectVideoTrack records the selected track', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      final List<VideoTrack> tracks = await controller.getVideoTracks();
      await controller.selectVideoTrack(tracks[1]);

      expect(fakeVideoPlayerPlatform.selectedVideoTracks[controller.playerId], tracks[1]);
    });

    test('selectVideoTrack with null restores automatic selection', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.selectVideoTrack(null);

      expect(fakeVideoPlayerPlatform.selectedVideoTracks.containsKey(controller.playerId), true);
      expect(fakeVideoPlayerPlatform.selectedVideoTracks[controller.playerId], null);
    });

    test('selectVideoTrack before initialization throws', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(() => controller.selectVideoTrack(null), throwsA(isA<StateError>()));
    });

    test('isVideoTrackSupportAvailable delegates to the platform', () {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      expect(controller.isVideoTrackSupportAvailable(), true);
      expect(fakeVideoPlayerPlatform.calls.contains('isVideoTrackSupportAvailable'), true);
    });
  });

  group('VideoPlayerOptions', () {
    test('setMixWithOthers', () async {
      final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
        _localhostUri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.videoPlayerOptions!.mixWithOthers, true);
    });

    test('setPreventsDisplaySleepDuringVideoPlayback', () async {
      final VideoPlayerHdrController controller =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.value.preventsDisplaySleepDuringVideoPlayback, true);

      // initialize() already forwards the initial value; clear so the
      // assertion below exercises the public setter, not initialization.
      fakeVideoPlayerPlatform.calls.clear();

      await controller.setPreventsDisplaySleepDuringVideoPlayback(false);
      expect(controller.value.preventsDisplaySleepDuringVideoPlayback, false);

      expect(
        fakeVideoPlayerPlatform.calls.contains('setPreventsDisplaySleepDuringVideoPlayback'),
        true,
      );
    });

    test('preventsDisplaySleepDuringVideoPlayback false via options', () async {
      final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
        _localhostUri,
        videoPlayerOptions: VideoPlayerOptions(preventsDisplaySleepDuringVideoPlayback: false),
      );
      addTearDown(controller.dispose);

      expect(controller.value.preventsDisplaySleepDuringVideoPlayback, false);
      await controller.initialize();
      expect(controller.value.preventsDisplaySleepDuringVideoPlayback, false);
    });

    test('passes constructor viewType through to the platform', () async {
      final VideoPlayerHdrController defaultController =
          VideoPlayerHdrController.networkUrl(_localhostUri);
      addTearDown(defaultController.dispose);
      await defaultController.initialize();
      expect(fakeVideoPlayerPlatform.creationOptions.last.viewType, VideoViewType.platformView);

      final VideoPlayerHdrController textureController = VideoPlayerHdrController.networkUrl(
        _localhostUri,
        viewType: VideoViewType.textureView,
      );
      addTearDown(textureController.dispose);
      await textureController.initialize();
      expect(fakeVideoPlayerPlatform.creationOptions.last.viewType, VideoViewType.textureView);
      expect(textureController.viewType, VideoViewType.textureView);
    });

    test('passes backBufferDurationMs through to the platform', () async {
      final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
        _localhostUri,
        videoPlayerOptions: VideoPlayerOptions(backBufferDurationMs: 5000),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(
        fakeVideoPlayerPlatform.creationOptions.last.videoPlayerOptions?.backBufferDurationMs,
        5000,
      );
    });

    test('true allowBackgroundPlayback continues playback', () async {
      final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
        _localhostUri,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: true,
        ),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.play();
      verifyPlayStateRespondsToLifecycle(
        controller,
        shouldPlayInBackground: true,
      );
    });

    test('false allowBackgroundPlayback pauses playback', () async {
      final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
        _localhostUri,
        videoPlayerOptions: VideoPlayerOptions(),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.play();
      verifyPlayStateRespondsToLifecycle(
        controller,
        shouldPlayInBackground: false,
      );
    });
  });

  test('VideoProgressColors', () {
    const Color playedColor = Color.fromRGBO(0, 0, 255, 0.75);
    const Color bufferedColor = Color.fromRGBO(0, 255, 0, 0.5);
    const Color backgroundColor = Color.fromRGBO(255, 255, 0, 0.25);

    const VideoProgressColors colors = VideoProgressColors(
        playedColor: playedColor, bufferedColor: bufferedColor, backgroundColor: backgroundColor);

    expect(colors.playedColor, playedColor);
    expect(colors.bufferedColor, bufferedColor);
    expect(colors.backgroundColor, backgroundColor);
  });

  test('isCompleted updates on video end', () async {
    final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
      _localhostUri,
      videoPlayerOptions: VideoPlayerOptions(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    final StreamController<VideoEvent> fakeVideoEventStream =
        fakeVideoPlayerPlatform.streams[controller.playerId]!;

    bool currentIsCompleted = controller.value.isCompleted;

    final void Function() isCompletedTest = expectAsync0(() {});

    controller.addListener(() async {
      if (currentIsCompleted != controller.value.isCompleted) {
        currentIsCompleted = controller.value.isCompleted;
        if (controller.value.isCompleted) {
          isCompletedTest();
        }
      }
    });

    fakeVideoEventStream.add(VideoEvent(eventType: VideoEventType.completed));
  });

  test('isCompleted updates on video play after completed', () async {
    final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
      _localhostUri,
      videoPlayerOptions: VideoPlayerOptions(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    final StreamController<VideoEvent> fakeVideoEventStream =
        fakeVideoPlayerPlatform.streams[controller.playerId]!;

    bool currentIsCompleted = controller.value.isCompleted;

    final void Function() isCompletedTest = expectAsync0(() {}, count: 2);
    final void Function() isNoLongerCompletedTest = expectAsync0(() {});
    bool hasLooped = false;

    controller.addListener(() async {
      if (currentIsCompleted != controller.value.isCompleted) {
        currentIsCompleted = controller.value.isCompleted;
        if (controller.value.isCompleted) {
          isCompletedTest();
          if (!hasLooped) {
            fakeVideoEventStream
                .add(VideoEvent(eventType: VideoEventType.isPlayingStateUpdate, isPlaying: true));
            hasLooped = !hasLooped;
          }
        } else {
          isNoLongerCompletedTest();
        }
      }
    });

    fakeVideoEventStream.add(VideoEvent(eventType: VideoEventType.completed));
  });

  test('isCompleted updates on video seek to end', () async {
    final VideoPlayerHdrController controller = VideoPlayerHdrController.networkUrl(
      _localhostUri,
      videoPlayerOptions: VideoPlayerOptions(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    bool currentIsCompleted = controller.value.isCompleted;

    final void Function() isCompletedTest = expectAsync0(() {});

    controller.value = controller.value.copyWith(duration: const Duration(seconds: 10));

    controller.addListener(() async {
      if (currentIsCompleted != controller.value.isCompleted) {
        currentIsCompleted = controller.value.isCompleted;
        if (controller.value.isCompleted) {
          isCompletedTest();
        }
      }
    });

    // This call won't update isCompleted.
    // The test will fail if `isCompletedTest` is called more than once.
    await controller.seekTo(const Duration(seconds: 10));

    await controller.seekTo(const Duration(seconds: 20));
  });

  group('HDR functionality with FakeController', () {
    late FakeController controller;

    setUp(() {
      controller = FakeController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('HDR support detection', () async {
      expect(await controller.isHdrSupported(), isTrue);

      controller.value =
          controller.value.copyWith(errorDescription: 'HDR not supported on this device');
      expect(controller.value.hasError, isTrue);
    });

    test('HDR formats list', () async {
      final formats = await controller.getSupportedHdrFormats();
      expect(formats, containsAll(['hdr10', 'dolby_vision', 'hlg']));
    });

    test('Wide Color Gamut support', () async {
      expect(await controller.isWideColorGamutSupported(), isTrue);
    });

    test('Video metadata retrieval', () async {
      final metadata = await controller.getVideoMetadata();

      expect(metadata, isA<Map<String, dynamic>>());
      expect(metadata['width'], equals(1920));
      expect(metadata['height'], equals(1080));
      expect(metadata['colorStandard'], equals('BT2020'));
      expect(metadata['colorTransfer'], equals('HLG'));
    });

    test('HDR video completion', () async {
      await controller.initialize();

      controller.value = controller.value.copyWith(
          duration: const Duration(seconds: 10),
          position: const Duration(seconds: 10),
          isPlaying: false,
          isCompleted: true);

      expect(controller.value.isCompleted, isTrue);
      expect(await controller.getVideoMetadata(), isNotNull);
    });

    test('Error handling for unsupported HDR format', () async {
      controller.value = controller.value.copyWith(errorDescription: 'Unsupported HDR format');

      expect(controller.value.hasError, isTrue);
      expect(controller.value.errorDescription, contains('Unsupported HDR format'));
    });
  });
}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  Completer<bool> initialized = Completer<bool>();
  List<String> calls = <String>[];
  List<DataSource> dataSources = <DataSource>[];
  List<VideoCreationOptions> creationOptions = <VideoCreationOptions>[];
  final Map<int, StreamController<VideoEvent>> streams = <int, StreamController<VideoEvent>>{};
  bool forceInitError = false;
  int nextTextureId = 0;
  final Map<int, Duration> _positions = <int, Duration>{};
  final Map<int, VideoPlayerWebOptions> webOptions = <int, VideoPlayerWebOptions>{};
  final Map<int, String> selectedAudioTrackIds = <int, String>{};
  final Map<int, VideoTrack?> selectedVideoTracks = <int, VideoTrack?>{};

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    creationOptions.add(options);
    return create(options.dataSource);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    calls.add('create');
    final StreamController<VideoEvent> stream = StreamController<VideoEvent>();
    streams[nextTextureId] = stream;
    if (forceInitError) {
      stream.addError(PlatformException(code: 'VideoError', message: 'Video player had error XYZ'));
    } else {
      stream.add(VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(100, 100),
          duration: const Duration(seconds: 1)));
    }
    dataSources.add(dataSource);
    return nextTextureId++;
  }

  @override
  Future<void> dispose(int textureId) async {
    calls.add('dispose');
  }

  @override
  Future<void> init() async {
    calls.add('init');
    initialized.complete(true);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return streams[textureId]!.stream;
  }

  @override
  Future<void> pause(int textureId) async {
    calls.add('pause');
  }

  @override
  Future<void> play(int textureId) async {
    calls.add('play');
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    calls.add('position');
    return _positions[textureId] ?? Duration.zero;
  }

  @override
  Future<void> seekTo(int textureId, Duration position) async {
    calls.add('seekTo');
    _positions[textureId] = position;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {
    calls.add('setLooping');
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    calls.add('setVolume');
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    calls.add('setPlaybackSpeed');
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {
    calls.add('setMixWithOthers');
  }

  @override
  Widget buildView(int textureId) {
    return Texture(textureId: textureId);
  }

  @override
  Future<void> setWebOptions(int textureId, VideoPlayerWebOptions options) async {
    if (!kIsWeb) {
      throw UnimplementedError('setWebOptions() is only available in the web.');
    }
    calls.add('setWebOptions');
    webOptions[textureId] = options;
  }

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int textureId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {
    calls.add('setPreventsDisplaySleepDuringVideoPlayback');
  }

  @override
  Future<List<VideoAudioTrack>> getAudioTracks(int textureId) async {
    calls.add('getAudioTracks');
    return <VideoAudioTrack>[
      const VideoAudioTrack(
        id: 'track_1',
        label: 'English',
        language: 'en',
        isSelected: true,
      ),
      const VideoAudioTrack(
        id: 'track_2',
        label: 'Spanish',
        language: 'es',
        isSelected: false,
        bitrate: 128000,
        sampleRate: 44100,
        channelCount: 2,
        codec: 'aac',
      ),
      const VideoAudioTrack(
        id: 'track_3',
        label: 'French',
        language: 'fr',
        isSelected: false,
        bitrate: 96000,
      ),
    ];
  }

  @override
  Future<void> selectAudioTrack(int textureId, String trackId) async {
    calls.add('selectAudioTrack');
    selectedAudioTrackIds[textureId] = trackId;
  }

  @override
  bool isAudioTrackSupportAvailable() {
    calls.add('isAudioTrackSupportAvailable');
    return true; // Return true for testing purposes
  }

  @override
  Future<List<VideoTrack>> getVideoTracks(int textureId) async {
    calls.add('getVideoTracks');
    return <VideoTrack>[
      const VideoTrack(
        id: '0_0',
        isSelected: true,
        label: '1080p',
        bitrate: 8000000,
        width: 1920,
        height: 1080,
      ),
      const VideoTrack(
        id: '0_1',
        isSelected: false,
        label: '720p',
        bitrate: 4000000,
        width: 1280,
        height: 720,
      ),
    ];
  }

  @override
  Future<void> selectVideoTrack(int textureId, VideoTrack? track) async {
    calls.add('selectVideoTrack');
    selectedVideoTracks[textureId] = track;
  }

  @override
  bool isVideoTrackSupportAvailable() {
    calls.add('isVideoTrackSupportAvailable');
    return true; // Return true for testing purposes
  }
}

class _SingleCaptionFile extends ClosedCaptionFile {
  @override
  List<Caption> get captions {
    return <Caption>[
      const Caption(
        text: 'only',
        number: 0,
        start: Duration(milliseconds: 100),
        end: Duration(milliseconds: 200),
      ),
    ];
  }
}

class _OverlappingCaptionFile extends ClosedCaptionFile {
  @override
  List<Caption> get captions {
    return <Caption>[
      const Caption(
        text: 'first',
        number: 0,
        start: Duration(milliseconds: 100),
        end: Duration(milliseconds: 300),
      ),
      const Caption(
        text: 'second',
        number: 1,
        start: Duration(milliseconds: 200),
        end: Duration(milliseconds: 400),
      ),
    ];
  }
}
