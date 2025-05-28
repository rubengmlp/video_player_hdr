# Video Player HDR

[![pub package](https://img.shields.io/pub/v/video_player_hdr.svg)](https://pub.dev/packages/video_player_hdr)
[![GitHub license](https://img.shields.io/github/license/rubengmlp/video_player_hdr.svg)](LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/rubengmlp/video_player_hdr.svg)](https://github.com/rubengmlp/video_player_hdr/issues)
[![GitHub issues closed](https://img.shields.io/github/issues-closed/rubengmlp/video_player_hdr.svg)](https://github.com/rubengmlp/video_player_hdr/issues?q=is%3Aissue+is%3Aclosed)

A fork of the official Flutter `video_player` plugin with **HDR (High Dynamic Range) support** for Android and iOS. This package exposes the option of using platform views in addition to the texture view currently offered by `video_player`.

<hr />

## Features

- Play HDR videos using platform views.
- Detect if the device supports HDR playback.
- Query supported HDR formats.
- Check for wide color gamut support.
- Retrieve video metadata, including HDR information.
- All standard features of the original `video_player` plugin.

## Supported Platforms

- **Android**
- **iOS**
- macOS (fallbacks to `video_player_avfoundation`)
- Web (fallbacks to `video_player_web`)

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  video_player_hdr: ^1.0.0
```

Then run:

```sh
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:video_player_hdr/video_player_hdr.dart';
```

### Basic Example

```dart
final controller = VideoPlayerHdrController.asset('assets/videos/hdr_video.mp4');
await controller.initialize(
  viewType: VideoViewType.platformView,
);
controller.play();
```

You can choose between `platformView` and `textureView` for the `viewType` parameter. The `platformView` option enables HDR representation, while `textureView` is the type currently used by the standard `video_player` package. If no `viewType` is specified, `platformView` will be used by default.

### HDR Features

```dart
final isHdrSupported = await controller.isHdrSupported();
final supportedHdrFormats = await controller.getSupportedHdrFormats();
final isWideColorGamut = await controller.isWideColorGamutSupported();
final metadata = await controller.getVideoMetadata();
```

### Example App

A full example is available in the [`example/`](example/) directory.  
It demonstrates:

- HDR video playback
- Checking HDR support
- Listing supported HDR formats
- Wide color gamut detection
- Retrieving video metadata

## API

- `isHdrSupported()`: Checks if the device supports HDR playback.
- `getSupportedHdrFormats()`: Returns a list of HDR formats supported by the device.
- `isWideColorGamutSupported()`: Checks if the device supports wide color gamut.
- `getVideoMetadata()`: Retrieves metadata from the video.

> **Note:** These methods are only available on Android and iOS.

## Migrating from `video_player`

This package is a drop-in replacement for the official `video_player` plugin.  
Just replace your imports and controller instantiations with `video_player_hdr`.

## Issues & Feedback

Please report issues and feature requests on the [GitHub issue tracker](https://github.com/rubengmlp/video_player_hdr/issues).

## License

This project is a fork of the official Flutter `video_player` plugin and retains its original BSD 3-Clause license.

See [LICENSE](LICENSE) for details.

## Authors and Contributors

Significant modifications and HDR support by Rubén Gómez López ([rubengmlp@gmail.com](mailto:rubengmlp@gmail.com)).