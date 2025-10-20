import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class RobustWebSocketService {
  static final RobustWebSocketService _instance =
      RobustWebSocketService._internal();
  factory RobustWebSocketService() => _instance;
  RobustWebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverUrl = 'ws://10.0.0.219:8765';
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 999999; // efetivamente infinito
  int _reconnectDelay = 2000; // base em ms
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  DateTime? _lastHeartbeat;
  DateTime? _lastMessageReceived;

  static const int _heartbeatInterval = 20;
  static const int _heartbeatTimeout = 45;

  Function(Map<String, dynamic>)? onDataReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;
  Function(String)? onStatusChanged;

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;
  DateTime? get lastHeartbeat => _lastHeartbeat;
  DateTime? get lastMessageReceived => _lastMessageReceived;

  void setServerUrl(String url) {
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      url = 'ws://$url';
    }
    _serverUrl = url;
    _log('URL do servidor definida como: $_serverUrl');
  }

  void _log(String message) {
    print('WebSocket: $message');
  }

  void _updateStatus(String status) {
    _log(status);
    onStatusChanged?.call(status);
  }

  Future<void> connect() async {
    if (_isConnected) {
      _log('Já está conectado');
      return;
    }

    _shouldReconnect = true;
    _updateStatus('🔗 Tentando conectar ao servidor: $_serverUrl');

    try {
      final uri = Uri.parse(_serverUrl);
      _log('URI parseada: $uri');

      final socket = await WebSocket.connect(
        uri.toString(),
        compression: CompressionOptions.compressionOff,
      );
      _log('Socket criado com sucesso');

      _channel = IOWebSocketChannel(socket);
      _isConnected = true;
      _reconnectAttempts = 0;

      _updateStatus('🎉 Conectado com sucesso ao servidor');
      onConnected?.call();

      _startHeartbeat();

      _channel!.stream.listen(
        (data) {
          _log('📨 Dados recebidos do servidor');
          _lastMessageReceived = DateTime.now();
          _handleMessage(data);
        },
        onError: (error) {
          _log('❌ Erro na conexão: $error');
          _handleDisconnection('Erro na conexão: $error');
        },
        onDone: () {
          _log('🔌 Conexão fechada pelo servidor');
          _handleDisconnection('Conexão fechada pelo servidor');
        },
      );
    } catch (e) {
      _log('❌ Erro ao conectar: $e');
      _updateStatus('💡 Verifique se o servidor está rodando e acessível');
      onError?.call(e.toString());
      _scheduleReconnect();
    }
  }

  void _handleDisconnection(String reason) {
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();

    if (_shouldReconnect) {
      _updateStatus('🔄 Agendando reconexão...');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts && _shouldReconnect) {
      _reconnectAttempts++;
      int delay = _reconnectDelay * _reconnectAttempts; // Backoff exponencial
      if (delay > 30000) delay = 30000; // máximo 30s
      delay += (1000 * (DateTime.now().millisecondsSinceEpoch % 3));

      _updateStatus(
          '🔄 Tentativa de reconexão $_reconnectAttempts/$_maxReconnectAttempts em ${delay}ms');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(milliseconds: delay), () {
        if (!_isConnected && _shouldReconnect) {
          _updateStatus('🔄 Executando reconexão...');
          connect();
        }
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateStatus('❌ Número máximo de tentativas de reconexão atingido');
      onError
          ?.call('Falha na reconexão após $_maxReconnectAttempts tentativas');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(Duration(seconds: _heartbeatInterval), (timer) {
      if (_isConnected) {
        _sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    if (_isConnected && _channel != null) {
      try {
        final heartbeatMessage = {
          "tipo": "heartbeat",
          "timestamp": DateTime.now().toIso8601String(),
          "client_id": "flutter_app",
        };

        _channel!.sink.add(jsonEncode(heartbeatMessage));
        _lastHeartbeat = DateTime.now();
        _log('💓 Heartbeat enviado');
      } catch (e) {
        _log('❌ Erro ao enviar heartbeat: $e');
      }
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

      _log('Mensagem recebida: $message');

      final Map<String, dynamic> jsonData = jsonDecode(message);
      final tipo = jsonData['tipo'];

      if (tipo == 'heartbeat') {
        _sendHeartbeatResponse(jsonData);
      } else if (tipo == 'heartbeat_response') {
        _lastHeartbeat = DateTime.now();
        _log('💓 Heartbeat confirmado pelo servidor');
      } else {
        onDataReceived?.call(jsonData);
      }
    } catch (e) {
      _log('Erro ao processar mensagem: $e');
    }
  }

  void _sendHeartbeatResponse(Map<String, dynamic> heartbeatData) {
    if (_isConnected && _channel != null) {
      try {
        final response = {
          "tipo": "heartbeat_response",
          "timestamp": DateTime.now().toIso8601String(),
          "client_id": "flutter_app",
          "server_time": heartbeatData['server_time'],
        };

        _channel!.sink.add(jsonEncode(response));
        _log('💓 Resposta de heartbeat enviada');
      } catch (e) {
        _log('❌ Erro ao enviar resposta de heartbeat: $e');
      }
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      _log('❌ Não está conectado');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _log('📤 Enviando mensagem: $jsonMessage');
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      _log('❌ Erro ao enviar mensagem: $e');
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
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _reconnectAttempts = 0;
    _updateStatus('🔌 Desconectado manualmente');
  }

  void dispose() {
    disconnect();
  }

  bool isConnectionHealthy() {
    if (!_isConnected) return false;

    if (_lastHeartbeat == null || _lastMessageReceived == null) return false;

    final now = DateTime.now();
    final heartbeatAge = now.difference(_lastHeartbeat!).inSeconds;
    final messageAge = now.difference(_lastMessageReceived!).inSeconds;

    return heartbeatAge < _heartbeatTimeout && messageAge < _heartbeatTimeout;
  }

  Future<void> forceReconnect() async {
    _log('🔄 Forçando reconexão...');
    disconnect();
    await Future.delayed(Duration(milliseconds: 500));
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    await connect();
  }

  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'lastHeartbeat': _lastHeartbeat?.toIso8601String(),
      'lastMessageReceived': _lastMessageReceived?.toIso8601String(),
      'isConnectionHealthy': isConnectionHealthy(),
      'serverUrl': _serverUrl,
    };
  }
}
