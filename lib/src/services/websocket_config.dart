import 'robust_websocket_service.dart';

class WebSocketConfig {
  static final RobustWebSocketService _websocketService =
      RobustWebSocketService();

  // Getters para facilitar o acesso
  static RobustWebSocketService get service => _websocketService;

  // Configurações padrão
  static const String defaultServerUrl = 'ws://10.0.0.219:8765';
  static const int defaultPort = 8765;

  // Método para configurar e conectar automaticamente
  static Future<void> setupAndConnect({
    String? serverUrl,
    Function(Map<String, dynamic>)? onDataReceived,
    Function()? onConnected,
    Function()? onDisconnected,
    Function(String)? onError,
    Function(String)? onStatusChanged,
  }) async {
    // Configura callbacks
    if (onDataReceived != null)
      _websocketService.onDataReceived = onDataReceived;
    if (onConnected != null) _websocketService.onConnected = onConnected;
    if (onDisconnected != null)
      _websocketService.onDisconnected = onDisconnected;
    if (onError != null) _websocketService.onError = onError;
    if (onStatusChanged != null)
      _websocketService.onStatusChanged = onStatusChanged;

    // Configura URL do servidor
    final url = serverUrl ?? defaultServerUrl;
    _websocketService.setServerUrl(url);

    // Conecta automaticamente
    await _websocketService.connect();
  }

  // Método para desconectar
  static void disconnect() {
    _websocketService.disconnect();
  }

  // Método para forçar reconexão
  static Future<void> forceReconnect() async {
    await _websocketService.forceReconnect();
  }

  // Método para verificar status da conexão
  static bool get isConnected => _websocketService.isConnected;
  static bool get isConnectionHealthy =>
      _websocketService.isConnectionHealthy();

  // Método para obter estatísticas
  static Map<String, dynamic> getConnectionStats() {
    return _websocketService.getConnectionStats();
  }

  // Método para enviar comandos
  static Future<void> sendCommand({
    required String action,
    int? andarDestino,
    Map<String, dynamic>? dados,
  }) async {
    await _websocketService.sendCommand(
      action: action,
      andarDestino: andarDestino,
      dados: dados,
    );
  }

  // Método para solicitar dados iniciais
  static Future<void> requestInitialData() async {
    await _websocketService.requestInitialData();
  }

  // Método para ir para um andar
  static Future<void> goToFloor(int andarDestino) async {
    await _websocketService.sendGoToFloor(andarDestino);
  }

  // Método para enviar comandos booleanos
  static Future<void> sendBooleanCommand({
    required String action,
    required bool estado,
  }) async {
    await _websocketService.sendBooleanCommand(
      action: action,
      estado: estado,
    );
  }

  // Método para limpar recursos
  static void dispose() {
    _websocketService.dispose();
  }
}
