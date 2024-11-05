package com.example.altitude_ipd_app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android_serialport_api.hyperlcd.BaseReader
import android_serialport_api.hyperlcd.SerialEnums
import android_serialport_api.hyperlcd.SerialPortManager
import java.nio.charset.StandardCharsets

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.altitude_ipd_app/channel"
    private val EVENT_CHANNEL = "com.example.altitude_ipd_app/receive_channel"
    private val spManager = SerialPortManager.getInstances()
    private lateinit var baseReader0: BaseReader
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Configura o MethodChannel para envio de mensagens
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendMessage" -> {
                    val message = call.arguments<String>()
                    sendMessageToPort0(message)
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

        // Configura o leitor para a porta 0 em UTF-8
        baseReader0 = object : BaseReader() {
            override fun onParse(port: String, isAscii: Boolean, read: String) {
                runOnUiThread {
                    try {
                        // Converte o conteúdo recebido diretamente para UTF-8
                        val utf8Message = String(read.toByteArray(Charsets.UTF_8), Charsets.UTF_8)
                        Log.d("SERIAL_RECEIVED_0", "Mensagem recebida (UTF-8): $utf8Message")
                        eventSink?.success(utf8Message) // Envia a mensagem decodificada para o Flutter
                    } catch (e: Exception) {
                        Log.e("SERIAL_RECEIVED_0", "Erro ao decodificar mensagem: ${e.message}")
                    }
                }
            }
        }

        // Inicia a porta 0 com o leitor, fixado em UTF-8
        val baudrate0 = 115200
        spManager.startSerialPort(SerialEnums.Ports.ttyS0, false, baudrate0, 0, baseReader0)
    }

    private fun sendMessageToPort0(message: String?) {
        message?.let {
            // Converte a mensagem para bytes UTF-8 e envia
            val utf8Bytes = it.toByteArray(StandardCharsets.UTF_8)
            spManager.send(SerialEnums.Ports.ttyS0, false, String(utf8Bytes, StandardCharsets.ISO_8859_1))
            Log.d("SERIAL_SENT_0", "Mensagem enviada para porta 0: $it")
        }
    }
}
