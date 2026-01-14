package com.example.digisangam

import android.Manifest
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ble_gatt_channel"
    private var gattServer: BleGattServerManager? = null

    // List of permissions needed for Android 12+ and older versions
    private val blePermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        arrayOf(
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    } else {
        arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startSOS") {
                // 1. Check if permissions are granted
                if (!hasPermissions()) {
                    ActivityCompat.requestPermissions(this, blePermissions, 101)
                    result.error("PERMISSION_DENIED", "Please grant Bluetooth and Location permissions", null)
                    return@setMethodCallHandler
                }

                // 2. Get location with fallback
                val location = getLocation()
                val lat = location?.latitude ?: 25.4484 
                val lng = location?.longitude ?: 81.8837

                // 3. Start BLE
                try {
                    EmergencyBleAdvertiser().start()
                    gattServer = BleGattServerManager(this, lat, lng)
                    gattServer?.start()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("BLE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun hasPermissions(): Boolean {
        return blePermissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun getLocation(): android.location.Location? {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) return null

        val lm = getSystemService(LOCATION_SERVICE) as LocationManager
        return lm.getLastKnownLocation(LocationManager.GPS_PROVIDER) 
            ?: lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
    }
}