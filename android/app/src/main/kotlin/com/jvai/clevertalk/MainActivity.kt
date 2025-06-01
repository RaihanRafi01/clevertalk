package com.jvai.clevertalk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.storage.StorageManager
import android.os.storage.StorageVolume // Added missing import
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.util.Log
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "usb_path_reader/usb"
    private val TAG = "MainActivity"
    private var usbReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
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
                "startUsbListener" -> {
                    startUsbListener()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startUsbListener() {
        usbReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                        Log.d(TAG, "USB Device Attached")
                        val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                        if (device != null) {
                            val details = mapOf(
                                "deviceName" to device.deviceName,
                                "vendorId" to device.vendorId.toString(),
                                "productId" to device.productId.toString(),
                                "deviceUUID" to "${device.vendorId}_${device.productId}_${device.deviceName.hashCode()}"
                            )
                            methodChannel?.invokeMethod("onUsbAttached", details)
                        }
                    }
                    UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                        Log.d(TAG, "USB Device Detached")
                        methodChannel?.invokeMethod("onUsbDetached", null)
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        registerReceiver(usbReceiver, filter)
    }

    private fun getUsbDeviceDetails(): Map<String, String>? {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList: HashMap<String, UsbDevice>? = usbManager.deviceList

        if (!deviceList.isNullOrEmpty()) {
            val device = deviceList.values.first()
            return mapOf(
                "deviceName" to device.deviceName,
                "vendorId" to device.vendorId.toString(),
                "productId" to device.productId.toString(),
                "deviceUUID" to "${device.vendorId}_${device.productId}_${device.deviceName.hashCode()}"
            )
        }
        return null
    }

    private fun getUsbPath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes: List<StorageVolume> = storageManager.storageVolumes // Explicit type annotation

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
                        // Use direct access instead of reflection if possible
                        val rawPath = volume.directory?.absolutePath
                        if (rawPath != null && (rawPath.contains("usb", ignoreCase = true) || rawPath.contains("otg", ignoreCase = true))) {
                            Log.d(TAG, "Raw path: $rawPath")
                            return rawPath
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to get path: $e")
                    }
                }
            }
        }
        return null
    }

    override fun onDestroy() {
        usbReceiver?.let { unregisterReceiver(it) }
        super.onDestroy()
    }
}