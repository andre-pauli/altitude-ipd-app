import 'package:flutter/material.dart';
import '../../../services/websocket_config.dart';

class RobustWebSocketWidget extends StatefulWidget {
  const RobustWebSocketWidget({Key? key}) : super(key: key);

  @override
  State<RobustWebSocketWidget> createState() => _RobustWebSocketWidgetState();
}

class _RobustWebSocketWidgetState extends State<RobustWebSocketWidget> {
  bool _isConnected = false;
  bool _isConnectionHealthy = false;
  String _status = 'Desconectado';
  Map<String, dynamic> _connectionStats = {};
  Map<String, dynamic>? _lastReceivedData;

  @override
  void initState() {
    super.initState();
    _setupWebSocket();
  }

  void _setupWebSocket() {
    WebSocketConfig.setupAndConnect(
      serverUrl: 'ws://10.0.0.219:8765', // Host específico do elevador
      onDataReceived: _onDataReceived,
      onConnected: _onConnected,
      onDisconnected: _onDisconnected,
      onError: _onError,
      onStatusChanged: _onStatusChanged,
    );
  }

  void _onDataReceived(Map<String, dynamic> data) {
    setState(() {
      _lastReceivedData = data;
    });
    print('Dados recebidos: $data');
  }

  void _onConnected() {
    setState(() {
      _isConnected = true;
      _status = 'Conectado';
    });
    print('WebSocket conectado!');

    // Solicita dados iniciais
    WebSocketConfig.requestInitialData();
  }

  void _onDisconnected() {
    setState(() {
      _isConnected = false;
      _status = 'Desconectado';
    });
    print('WebSocket desconectado!');
  }

  void _onError(String error) {
    setState(() {
      _status = 'Erro: $error';
    });
    print('Erro WebSocket: $error');
  }

  void _onStatusChanged(String status) {
    setState(() {
      _status = status;
    });
  }

  void _updateConnectionStats() {
    setState(() {
      _connectionStats = WebSocketConfig.getConnectionStats();
      _isConnectionHealthy = WebSocketConfig.isConnectionHealthy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'WebSocket Robusto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status da conexão
            _buildStatusRow('Status:', _status),
            _buildStatusRow('Conectado:', _isConnected ? 'Sim' : 'Não'),
            _buildStatusRow(
                'Conexão Saudável:', _isConnectionHealthy ? 'Sim' : 'Não'),

            const SizedBox(height: 16),

            // Botões de controle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isConnected ? null : WebSocketConfig.forceReconnect,
                    child: const Text('Reconectar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? WebSocketConfig.disconnect : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Desconectar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botões de teste
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected
                        ? () => WebSocketConfig.requestInitialData()
                        : null,
                    child: const Text('Solicitar Dados'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected
                        ? () => WebSocketConfig.goToFloor(2)
                        : null,
                    child: const Text('Ir para Andar 2'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Estatísticas da conexão
            ElevatedButton(
              onPressed: _updateConnectionStats,
              child: const Text('Atualizar Estatísticas'),
            ),

            if (_connectionStats.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Estatísticas da Conexão:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._connectionStats.entries.map((entry) =>
                  _buildStatusRow('${entry.key}:', '${entry.value}')),
            ],

            if (_lastReceivedData != null) ...[
              const SizedBox(height: 16),
              const Text('Últimos Dados Recebidos:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastReceivedData.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WebSocketConfig.dispose();
    super.dispose();
  }
}
