import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverUrl = 'ws://quadro-elevador.local:8765';
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 5;
  int _reconnectDelay = 2000; // 2 segundos

  // Callbacks
  Function(Map<String, dynamic>)? onDataReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;

  void setServerUrl(String url) {
    _serverUrl = url;
  }

  Future<void> connect() async {
    if (_isConnected) {
      print('WebSocket já está conectado');
      return;
    }

    try {
      print('Tentando conectar ao WebSocket: $_serverUrl');

      final uri = Uri.parse(_serverUrl);
      final socket = await WebSocket.connect(uri.toString());
      _channel = IOWebSocketChannel(socket);
      _isConnected = true;
      _reconnectAttempts = 0;

      print('WebSocket conectado com sucesso');
      onConnected?.call();

      // Escuta mensagens
      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('Erro no WebSocket: $error');
          _isConnected = false;
          onError?.call(error.toString());
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket desconectado');
          _isConnected = false;
          onDisconnected?.call();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('Erro ao conectar WebSocket: $e');
      onError?.call(e.toString());
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print(
          'Tentativa de reconexão $_reconnectAttempts/$_maxReconnectAttempts em ${_reconnectDelay}ms');

      Future.delayed(Duration(milliseconds: _reconnectDelay), () {
        if (!_isConnected) {
          connect();
        }
      });
    } else {
      print('Número máximo de tentativas de reconexão atingido');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      String message;
      if (data is String) {
        message = data;
      } else {
        message = utf8.decode(data);
      }

      print('Mensagem recebida via WebSocket: $message');

      final Map<String, dynamic> jsonData = jsonDecode(message);
      onDataReceived?.call(jsonData);
    } catch (e) {
      print('Erro ao processar mensagem WebSocket: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      print('WebSocket não está conectado');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      print('Enviando mensagem via WebSocket: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      print('Erro ao enviar mensagem WebSocket: $e');
      onError?.call(e.toString());
    }
  }

  Future<void> sendCommand({
    required String action,
    int? andarDestino,
    Map<String, dynamic>? dados,
  }) async {
    final message = {
      "tipo": "comando",
      "acao": action,
      "andar_destino": andarDestino,
      "dados": dados,
      "timestamp": DateTime.now().toIso8601String(),
    };

    sendMessage(message);
  }

  Future<void> requestInitialData() async {
    await sendCommand(
      action: "buscar_dados_iniciais",
      dados: {"estado": true},
    );
  }

  Future<void> sendGoToFloor(int andarDestino) async {
    await sendCommand(
      action: "ir_para_andar",
      andarDestino: andarDestino,
    );
  }

  Future<void> sendBooleanCommand({
    required String action,
    required bool estado,
  }) async {
    await sendCommand(
      action: action,
      dados: {"estado": estado},
    );
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _reconnectAttempts = 0;
    print('WebSocket desconectado manualmente');
  }

  void dispose() {
    disconnect();
  }
}
