package com.jvai.clevertalk

import android.content.Intent
import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.storage.StorageManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentResolver
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import android.os.storage.StorageVolume



class MainActivity : FlutterActivity() {
    private val CHANNEL = "usb_path_reader/usb"

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
                "getFolderPath" -> {
                    val uriStr = call.argument<String>("uri")
                    val uri = Uri.parse(uriStr)
                    val resolvedPath = getRealPathFromURI(uri)
                    result.success(resolvedPath)
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

    // Function to get USB storage path
    private fun getUsbPath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes = storageManager.storageVolumes

        // Iterate in reverse to prioritize recently connected devices
        for (volume in storageVolumes.reversed()) {
            if (volume.isRemovable) {
                // Heuristic 1: Check volume description for "USB"
                val description = volume.getDescription(this).lowercase()
                if ("usb" in description) {
                    return volume.directory?.absolutePath ?: "/storage/${volume.uuid}"
                }

                // Heuristic 2: Check if path contains USB identifiers
                val path = volume.directory?.absolutePath?.lowercase() ?: ""
                if (path.contains("usb") || path.contains("otg")) {
                    return path
                }

                // Heuristic 3: Use reflection to check raw system path
                val systemPath = try {
                    val getPathMethod = StorageVolume::class.java.getMethod("getPath")
                    getPathMethod.invoke(volume) as String
                } catch (e: Exception) {
                    null
                }

                if (systemPath?.lowercase()?.contains("usb") == true) {
                    return volume.directory?.absolutePath ?: systemPath
                }
            }
        }
        return null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_OPEN_DOCUMENT_TREE && resultCode == RESULT_OK) {
            val treeUri = data?.data
            if (treeUri != null) {
                // Take persistent permissions
                contentResolver.takePersistableUriPermission(
                    treeUri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )

                // Resolve the URI to a real path
                val resolvedPath = getRealPathFromURI(treeUri)

                // Send the resolved path to Flutter
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("onFolderSelected", resolvedPath)
            }
        }
    }

    private fun getRealPathFromURI(uri: Uri): String {
        return if (DocumentsContract.isTreeUri(uri)) {
            val docId = DocumentsContract.getTreeDocumentId(uri)
            val parts = docId.split(":").toTypedArray()
            if (parts.size >= 2) {
                "/storage/${parts[0]}/${parts[1]}"
            } else {
                docId
            }
        } else {
            uri.path ?: ""
        }
    }

    companion object {
        private const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 1
    }
}
