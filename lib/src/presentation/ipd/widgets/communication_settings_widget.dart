import 'package:flutter/material.dart';
import '../ipd_home_controller.dart';

class CommunicationSettingsWidget extends StatefulWidget {
  const CommunicationSettingsWidget({super.key});

  @override
  State<CommunicationSettingsWidget> createState() =>
      _CommunicationSettingsWidgetState();
}

class _CommunicationSettingsWidgetState
    extends State<CommunicationSettingsWidget> {
  final IpdHomeController _controller = IpdHomeController();
  final TextEditingController _ipController = TextEditingController();
  bool _useWebSocket = false;

  @override
  void initState() {
    super.initState();
    _useWebSocket = _controller.useWebSocket;
    _ipController.text =
        _controller.webSocketService.serverUrl.replaceFirst('ws://', '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuração de Comunicação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seletor de modo de comunicação
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modo de Comunicação',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<bool>(
                    title: const Text('RS485 (Serial)'),
                    subtitle: const Text('Comunicação via cabo serial'),
                    value: false,
                    groupValue: _useWebSocket,
                    onChanged: (value) {
                      setState(() {
                        _useWebSocket = value!;
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('WebSocket (WiFi)'),
                    subtitle: const Text('Comunicação via rede WiFi'),
                    value: true,
                    groupValue: _useWebSocket,
                    onChanged: (value) {
                      setState(() {
                        _useWebSocket = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Configuração do IP do servidor WebSocket
          if (_useWebSocket) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuração do Servidor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP do Servidor',
                        hintText: '192.168.1.100:8765',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Atualiza o IP no controller
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _controller.isWebSocketConnected
                                ? null
                                : () {
                                    final ip = _ipController.text.trim();
                                    if (ip.isNotEmpty) {
                                      _controller.webSocketService
                                          .setServerUrl('ws://$ip');
                                      _controller.webSocketService.connect();
                                      setState(() {});
                                    }
                                  },
                            icon: const Icon(Icons.wifi),
                            label: const Text('Conectar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _controller.isWebSocketConnected
                                ? () {
                                    _controller.webSocketService.disconnect();
                                    setState(() {});
                                  }
                                : null,
                            icon: const Icon(Icons.wifi_off),
                            label: const Text('Desconectar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _controller.isWebSocketConnected
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _controller.isWebSocketConnected
                                ? Icons.check_circle
                                : Icons.error,
                            color: _controller.isWebSocketConnected
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _controller.isWebSocketConnected
                                ? 'Conectado'
                                : 'Desconectado',
                            style: TextStyle(
                              color: _controller.isWebSocketConnected
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.setUseWebSocket(_useWebSocket);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _useWebSocket
                      ? 'Modo WebSocket ativado'
                      : 'Modo RS485 ativado',
                ),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
