import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/network/api_client.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;

  const VideoCallScreen({super.key, required this.roomId});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  io.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  bool _isConnected = false;
  bool _isConnecting = true;
  String _status = 'সংযোগ হচ্ছে...';
  String? _peerSocketId;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _getUserMedia();
    _connectSocket();
  }

  Future<void> _getUserMedia() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user', 'width': 640, 'height': 480},
      });
      _localRenderer.srcObject = _localStream;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _status = 'ক্যামেরা অ্যাক্সেস ব্যর্থ হয়েছে');
    }
  }

  void _connectSocket() {
    final wsUrl = ApiClient.baseUrl.replaceFirst('/api', '').replaceFirst('http', 'ws');
    _socket = io.io(
      '$wsUrl/webrtc',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      final userId = ApiClient.currentUser?['id'] ?? 'anonymous';
      _socket!.emit('join-room', {'roomId': widget.roomId, 'userId': userId});
    });

    _socket!.on('room-joined', (data) async {
      final others = data['otherUsers'] as List? ?? [];
      if (others.isNotEmpty) {
        _peerSocketId = others.first as String;
        await _createPeerConnection();
        await _createAndSendOffer();
      } else {
        if (mounted) setState(() => _status = 'প্রতীক্ষায়... অন্য পক্ষের যোগদানের অপেক্ষা করছেন');
      }
    });

    _socket!.on('peer-joined', (data) async {
      _peerSocketId = data['socketId'] as String;
      await _createPeerConnection();
    });

    _socket!.on('offer', (data) async {
      _peerSocketId ??= data['from'] as String;
      await _createPeerConnection();
      final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
      await _peerConnection!.setRemoteDescription(offer);
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _socket!.emit('answer', {'to': _peerSocketId, 'answer': {'sdp': answer.sdp, 'type': answer.type}});
    });

    _socket!.on('answer', (data) async {
      final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await _peerConnection?.setRemoteDescription(answer);
    });

    _socket!.on('ice-candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    });

    _socket!.on('call-ended', (_) => _endCall(remoteEnded: true));
    _socket!.on('peer-left', (_) {
      if (mounted) setState(() { _isConnected = false; _status = 'অন্য পক্ষ ছেড়ে গেছে'; });
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers);

    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _socket!.emit('ice-candidate', {
          'to': _peerSocketId,
          'candidate': {'candidate': candidate.candidate, 'sdpMid': candidate.sdpMid, 'sdpMLineIndex': candidate.sdpMLineIndex},
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() { _remoteStream = event.streams[0]; _remoteRenderer.srcObject = _remoteStream; });
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        setState(() { _isConnected = true; _isConnecting = false; _status = 'সংযুক্ত'; });
        _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _callDuration += const Duration(seconds: 1));
        });
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        setState(() { _isConnected = false; _status = 'সংযোগ বিচ্ছিন্ন'; });
      }
    };
  }

  Future<void> _createAndSendOffer() async {
    final offer = await _peerConnection!.createOffer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
    await _peerConnection!.setLocalDescription(offer);
    _socket!.emit('offer', {'to': _peerSocketId, 'offer': {'sdp': offer.sdp, 'type': offer.type}, 'from': _socket!.id});
    if (mounted) setState(() => _status = 'কল করা হচ্ছে...');
  }

  void _toggleMute() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = _isMuted);
    setState(() => _isMuted = !_isMuted);
    _socket?.emit('toggle-audio', {'roomId': widget.roomId, 'muted': _isMuted});
  }

  void _toggleVideo() {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = _isVideoOff);
    setState(() => _isVideoOff = !_isVideoOff);
    _socket?.emit('toggle-video', {'roomId': widget.roomId, 'videoOff': _isVideoOff});
  }

  Future<void> _flipCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      await Helper.switchCamera(tracks[0]);
      setState(() => _isFrontCamera = !_isFrontCamera);
    }
  }

  void _endCall({bool remoteEnded = false}) {
    _callTimer?.cancel();
    if (!remoteEnded) _socket?.emit('call-ended', {'roomId': widget.roomId});
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _socket?.disconnect();
    Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video (full screen) ──────────────────────────────
          Positioned.fill(
            child: _isConnected
                ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.video_call_rounded, color: Color(0xFF1565C0), size: 80),
                    const SizedBox(height: 16),
                    Text(_status, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    if (_isConnecting) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(color: Color(0xFF1565C0)),
                    ],
                  ])),
          ),

          // ── Call duration ────────────────────────────────────────────
          if (_isConnected)
            Positioned(top: MediaQuery.of(context).padding.top + 16, left: 0, right: 0,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                child: Text(_formatDuration(_callDuration), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ),

          // ── Local video (PiP) ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100, height: 140,
                child: _isVideoOff
                    ? Container(color: const Color(0xFF1E293B), child: const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28))
                    : RTCVideoView(_localRenderer, mirror: _isFrontCamera, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
            ),
          ),

          // ── Controls ─────────────────────────────────────────────────
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ControlBtn(icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, onTap: _toggleMute, active: !_isMuted, label: _isMuted ? 'আনমিউট' : 'মিউট'),
                const SizedBox(width: 16),
                _ControlBtn(icon: Icons.call_end_rounded, onTap: _endCall, active: false, isEndCall: true, label: 'কল শেষ'),
                const SizedBox(width: 16),
                _ControlBtn(icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded, onTap: _toggleVideo, active: !_isVideoOff, label: _isVideoOff ? 'ভিডিও চালু' : 'ভিডিও বন্ধ'),
                const SizedBox(width: 16),
                _ControlBtn(icon: Icons.flip_camera_android_rounded, onTap: _flipCamera, active: true, label: 'ফ্লিপ'),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _socket?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool isEndCall;
  final String label;

  const _ControlBtn({required this.icon, required this.onTap, required this.active, required this.label, this.isEndCall = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: isEndCall ? const Color(0xFFDC2626) : (active ? Colors.white.withOpacity(0.2) : Colors.black45),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      );
}
