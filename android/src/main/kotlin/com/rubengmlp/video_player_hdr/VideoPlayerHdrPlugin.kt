package com.rubengmlp.video_player_hdr

import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.view.Display
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** VideoPlayerHdrPlugin */
class VideoPlayerHdrPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_player_hdr/hdr_control")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isHdrSupported" -> isHdrSupported(result)
            "getSupportedHdrFormats" -> getSupportedHdrFormats(result)
            "getColorInfo" -> getColorInfo(result)
            "getHdrStaticInfo" -> getHdrStaticInfo(result)
            "setPreferredHdrMode" -> setPreferredHdrMode(call, result)
            "getPreferredHdrMode" -> getPreferredHdrMode(result)
            "setMaxBitrate" -> setMaxBitrate(call, result)
            else -> result.notImplemented()
        }
    }

    private fun isHdrSupported(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.success(false)
            return
        }

        try {
            val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
            if (display != null) {
                val hdrCapabilities = display.hdrCapabilities
                val supportedHdrTypes = hdrCapabilities.supportedHdrTypes
                result.success(supportedHdrTypes.isNotEmpty())
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("HDR_CHECK_FAILED", "Failed to check HDR support: ${e.message}", null)
        }
    }

    private fun getSupportedHdrFormats(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.success(false)
            return
        }

        try {
            val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
            if (display != null) {
                val hdrCapabilities = display.hdrCapabilities
                val supportedHdrTypes = hdrCapabilities.supportedHdrTypes
                val formats = supportedHdrTypes.mapNotNull { type ->
                    when (type) {
                        Display.HdrCapabilities.HDR_TYPE_DOLBY_VISION -> "dolby_vision"
                        Display.HdrCapabilities.HDR_TYPE_HDR10 -> "hdr10"
                        Display.HdrCapabilities.HDR_TYPE_HLG -> "hlg"
                        // HDR10_PLUS is only available on API 29 and above
                        else -> if (Build.VERSION.SDK_INT >= 29 &&
                            type == Display.HdrCapabilities.HDR_TYPE_HDR10_PLUS
                        ) {
                            "hdr10_plus"
                        } else {
                            null
                        }
                    }
                }
                result.success(formats)
            } else {
                result.success(emptyList<String>())
            }
        } catch (e: Exception) {
                result.error("HDR_FORMATS_FAILED", "Failed to get supported HDR formats: ${e.message}", null)
            }
    }
    
    

    
}
