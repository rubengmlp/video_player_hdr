import Flutter
import UIKit
import AVFoundation

public class VideoPlayerHdrPlugin: NSObject, FlutterPlugin {
    private static var registrar: FlutterPluginRegistrar?

    public static func register(with registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        let channel = FlutterMethodChannel(name: "video_player_hdr", binaryMessenger: registrar.messenger())
        let instance = VideoPlayerHdrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isHdrSupported":
            isHdrSupported(result: result)
        case "getSupportedHdrFormats":
            getSupportedHdrFormats(result: result)
        case "isWideColorGamutSupported":
            isWideColorGamutSupported(result: result)
        case "getVideoMetadata":
            if #available(iOS 15.0, *) {
                if let args = call.arguments as? [String: Any],
                           let filePath = args["filePath"] as? String {
                            let httpHeaders = args["httpHeaders"] as? [String: String]
                            getVideoMetadata(filePath: filePath, httpHeaders: httpHeaders, result: result)
                        } else {
                            result(FlutterError(code: "INVALID_ARGUMENT",
                                              message: "File path is required and must be a string",
                                              details: nil))
                        }
            } else {
                result(FlutterError(code: "NOT_SUPPORTED",
                                    message: "This feature is only supported on iOS 15.0 and above",
                                    details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isHdrSupported(result: @escaping FlutterResult) {
        if #available(iOS 13.4, *) {
            result(AVPlayer.eligibleForHDRPlayback)
        } else {
            result(!AVPlayer.availableHDRModes.isEmpty)
        }
    }

    private func getSupportedHdrFormats(result: @escaping FlutterResult) {
        let modes = AVPlayer.availableHDRModes
        var formats: [String] = []
        if modes.contains(.hdr10) { formats.append("hdr10") }
        if modes.contains(.dolbyVision) { formats.append("dolby_vision") }
        if modes.contains(.hlg) { formats.append("hlg") }
        result(formats)
    }

    private func isWideColorGamutSupported(result: @escaping FlutterResult) {
        result(UIScreen.main.traitCollection.displayGamut == .P3)
    }

    // Values use the same names as the Android plugin so metadata matches across platforms.
    private static let colorStandards: [String: String] = [
        kCMFormatDescriptionColorPrimaries_ITU_R_2020 as String: "BT2020",
        kCMFormatDescriptionColorPrimaries_ITU_R_709_2 as String: "BT709",
        kCMFormatDescriptionColorPrimaries_SMPTE_C as String: "BT601_NTSC",
        kCMFormatDescriptionColorPrimaries_EBU_3213 as String: "BT601_PAL",
    ]

    private static let colorTransfers: [String: String] = [
        kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG as String: "HLG",
        kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ as String: "ST2084",
        kCMFormatDescriptionTransferFunction_ITU_R_709_2 as String: "SDR_VIDEO",
        kCMFormatDescriptionTransferFunction_ITU_R_2020 as String: "SDR_VIDEO",
        kCMFormatDescriptionTransferFunction_Linear as String: "LINEAR",
    ]
    
    @available(iOS 15.0, *)
    private func getVideoMetadata(filePath: String, httpHeaders: [String: String]?, result: @escaping FlutterResult) {
        // Check if the file is HLS or DASH
        if (filePath.hasSuffix(".m3u8") || filePath.hasSuffix(".mpd")) && (filePath.hasPrefix("http://") || filePath.hasPrefix("https://")) {
            let streamingFormat = filePath.hasSuffix(".m3u8") ? "HLS" : "DASH"
            result(FlutterError(code: "STREAMING_METADATA_UNSUPPORTED",
                                message: "Cannot extract metadata from streaming formats (\(streamingFormat))",
                                details: nil))
            return
        }

        var assetURL: URL?

         if filePath.hasPrefix("asset://") {
            let assetName = String(filePath.dropFirst(8))

            guard let registrar = VideoPlayerHdrPlugin.registrar else {
        result(FlutterError(code: "NO_REGISTRAR",
                            message: "Registrar not available",
                            details: nil))
        return
    }
            
            let key = registrar.lookupKey(forAsset: assetName)

            if let path = Bundle.main.path(forResource: key, ofType: nil) {
                assetURL = URL(fileURLWithPath: path)
            } else {
                result(FlutterError(code: "ASSET_NOT_FOUND",
                                    message: "Asset not found: \(assetName)",
                                    details: nil))
                return
            }
        }  else if filePath.hasPrefix("file://") {
                    assetURL = URL(string: filePath)
                } else if filePath.hasPrefix("http://") || filePath.hasPrefix("https://") {
                    assetURL = URL(string: filePath)
                } else {
                    assetURL = URL(fileURLWithPath: filePath)
                }
                
                guard let url = assetURL else {
                    result(FlutterError(code: "INVALID_PATH",
                                      message: "Could not create URL from path",
                                      details: nil))
                    return
                }
        
        let asset: AVAsset
        if let httpHeaders = httpHeaders, !httpHeaders.isEmpty,
           url.scheme == "http" || url.scheme == "https" {
            asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": httpHeaders])
        } else {
            asset = AVAsset(url: url)
        }
    
    Task {
        do {
            let duration = try await asset.load(.duration)

            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_VIDEO_TRACK",
                                      message: "No video track found in the asset",
                                      details: nil))
                }
                return
            }
            
            var videoMetadata: [String: Any] = [:]
            
            // Dimensions
            let size = videoTrack.naturalSize
            videoMetadata["width"] = Int(size.width)
            videoMetadata["height"] = Int(size.height)
            
            // Duration (in milliseconds)
            let durationSeconds = CMTimeGetSeconds(duration)
            videoMetadata["duration"] = Int64(durationSeconds * 1000)
            
            // Framerate
            videoMetadata["frameRate"] = Float(videoTrack.nominalFrameRate)
            
            // Rotation
            let transform = videoTrack.preferredTransform
            let angle = atan2(transform.b, transform.a)
            let degrees = angle * 180 / .pi
            // atan2 yields -180...180; report 0...359 like Android
            videoMetadata["rotation"] = (Int(degrees.rounded()) + 360) % 360
            
            // Bitrate
            videoMetadata["bitrate"] = Int(videoTrack.estimatedDataRate)
            
            // HDR information
        
                if let formatDescriptions = videoTrack.formatDescriptions as? [CMFormatDescription],
                   let format = formatDescriptions.first {
                    let colorPrimaries = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_ColorPrimaries)
                    let transferFunction = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_TransferFunction)
                    let fullRange = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_FullRangeVideo)

                    videoMetadata["colorStandard"] = (colorPrimaries as? String).flatMap { Self.colorStandards[$0] }
                    videoMetadata["colorTransfer"] = (transferFunction as? String).flatMap { Self.colorTransfers[$0] }
                    videoMetadata["colorRange"] = (fullRange as? Bool).map { $0 ? "FULL" : "LIMITED" }
                }
            
            DispatchQueue.main.async {
                result(videoMetadata)
            }
            
        } catch {
            DispatchQueue.main.async {
                result(FlutterError(code: "METADATA_ERROR",
                                  message: "Error loading video metadata: \(error.localizedDescription)",
                                  details: nil))
            }
        }
    }
    }
}
