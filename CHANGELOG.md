## 2.1.0
- Adds Swift Package Manager support for iOS (CocoaPods remains supported;
  Flutter picks the right one based on the consuming app's configuration).
  Thanks to @bbbshah for the original contribution (#5).
- Raises the declared minimum iOS version from 12.0 to 13.0, the floor already
  imposed by Flutter 3.44 and `video_player_avfoundation` 2.11.
- Android: `getSupportedHdrFormats()` returns an empty list instead of an
  internal error on devices where `Display.getHdrCapabilities()` returns null.

## 2.0.0
Aligns the public API with upstream `video_player` 2.10+. **Breaking changes:**

- `viewType` moves from `initialize()` to the `VideoPlayerHdrController`
  constructors, matching upstream. `initialize()` no longer takes parameters.
  Unlike upstream, the default remains `VideoViewType.platformView`, since HDR
  output is lost through the texture path. To switch view types at runtime,
  dispose the controller and create a new one.
  - Before: `VideoPlayerHdrController.asset(src)..initialize(viewType: ...)`
  - After: `VideoPlayerHdrController.asset(src, viewType: ...)..initialize()`
- Migrates from the deprecated texture-based platform interface surface to the
  current one: the test-visible `textureId` getter and
  `kUninitializedTextureId` constant are renamed to `playerId` /
  `kUninitializedPlayerId`, and the video widget is now built with
  `buildViewWithOptions()`. This resolves the last deprecation warning against
  `video_player_platform_interface` 6.9.0 and prepares the package for its
  next major.
- Code that `implements VideoPlayerHdrController` (e.g. hand-written fakes or
  generated mocks) must add the new `viewType` getter.

Not changed (deliberately): `VideoPlayerHdrController.network` remains
deprecated-but-present (as in upstream), and the widget names shared with
upstream (`VideoProgressIndicator`, `VideoScrubber`, `ClosedCaption`,
`VideoProgressColors`) keep their names — use an import `hide`/`as` clause if
you import both packages.

## 1.2.0
- Adds audio track selection, matching upstream `video_player` 2.11.0:
  `getAudioTracks()`, `selectAudioTrack()` and `isAudioTrackSupportAvailable()`
  on `VideoPlayerHdrController`, plus the `VideoAudioTrack` type re-exported
  from the platform interface.
- Adds video track (quality variant) selection — not yet exposed by upstream's
  app-facing package: `getVideoTracks()`, `selectVideoTrack()` and
  `isVideoTrackSupportAvailable()`, plus the `VideoTrack` type. For HLS/DASH
  this allows picking specific variants, including HDR ones.
- `VideoPlayerOptions.backBufferDurationMs` is now passed through to the
  platform implementations, matching upstream `video_player` 2.12.0.
- Honors `VideoPlayerOptions.preventsDisplaySleepDuringVideoPlayback`: adds the
  field to `VideoPlayerHdrValue` and `setPreventsDisplaySleepDuringVideoPlayback()`
  to the controller, to control whether the display sleeps during playback on
  iOS and macOS, matching upstream `video_player` 2.13.0.

## 1.1.0
- Syncs bug fixes from upstream `video_player` 2.10.1 and 2.11.1:
  - Fixes `VideoPlayerHdr` and `VideoProgressIndicator` no longer updating after
    being reparented in the widget tree with a `GlobalKey`.
  - `VideoProgressIndicator` now handles videos with zero duration instead of
    dividing by zero.
  - Optimizes closed caption lookup with a binary search (adds a dependency on
    `package:collection`).
- Raises dependency lower bounds to the versions the package is developed and
  tested against, matching upstream `video_player` 2.13.0:
  `video_player_android` ^2.11.0, `video_player_avfoundation` ^2.11.0,
  `video_player_platform_interface` ^6.9.0.
- Updates minimum supported SDK to Flutter 3.44 / Dart 3.12.
- Android: modernizes the plugin build (AGP 8.13, Kotlin 2.3, Java 17,
  compileSdk 36) and raises minSdk from 21 to 24, matching
  `video_player_android`, which already required API 24+ for playback.
- Updates the example app to current Flutter tooling.
- Removes `.gitignore` rules that covered two checked-in example files
  (`project.pbxproj`, `Info.plist`), so `pub publish` no longer warns and the
  published example is complete.

## 1.0.1
- Fixes a crash in `getSupportedHdrFormats()` on Android API < 24: the native side
  returned a boolean instead of a list, causing a cast error in Dart. It now returns
  an empty list.
- Fixes HDR methods on web: they now throw the documented `HdrVideoError` instead of
  crashing with `UnsupportedError` from `dart:io`.
- `getVideoMetadata()` on iOS now honors the controller's `httpHeaders` for network
  videos (previously they were only applied on Android).
- Fixes the iPhone 16 family model identifier mapping (Pro/non-Pro were swapped) and
  adds the iPhone 16e, iPhone 17 family, iPhone 17e and iPhone Air to the HDR format
  detection on iOS.
- Fixes the `@Deprecated` message of `VideoPlayerHdrController.network` to reference
  the correct class name.
- Updates the iOS podspec: version aligned with the package, minimum iOS raised from
  10.0 to 12.0 (Flutter's supported minimum), declares `swift_version`, removes the
  obsolete i386 exclusion, and fixes the homepage URL.

## 1.0.0
- Initial release

