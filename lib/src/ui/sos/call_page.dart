import 'dart:async';

import 'package:altitude_ipd_app/src/services/signaling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallPageType { audio, video }

class CallPage extends StatefulWidget {
  CallPageType callPageType;
  CallPage({Key? key, required this.callPageType}) : super(key: key);
  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final SignalingService _signaling = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Timer? _callingTimer;
  Timer? _callTimer;
  final ValueNotifier<Duration> _callDuration = ValueNotifier(Duration.zero);

  final String room = 'ipd_user_1';
  static const int call_time = 100;

  bool isCalling = false;
  bool inCall = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _startSignaling();
    _startCallTimer();
  }

  Future<void> _initializeRenderers() async {
    setState(() {
      isCalling = true;
    });
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startSignaling() async {
    await _signaling.init(
        isVideoCall: widget.callPageType == CallPageType.video);
    setState(() {
      _localRenderer.srcObject = _signaling.localStream;
    });

    _signaling.onRemoteStream = (MediaStream stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
      _callingTimer?.cancel();
      _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _callDuration.value += Duration(seconds: 1);
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

  void _startCallTimer() {
    const duration = Duration(seconds: call_time); // Tempo limite da chamada
    _callingTimer = Timer(duration, () {
      print('Tempo de chamada expirado. Finalizando a chamada...');
      _endCall(); // Finaliza a chamada
    });
  }

  @override
  void dispose() {
    _stopCallProcess();
    _callingTimer?.cancel();
    _callTimer?.cancel();
    _callDuration.value = Duration.zero;
    super.dispose();
  }

  void _stopCallProcess() async {
    await _signaling.disconnect();
    if (_localRenderer.srcObject != null) {
      _localRenderer.srcObject = null;
      _localRenderer.dispose();
    }
    if (_remoteRenderer.srcObject != null) {
      _remoteRenderer.srcObject = null;
      _remoteRenderer.dispose();
    }
    _callingTimer?.cancel();
    _callTimer?.cancel();
    _callDuration.value = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;
    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.callPageType == CallPageType.video
          ? buildVideoCallWidget(
              widthRatio: widthRatio, heightRatio: heightRatio)
          : buildAudioCallWidget(
              widthRatio: widthRatio, heightRatio: heightRatio),
    );
  }

  Widget buildVideoCallWidget(
      {required double widthRatio, required double heightRatio}) {
    return Stack(
      children: [
        Container(
          child: _remoteRenderer.srcObject == null
              ? Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chamando...'),
                    Image.asset('assets/images/png/logo_altitude.png'),
                  ],
                ))
              : RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
        Positioned(
          bottom: 40.0 * heightRatio, // Margem do topo
          right: 40.0 * widthRatio, // Margem do canto esquerdo
          width: 400 * widthRatio, // Largura do vídeo local
          height: 450 * heightRatio, // Altura do vídeo local
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2), // Borda branca
              borderRadius: BorderRadius.circular(8), // Cantos arredondados
            ),
            child: _localRenderer.srcObject == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
        ),
        // Botão de finalizar chamada centralizado
        Padding(
          padding: EdgeInsets.only(bottom: 40.0 * heightRatio),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              onPressed: _endCall,
              tooltip: 'Finalizar Chamada',
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAudioCallWidget(
      {required double widthRatio, required double heightRatio}) {
    return Stack(
      children: [
        Container(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _remoteRenderer.srcObject == null
                    ? Text('Chamando...')
                    : buildTimerWidget(),
                Image.asset('assets/images/png/logo_altitude.png'),
              ],
            ),
          ),
        ),
        // Botão de finalizar chamada centralizado
        Padding(
          padding: EdgeInsets.only(bottom: 40.0 * heightRatio),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              onPressed: _endCall,
              tooltip: 'Finalizar Chamada',
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTimerWidget() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _callDuration,
      builder: (context, duration, child) {
        final minutes =
            duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds =
            duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        return Text(
          '$minutes:$seconds',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  void _endCall() {
    _stopCallProcess();
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }
}
