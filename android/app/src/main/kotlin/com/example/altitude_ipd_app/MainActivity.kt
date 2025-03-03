package com.example.altitude_ipd_app

import android.os.Bundle
import android.util.Log
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android_serialport_api.hyperlcd.BaseReader
import android_serialport_api.hyperlcd.SerialEnums
import android_serialport_api.hyperlcd.SerialPortManager
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.altitude_ipd_app/channel"
    private val EVENT_CHANNEL = "com.example.altitude_ipd_app/receive_channel"
    private val spManager = SerialPortManager.getInstances()
    private lateinit var baseReader: BaseReader
    private var eventSink: EventChannel.EventSink? = null
    private val isAscii = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableKioskMode() // Habilita o modo quiosque ao criar a atividade
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Configura o MethodChannel para envio de mensagens
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendMessage" -> {
                    val message = call.arguments<String>()
                    sendMessageToPort(message)
                    result.success("Mensagem enviada: $message")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Configura o EventChannel para recepção contínua de mensagens
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Configura o leitor para a porta em UTF-8
        baseReader = object : BaseReader() {
            override fun onParse(port: String, isAscii: Boolean, read: String) {
                runOnUiThread {
                    try {
                        Log.d("SERIAL_RECEIVED", "Recebido em hexadecimal: $read")
//                        val utf8Message = hexToUtf8String(read)
//                        Log.d("SERIAL_RECEIVED", "Mensagem recebida (UTF-8): $utf8Message")

                        // Verifica se a mensagem é um JSON válido antes de enviar ao Flutter
                        if (isValidJson(read)) {
                            eventSink?.success(read)
                        } else {
                            Log.e("SERIAL_RECEIVED", "Mensagem recebida não é um JSON válido: $read")
                        }
                    } catch (e: Exception) {
                        Log.e("SERIAL_RECEIVED", "Erro ao decodificar mensagem: ${e.message}")
                    }
                }
            }
        }

        // Inicia a porta com o leitor, fixado em UTF-8
        val baudrate = 9600
        spManager.startSerialPort(SerialEnums.Ports.ttyS0, isAscii, baudrate, 0, baseReader)
    }

    override fun onResume() {
        super.onResume()
        enableKioskMode() // Reativa o modo quiosque quando a atividade volta ao foco
    }

    private fun enableKioskMode() {
        val decorView = window.decorView
        decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                )

        decorView.setOnSystemUiVisibilityChangeListener { visibility ->
            if ((visibility and View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
                decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                or View.SYSTEM_UI_FLAG_FULLSCREEN
                                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        )
            }
        }
    }

    private fun hexToUtf8String(hex: String): String {
        return try {
            val bytes = hex.chunked(2)
                .map { it.toInt(16).toByte() }
                .toByteArray()
            String(bytes, Charsets.UTF_8)
        } catch (e: Exception) {
            Log.e("SERIAL_CONVERSION", "Erro ao converter hexadecimal para UTF-8: ${e.message}")
            ""
        }
    }

    private fun isValidJson(json: String): Boolean {
        return try {
            JSONObject(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun sendMessageToPort(message: String?) {
        message?.let {
            // Verifica se a mensagem é um JSON válido antes de enviar
            if (isValidJson(it)) {
                spManager.send(SerialEnums.Ports.ttyS0, isAscii, it)
                Log.d("SERIAL_SENT", "Mensagem enviada para porta: $it")
            } else {
                Log.e("SERIAL_SENT", "Mensagem não é um JSON válido: $it")
            }
        }
    }
}
