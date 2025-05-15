import Flutter
import UIKit
import AVFoundation

public class VideoPlayerHdrPlugin: NSObject, FlutterPlugin {
    private static var registrar: FlutterPluginRegistrar?

    public static func register(with registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        let channel = FlutterMethodChannel(name: "video_player_hdr/hdr_control", binaryMessenger: registrar.messenger())
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
                            getVideoMetadata(filePath: filePath, result: result)
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
        
    }
    
    private func getSupportedHdrFormats(result: @escaping FlutterResult) {
        
    }
    
    private func isWideColorGamutSupported(result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            let screen = UIScreen.main
            // Check if the display supports Wide Color (P3 color space)
            result(screen.traitCollection.displayGamut == .P3)
        } else {
            result(false)
        }
    }
    
    @available(iOS 15.0, *)
    private func getVideoMetadata(filePath: String, result: @escaping FlutterResult) {
        var assetURL: URL?

         if filePath.hasPrefix("asset://") {
            let assetName = String(filePath.dropFirst(8))
            print("Looking up asset: \(assetName)")

            guard let registrar = VideoPlayerHdrPlugin.registrar else {
        result(FlutterError(code: "NO_REGISTRAR",
                            message: "Registrar not available",
                            details: nil))
        return
    }
            
            let key = registrar.lookupKey(forAsset: assetName)
            print("Asset key: \(key)")
            
            if let path = Bundle.main.path(forResource: key, ofType: nil) {
                assetURL = URL(fileURLWithPath: path)
                print("Asset URL created: \(assetURL?.absoluteString ?? "nil")")
            } else {
                result(FlutterError(code: "ASSET_NOT_FOUND",
                                    message: "Asset not found: \(assetName)",
                                    details: nil))
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
        
        let asset = AVAsset(url: url)
    
    Task {
        do {
            try await _ = asset.load(.duration, .tracks)
            
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                result(FlutterError(code: "NO_VIDEO_TRACK",
                                  message: "No video track found in the asset",
                                  details: nil))
                return
            }
            
            var videoMetadata: [String: Any] = [:]
            
            // Dimensions
            let size = videoTrack.naturalSize
            videoMetadata["width"] = Int(size.width)
            videoMetadata["height"] = Int(size.height)
            
            // Duration (in milliseconds)
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            videoMetadata["duration"] = Int64(durationSeconds * 1000)
            
            // Framerate
            videoMetadata["frameRate"] = Float(videoTrack.nominalFrameRate)
            
            // Rotation
            let transform = videoTrack.preferredTransform
            let angle = atan2(transform.b, transform.a)
            let degrees = angle * 180 / .pi
            videoMetadata["rotation"] = Int(degrees)
            
            // Bitrate
            videoMetadata["bitrate"] = Int(videoTrack.estimatedDataRate)
            
            // HDR information
        
                if let formatDescriptions = videoTrack.formatDescriptions as? [CMFormatDescription],
                   let format = formatDescriptions.first {
                    let colorPrimaries = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_ColorPrimaries)
                    let transferFunction = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_TransferFunction)
                    let colorMatrix = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_YCbCrMatrix)
                    
                    videoMetadata["colorStandard"] = colorPrimaries as? String
                    videoMetadata["colorTransfer"] = transferFunction as? String
                    videoMetadata["colorRange"] = colorMatrix as? String
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
