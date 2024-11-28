import 'package:altitude_ipd_app/src/ui/sos/signaling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallPage extends StatefulWidget {
  // ignore: use_super_parameters
  const CallPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final SignalingService _signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  final String room = 'ipd_user_1';

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startSignaling();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startSignaling() async {
    await _signaling.init();
    setState(() {
      _localRenderer.srcObject = _signaling.localStream;
    });

    _signaling.onRemoteStream = (MediaStream stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
      print('Stream remoto configurado no renderizador: ${stream.id}');
    };

    _signaling.connect(room);
    _startCall();
  }

  void _startCall() async {
    print('Iniciando a chamada...');
    var offer = await _signaling.createOffer();
    if (offer != null) {
      _signaling.sendOffer(offer, room);
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Call Room: $room')),
      body: Stack(
        children: [
          // Vídeo remoto ocupando toda a tela
          RTCVideoView(
            _remoteRenderer,
          ),
          // Vídeo local em uma janela flutuante
          Positioned(
            right: 20, // Margem do canto direito
            bottom: 0, // Margem do canto inferior
            width: 150, // Largura do vídeo local
            height: 200, // Altura do vídeo local
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.white, width: 2), // Borda branca
                borderRadius: BorderRadius.circular(8), // Cantos arredondados
              ),
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startCall,
        tooltip: 'Iniciar Chamada',
        child: const Icon(Icons.phone),
      ),
    );
  }
}
