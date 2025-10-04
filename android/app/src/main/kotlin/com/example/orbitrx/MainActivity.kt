package com.example.orbitrx

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "orbitrx/bluetooth"
	private val REQUEST_ENABLE_BT = 1001
	private var pendingResult: MethodChannel.Result? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		flutterEngine.dartExecutor.binaryMessenger?.let { messenger ->
			MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
				if (call.method == "requestEnableBluetooth") {
					pendingResult = result
					requestEnableBluetooth()
				} else {
					result.notImplemented()
				}
			}
		}
	}

	private fun requestEnableBluetooth() {
		val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
		if (bluetoothAdapter == null) {
			pendingResult?.success(false)
			pendingResult = null
			return
		}

		if (bluetoothAdapter.isEnabled) {
			pendingResult?.success(true)
			pendingResult = null
			return
		}

		val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
		startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT)
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode == REQUEST_ENABLE_BT) {
			val enabled = resultCode == Activity.RESULT_OK
			pendingResult?.success(enabled)
			pendingResult = null
		}
	}
}
