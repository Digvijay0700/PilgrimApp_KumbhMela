package com.example.digisangam

import android.bluetooth.*
import android.content.Context
import android.util.Log
import java.nio.ByteBuffer
import java.util.UUID

class BleGattServerManager(
    private val context: Context,
    private val lat: Double,
    private val lng: Double
) {

    private var gattServer: BluetoothGattServer? = null

    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    companion object {
        val SERVICE_UUID =
            UUID.fromString("0000aaaa-0000-1000-8000-00805f9b34fb")
        val LAT_UUID =
            UUID.fromString("0000aaab-0000-1000-8000-00805f9b34fb")
        val LNG_UUID =
            UUID.fromString("0000aaac-0000-1000-8000-00805f9b34fb")
    }

    fun start() {

        gattServer = bluetoothManager.openGattServer(
            context,
            gattCallback
        )

        val service = BluetoothGattService(
            SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )

        val latChar = BluetoothGattCharacteristic(
            LAT_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ
        )

        val lngChar = BluetoothGattCharacteristic(
            LNG_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ,
            BluetoothGattCharacteristic.PERMISSION_READ
        )

        latChar.value = doubleToBytes(lat)
        lngChar.value = doubleToBytes(lng)

        service.addCharacteristic(latChar)
        service.addCharacteristic(lngChar)

        gattServer?.addService(service)

        Log.d("PILGRIM_GATT", "🟢 GATT server started")
    }

    private val gattCallback = object : BluetoothGattServerCallback() {

        override fun onConnectionStateChange(
            device: BluetoothDevice,
            status: Int,
            newState: Int
        ) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.d("PILGRIM_GATT", "📡 Volunteer connected")
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            gattServer?.sendResponse(
                device,
                requestId,
                BluetoothGatt.GATT_SUCCESS,
                0,
                characteristic.value
            )
        }
    }

    private fun doubleToBytes(value: Double): ByteArray =
        ByteBuffer.allocate(8).putDouble(value).array()
}
