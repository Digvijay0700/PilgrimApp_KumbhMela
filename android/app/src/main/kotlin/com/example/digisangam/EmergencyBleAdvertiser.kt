package com.example.digisangam

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.*
import android.os.ParcelUuid
import android.util.Log
import java.util.UUID

class EmergencyBleAdvertiser {

    private val advertiser =
        BluetoothAdapter.getDefaultAdapter().bluetoothLeAdvertiser

    fun start() {

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true) // REQUIRED for GATT
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(
                ParcelUuid(
                    UUID.fromString("0000aaaa-0000-1000-8000-00805f9b34fb")
                )
            )
            .build()

        advertiser.startAdvertising(settings, data, callback)

        Log.d("PILGRIM_BLE", "🚨 SOS Advertisement started")
    }

    private val callback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            Log.d("PILGRIM_BLE", "Advertisement success")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e("PILGRIM_BLE", "Advertise failed: $errorCode")
        }
    }
}
