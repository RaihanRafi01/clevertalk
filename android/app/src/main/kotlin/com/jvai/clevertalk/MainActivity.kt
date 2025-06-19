package com.jvai.clevertalk
import android.os.Bundle
import android.view.WindowManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.util.Log
import android.os.Handler
import android.os.Looper
import java.io.File
import androidx.core.app.NotificationCompat
import com.jvai.clevertalk.services.RestartService

class MainActivity : FlutterActivity() {
    private val CHANNEL = "usb_path_reader/usb"
    private val TAG = "MainActivity"
    private val USB_PERMISSION = "com.jvai.clevertalk.USB_PERMISSION"
    private val NOTIFICATION_CHANNEL_ID = "clevertalk_restart_channel"
    private val NOTIFICATION_ID = 1
    private var usbReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Force fullscreen
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        Log.d(TAG, "MainActivity onCreate called")
        // Existing onCreate code
    }

    private fun restartApp() {
        Log.d(TAG, "Attempting to restart app")
        try {
            // Use CLEAR_TOP for API < 11
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
            } else {
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NO_ANIMATION
            }
            val restartIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                addFlags(flags)
            }
            if (restartIntent != null) {
                Log.d(TAG, "Launching restart intent: $restartIntent")
                startActivity(restartIntent)
            } else {
                Log.e(TAG, "Failed to get launch intent for package: $packageName")
            }

            // Start RestartService
            val serviceIntent = Intent(this, RestartService::class.java)
            startService(serviceIntent)
            Log.d(TAG, "RestartService started")

            // Use finish() for API < 16
            Handler(Looper.getMainLooper()).postDelayed({
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                    finishAffinity()
                    Log.d(TAG, "finishAffinity called")
                } else {
                    finish()
                    Log.d(TAG, "finish called")
                }
            }, 100)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart app: $e")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsbDeviceDetails" -> {
                    Log.d(TAG, "Method call: getUsbDeviceDetails")
                    val usbDetails = getUsbDeviceDetails()
                    if (usbDetails != null) {
                        result.success(usbDetails)
                    } else {
                        result.error("UNAVAILABLE", "No USB devices connected.", null)
                    }
                }
                "getUsbPath" -> {
                    Log.d(TAG, "Method call: getUsbPath")
                    val usbPath = getUsbPath()
                    if (usbPath != null) {
                        result.success(usbPath)
                    } else {
                        result.error("UNAVAILABLE", "USB Path not available.", null)
                    }
                }
                "startUsbListener" -> {
                    Log.d(TAG, "Method call: startUsbListener")
                    startUsbListener()
                    result.success(true)
                }
                "restartApp" -> {
                    Log.d(TAG, "Method call: restartApp")
                    restartApp()
                    result.success(true)
                }
                else -> {
                    Log.w(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestUsbPermission(device: UsbDevice) {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val permissionIntent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(USB_PERMISSION),
            PendingIntent.FLAG_IMMUTABLE // Use FLAG_IMMUTABLE for Android 14+ compatibility
        )
        Log.d(TAG, "Requesting USB permission for device: ${device.deviceName}")
        usbManager.requestPermission(device, permissionIntent)
    }

    private fun startUsbListener() {
        Log.d(TAG, "Starting USB listener")
        if (usbReceiver != null) {
            Log.d(TAG, "Unregistering existing USB receiver")
            try {
                unregisterReceiver(usbReceiver)
                Log.d(TAG, "Existing USB receiver unregistered")
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering existing receiver: $e")
            }
            usbReceiver = null
        }

        usbReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                Log.d(TAG, "Broadcast received: ${intent.action}")
                when (intent.action) {
                    UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                        val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                        if (device != null) {
                            Log.d(TAG, "USB Device Attached: ${device.deviceName}, VendorID: ${device.vendorId}, ProductID: ${device.productId}")
                            requestUsbPermission(device)
                            val details = mapOf(
                                "deviceName" to device.deviceName,
                                "vendorId" to device.vendorId.toString(),
                                "productId" to device.productId.toString(),
                                "deviceUUID" to "${device.vendorId}_${device.productId}_${device.deviceName.hashCode()}"
                            )
                            methodChannel?.invokeMethod("onUsbAttached", details)
                        } else {
                            Log.w(TAG, "No device found in ACTION_USB_DEVICE_ATTACHED")
                        }
                    }
                    UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                        val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                        Log.d(TAG, "USB Device Detached: ${device?.deviceName}")
                        methodChannel?.invokeMethod("onUsbDetached", null)
                    }
                    USB_PERMISSION -> {
                        val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        Log.d(TAG, "USB Permission for ${device?.deviceName}: $granted")
                        if (granted && device != null) {
                            methodChannel?.invokeMethod("onUsbPermissionGranted", mapOf(
                                "deviceName" to device.deviceName
                            ))
                        } else {
                            Log.w(TAG, "USB Permission denied or device null")
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            addAction(USB_PERMISSION)
            priority = 100 // Higher priority for timely delivery
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(usbReceiver, filter, RECEIVER_EXPORTED)
            } else {
                registerReceiver(usbReceiver, filter)
            }
            Log.d(TAG, "USB receiver registered successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register USB receiver: $e")
        }

        // Check for already connected devices
        checkExistingDevices()
    }

    private fun checkExistingDevices() {
        Log.d(TAG, "Checking for existing USB devices")
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList: HashMap<String, UsbDevice>? = usbManager.deviceList
        if (!deviceList.isNullOrEmpty()) {
            val device = deviceList.values.first()
            Log.d(TAG, "Found existing USB device: ${device.deviceName}")
            requestUsbPermission(device)
            val details = mapOf(
                "deviceName" to device.deviceName,
                "vendorId" to device.vendorId.toString(),
                "productId" to device.productId.toString(),
                "deviceUUID" to "${device.vendorId}_${device.productId}_${device.deviceName.hashCode()}"
            )
            methodChannel?.invokeMethod("onUsbAttached", details)
        } else {
            Log.d(TAG, "No existing USB devices found")
        }
    }

    private fun getUsbDeviceDetails(): Map<String, String>? {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val deviceList: HashMap<String, UsbDevice>? = usbManager.deviceList

        if (!deviceList.isNullOrEmpty()) {
            val device = deviceList.values.first()
            Log.d(TAG, "USB Device Details: ${device.deviceName}, VendorID: ${device.vendorId}, ProductID: ${device.productId}")
            return mapOf(
                "deviceName" to device.deviceName,
                "vendorId" to device.vendorId.toString(),
                "productId" to device.productId.toString(),
                "deviceUUID" to "${device.vendorId}_${device.productId}_${device.deviceName.hashCode()}"
            )
        }
        Log.w(TAG, "No USB devices found")
        return null
    }

    private fun getUsbPath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes: List<StorageVolume> = storageManager.storageVolumes

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
        Log.w(TAG, "No USB path found")
        return null
    }

    override fun onDestroy() {
        Log.d(TAG, "Unregistering USB receiver in onDestroy")
        usbReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "USB receiver unregistered")
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering receiver: $e")
            }
        }
        super.onDestroy()
    }
}