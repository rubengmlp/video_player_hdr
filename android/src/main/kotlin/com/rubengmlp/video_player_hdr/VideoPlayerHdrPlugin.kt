package com.rubengmlp.video_player_hdr

import android.content.Context
import android.hardware.display.DisplayManager
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.view.Display
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream

/** VideoPlayerHdrPlugin */
class VideoPlayerHdrPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var flutterAssets: FlutterPlugin.FlutterAssets

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        flutterAssets = flutterPluginBinding.flutterAssets
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "video_player_hdr/hdr_control")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isHdrSupported" -> isHdrSupported(result)
            "getSupportedHdrFormats" -> getSupportedHdrFormats(result)
            "isWideColorGamutSupported" -> isWideColorGamutSupported(result)
            "getVideoMetadata" -> getVideoMetadata(call, result)
            else -> result.notImplemented()
        }
    }

    private fun isHdrSupported(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(false)
            return
        }

        try {
            val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
            if (display != null) {
                result.success(display.isHdr)
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
                val formats = supportedHdrTypes.toList().mapNotNull { type ->
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
            result.error(
                "HDR_FORMATS_FAILED",
                "Failed to get supported HDR formats: ${e.message}",
                null
            )
        }
    }

    private fun isWideColorGamutSupported(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(false)
            return
        }

        try {
            val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
            if (display != null) {
                result.success(display.isWideColorGamut)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error(
                "WIDE_COLOR_GAMUT_FAILED",
                "Failed to check wide color gamut support: ${e.message}",
                null
            )
        }

    }

    private fun getVideoMetadata(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")
        val httpHeaders = call.argument<Map<String, String>>("httpHeaders")

        if (filePath == null) {
            result.error("INVALID_ARGUMENT", "File path is required to extract metadata", null)
            return
        }

        // Check if the file is HLS or DASH
        if (filePath.startsWith("http") && (filePath.endsWith(".m3u8") || filePath.endsWith(".mpd"))) {
            val streamingFormat = if (filePath.endsWith(".m3u8")) "HLS" else "DASH"
            result.error(
                "STREAMING_METADATA_UNSUPPORTED",
                "Cannot extract metadata from streaming formats ($streamingFormat)",
                null
            )
            return
        }

        try {
            val metadataRetriever = MediaMetadataRetriever()

            when {
                filePath.startsWith("asset://") -> {
                    val assetPath = filePath.substring(8)
                    val resolvedPath = flutterAssets.getAssetFilePathByName(assetPath)

                    val assetManager = context.assets
                    val inputStream = assetManager.open(resolvedPath)

                    val videoFormat = assetPath.substringAfterLast('.', "")
                    val tempFile = File.createTempFile("temp_video", ".$videoFormat", context.cacheDir)
                    val outputStream = FileOutputStream(tempFile)
                    inputStream.copyTo(outputStream)
                    outputStream.close()
                    inputStream.close()

                    metadataRetriever.setDataSource(
                        tempFile.absolutePath
                    )
                    tempFile.delete()
                }

                filePath.startsWith("file://") -> metadataRetriever.setDataSource(
                    filePath.substring(7)
                )

                filePath.startsWith("http") -> metadataRetriever.setDataSource(
                    filePath,
                    httpHeaders?.toMap() ?: HashMap<String, String>()
                )

                filePath.startsWith("content://") -> metadataRetriever.setDataSource(
                    context,
                    Uri.parse(filePath)
                )

                else -> metadataRetriever.setDataSource(filePath)
            }

            val videoMetadata = HashMap<String, Any?>()

            // Basic video information
            videoMetadata["width"] =
                metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                    ?.toIntOrNull()
            videoMetadata["height"] =
                metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                    ?.toIntOrNull()
            videoMetadata["bitrate"] =
                metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)
                    ?.toIntOrNull()
            videoMetadata["duration"] =
                metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                    ?.toLongOrNull()

            // Rotation
            videoMetadata["rotation"] =
                metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                    ?.toIntOrNull() ?: 0

            // Framerate
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                videoMetadata["frameRate"] =
                    metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)
                        ?.toFloatOrNull()
            }

            // HDR information
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val colorStandard =
                    metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_STANDARD)
                val colorTransfer =
                    metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_TRANSFER)
                val colorRange =
                    metadataRetriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COLOR_RANGE)

                videoMetadata["colorStandard"] = when (colorStandard) {
                    "6" -> "BT2020"
                    "4" -> "BT601_NTSC"
                    "2" -> "BT601_PAL"
                    "1" -> "BT709"
                    else -> "null"
                }

                videoMetadata["colorTransfer"] = when (colorTransfer) {
                    "7" -> "HLG"
                    "6" -> "ST2084"
                    "3" -> "SDR_VIDEO"
                    "1" -> "LINEAR"
                    else -> "null"
                }

                videoMetadata["colorRange"] = when (colorRange) {
                    "2" -> "LIMITED"
                    "1" -> "FULL"
                    else -> "null"
                }
            }

            result.success(videoMetadata)

            metadataRetriever.release()
        } catch (e: Exception) {
            // Check if the exception might be related to streaming formats that weren't detected by extension
            if (filePath.startsWith("http")) {
                result.error(
                    "METADATA_ERROR", 
                    "Error extracting metadata. This might be a streaming format (HLS/DASH) that cannot be processed directly: ${e.message}",
                    null
                )
            } else {
                result.error("METADATA_ERROR", "Error extracting metadata: ${e.message}", null)
            }
        }
    }
}
