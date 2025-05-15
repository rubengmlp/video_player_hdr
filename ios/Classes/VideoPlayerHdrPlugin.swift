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
        // In iOS, HDR is supported if the device supports Wide Color Gamut
        return isWideColorGamutSupported(result: result)
    }
    
    private func getSupportedHdrFormats(result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            let screen = UIScreen.main
            var formats: [String] = []
            
            // P3 color space is a requirement for any HDR support
            if screen.traitCollection.displayGamut == .P3 {
                // All devices with P3 support HDR10
                formats.append("HDR10")
                
                // Detect the model to determine Dolby Vision support
                let deviceModel = UIDevice.current.modelName
                
                // Devices with OLED screens support Dolby Vision
                if deviceModel.contains("iPhone X") && !deviceModel.contains("iPhone XR") ||
                   deviceModel.contains("iPhone 11 Pro") ||
                   deviceModel.contains("iPhone 12") || 
                   deviceModel.contains("iPhone 13") || 
                   deviceModel.contains("iPhone 14") || 
                   deviceModel.contains("iPhone 15") ||
                   deviceModel.contains("iPhone 16") {  
                    formats.append("Dolby Vision")
                }
                
                // HLG is supported on most recent devices with HDR capability
                if deviceModel.contains("iPhone 11") || 
                   deviceModel.contains("iPhone 12") || 
                   deviceModel.contains("iPhone 13") || 
                   deviceModel.contains("iPhone 14") || 
                   deviceModel.contains("iPhone 15") ||
                   deviceModel.contains("iPhone 16") {  
                    formats.append("HLG")
                }
            }
            
            result(formats)
        } else {
            result([])
        }
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

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Map device identifiers to commercial names of iPhones
        switch identifier {
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16"
        case "iPhone17,2": return "iPhone 16 Plus"
        case "iPhone17,3": return "iPhone 16 Pro"
        case "iPhone17,4": return "iPhone 16 Pro Max"
        default: return identifier
        }
    }
}
