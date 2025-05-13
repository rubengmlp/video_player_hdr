import Flutter
import UIKit
import AVFoundation

public class VideoPlayerHdrPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
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
} 