package com.example.digisangam

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.*
import android.os.ParcelUuid
import android.util.Log
import java.util.UUID

class EmergencyBleAdvertiser {

    private val advertiser: BluetoothLeAdvertiser? =
        BluetoothAdapter.getDefaultAdapter()?.bluetoothLeAdvertiser

    private var advertiseCallback: AdvertiseCallback? = null

    // 🚨 START SOS ADVERTISEMENT
    fun start() {
        if (advertiseCallback != null) {
            Log.d("PILGRIM_BLE", "⚠️ SOS already broadcasting")
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true) // REQUIRED for GATT
            .setTimeout(0) // infinite
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(
                ParcelUuid(
                    UUID.fromString("0000aaaa-0000-1000-8000-00805f9b34fb")
                )
            )
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                Log.d("PILGRIM_BLE", "🚨 SOS Advertisement started")
            }

            override fun onStartFailure(errorCode: Int) {
                Log.e("PILGRIM_BLE", "❌ Advertise failed: $errorCode")
            }
        }

        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    // 🛑 STOP SOS ADVERTISEMENT
    fun stop() {
        advertiseCallback?.let {
            advertiser?.stopAdvertising(it)
            Log.d("PILGRIM_BLE", "🛑 SOS Advertisement stopped")
        }
        advertiseCallback = null
    }
}
