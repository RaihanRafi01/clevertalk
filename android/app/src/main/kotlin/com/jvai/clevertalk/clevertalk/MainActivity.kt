package com.jvai.clevertalk.clevertalk

import android.content.Context
import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.os.storage.StorageManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "usb_path_reader/usb"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getUsbPath") {
                val usbPath = getUsbPath()
                if (usbPath != null) {
                    result.success(usbPath)
                } else {
                    result.error("UNAVAILABLE", "USB Path not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // This function reads the UUID of the connected USB drive
    private fun getUsbPath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes = storageManager.storageVolumes
        for (volume in storageVolumes) {
            if (volume.isRemovable) {  // Checks if the volume is removable (like a USB drive)
                val uuid = volume.uuid
                if (uuid != null) {
                    return "/storage/$uuid"  // Returns the path of the USB drive
                }
            }
        }
        return null  // Return null if no USB is connected
    }
}
