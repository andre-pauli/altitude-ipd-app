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
    
    // Buffer handling variables
    private var jsonBuffer = StringBuilder()
    private var lastProcessedTime = 0L
    private val BUFFER_TIMEOUT = 500L // 500ms de timeout
    private var lastChunkTime = 0L
    private val CHUNK_TIMEOUT = 100L // 100ms entre chunks

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
                        
                        val currentTime = System.currentTimeMillis()
                        
                        // Se passou muito tempo desde o último chunk, limpa o buffer
                        if (currentTime - lastChunkTime > CHUNK_TIMEOUT) {
                            Log.d("SERIAL_BUFFER", "Muito tempo desde o último chunk, limpando buffer")
                            jsonBuffer = StringBuilder()
                        }
                        lastChunkTime = currentTime
                        
                        // Adiciona o novo dado ao buffer
                        jsonBuffer.append(read)
                        val bufferContent = jsonBuffer.toString()
                        
                        // Procura por JSONs completos no buffer
                        var startIndex = bufferContent.indexOf("{")
                        while (startIndex != -1) {
                            var endIndex = findMatchingBrace(bufferContent, startIndex)
                            if (endIndex == -1) {
                                break
                            }
                            
                            val potentialJson = bufferContent.substring(startIndex, endIndex + 1)
                            if (isValidJson(potentialJson)) {
                                Log.d("SERIAL_BUFFER", "JSON válido encontrado: $potentialJson")
                                eventSink?.success(potentialJson)
                                // Remove o JSON processado do buffer
                                jsonBuffer = StringBuilder(bufferContent.substring(endIndex + 1))
                                lastProcessedTime = currentTime
                                break
                            }
                            
                            startIndex = bufferContent.indexOf("{", startIndex + 1)
                        }
                        
                        // Se o buffer estiver muito grande, limpa
                        if (bufferContent.length > 2000) {
                            Log.d("SERIAL_BUFFER", "Buffer muito grande, limpando")
                            jsonBuffer = StringBuilder()
                            lastProcessedTime = currentTime
                        }
                    } catch (e: Exception) {
                        Log.e("SERIAL_RECEIVED", "Erro ao processar mensagem: ${e.message}")
                        jsonBuffer = StringBuilder()
                        lastProcessedTime = System.currentTimeMillis()
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
    }

    private fun isValidJson(json: String): Boolean {
        return try {
            JSONObject(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun findMatchingBrace(str: String, startIndex: Int): Int {
        var count = 0
        for (i in startIndex until str.length) {
            when (str[i]) {
                '{' -> count++
                '}' -> {
                    count--
                    if (count == 0) return i
                }
            }
        }
        return -1
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
