package com.jvai.clevertalk

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.storage.StorageManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Environment
import android.os.storage.StorageVolume
import java.io.File
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "usb_path_reader/usb"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsbDeviceDetails" -> {
                    val usbDetails = getUsbDeviceDetails()
                    if (usbDetails != null) {
                        result.success(usbDetails)
                    } else {
                        result.error("UNAVAILABLE", "No USB devices connected.", null)
                    }
                }
                "getUsbPath" -> {
                    val usbPath = getUsbPath()
                    if (usbPath != null) {
                        result.success(usbPath)
                    } else {
                        result.error("UNAVAILABLE", "USB Path not available.", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Function to get USB device details
    private fun getUsbDeviceDetails(): Map<String, String>? {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList: HashMap<String, UsbDevice>? = usbManager.deviceList

        if (!deviceList.isNullOrEmpty()) {
            // Assuming the first USB device in the list
            val device = deviceList.values.first()

            val deviceName = device.deviceName // Device name
            val vendorId = device.vendorId.toString() // Vendor ID
            val productId = device.productId.toString() // Product ID
            val deviceUUID = "${vendorId}_${productId}_${deviceName.hashCode()}" // Generate a unique UUID-like string

            return mapOf(
                "deviceName" to deviceName,
                "vendorId" to vendorId,
                "productId" to productId,
                "deviceUUID" to deviceUUID
            )
        }
        return null
    }

    private fun getUsbPath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes = storageManager.storageVolumes

        for (volume in storageVolumes) {
            if (volume.isRemovable) {
                val path = volume.directory?.absolutePath
                Log.d(TAG, "Checking removable volume: $path")
                if (path != null) {
                    if (path.contains("usb", ignoreCase = true) || path.contains("otg", ignoreCase = true)) {
                        Log.d(TAG, "USB path found: $path")
                        return path
                    }
                    val file = File(path)
                    if (file.exists() && file.canRead()) {
                        Log.d(TAG, "Accessible removable path found: $path")
                        return path
                    }
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        val getPathMethod = StorageVolume::class.java.getMethod("getPath")
                        val rawPath = getPathMethod.invoke(volume) as String
                        Log.d(TAG, "Raw path via reflection: $rawPath")
                        if (rawPath.contains("usb", ignoreCase = true) || rawPath.contains("otg", ignoreCase = true)) {
                            return rawPath
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Reflection failed: $e")
                    }
                }
            }
        }
        return null
    }
}