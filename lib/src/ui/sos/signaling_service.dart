import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignalingService {
  late IO.Socket _socket;
  final String _serverUrl = 'http://91.108.125.86:3000';
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ],
    'sdpSemantics': 'unified-plan',
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Function(MediaStream)? onRemoteStream;

  Future<void> init() async {
    await _checkPermissions();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    _peerConnection = await createPeerConnection(_configuration);

    for (var track in _localStream!.getTracks()) {
      print('Adicionando trilha local: ${track.id}');
      await _peerConnection?.addTrack(track, _localStream!);
    }

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        print('Stream remoto recebido: ${event.streams[0].id}');
        if (onRemoteStream != null) {
          onRemoteStream!(event.streams[0]);
        }
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('ICE candidate gerado: ${candidate.candidate}');
      _socket.emit('signal', {
        'room': '1234', // Certifique-se de ajustar o ID da sala
        'signal': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
      print('ICE candidate enviado ao servidor.');
    };
  }

  void connect(String room) {
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket.onConnect((_) {
      print('Conectado ao servidor de sinalização.');
      _socket.emit('join-room', room);
    });

    _socket.on('signal', (data) async {
      print('Sinal recebido: $data');
      var description = data['signal'];

      if (description != null && description['type'] == 'offer') {
        print('Offer recebido.');
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(description['sdp']!, description['type']!),
        );

        var answer = await _peerConnection?.createAnswer();
        if (answer != null) {
          await _peerConnection?.setLocalDescription(answer);

          _socket.emit('signal', {
            'room': room,
            'signal': {
              'sdp': answer.sdp,
              'type': answer.type,
            },
          });
          print('Answer enviada.');
        }
      } else if (description != null && description['type'] == 'answer') {
        print('Answer recebida.');
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(description['sdp']!, description['type']!),
        );
      }

      if (data['candidate'] != null) {
        print('ICE candidate recebido.');
        await _peerConnection?.addCandidate(RTCIceCandidate(
          data['candidate']['candidate']!,
          data['candidate']['sdpMid']!,
          data['candidate']['sdpMLineIndex']!,
        ));
      }
    });

    _socket.onDisconnect((_) {
      print('Desconectado do servidor de sinalização.');
    });
  }

  MediaStream? get localStream => _localStream;

  Future<void> _checkPermissions() async {
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }

    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection != null) {
      var offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      print('Offer criada: ${offer.sdp}');
      return offer;
    }
    print('Erro: PeerConnection não inicializada.');
    return null;
  }

  void sendOffer(RTCSessionDescription offer, String room) {
    _socket.emit('signal', {
      'room': room,
      'signal': {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    });
    print('Offer enviada para a sala: $room');
  }
}
