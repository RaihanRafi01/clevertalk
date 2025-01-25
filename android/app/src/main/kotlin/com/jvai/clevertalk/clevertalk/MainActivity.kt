package com.jvai.clevertalk.clevertalk

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "usb_path_reader/usb"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getUsbDeviceDetails") {
                val usbDetails = getUsbDeviceDetails()
                if (usbDetails != null) {
                    result.success(usbDetails)
                } else {
                    result.error("UNAVAILABLE", "No USB devices connected.", null)
                }
            } else {
                result.notImplemented()
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
}

