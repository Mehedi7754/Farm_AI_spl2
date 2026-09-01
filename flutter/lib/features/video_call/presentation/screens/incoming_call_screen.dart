import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/network/api_client.dart';

class IncomingCallScreen extends StatefulWidget {
  final String roomId;
  final String callerName;
  final String consultationId;
  final String callerSocketId;

  const IncomingCallScreen({
    super.key,
    required this.roomId,
    required this.callerName,
    required this.consultationId,
    required this.callerSocketId,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnim;
  late Animation<double> _ringAnim;

  Timer? _autoDeclineTimer;
  int _secondsLeft = 45;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Show over lock screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    // Connect socket to register presence
    _connectSocket();

    // Start repeating haptic vibration for call alert
    _startVibration();

    // Auto-decline after 45 seconds
    _autoDeclineTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _decline();
      }
    });
  }

  void _startVibration() {
    HapticFeedback.vibrate();
    Timer.periodic(const Duration(milliseconds: 1000), (vibeTimer) {
      if (!mounted) {
        vibeTimer.cancel();
        return;
      }
      HapticFeedback.vibrate();
    });
  }

  void _connectSocket() {
    final wsUrl = ApiClient.baseUrl.replaceFirst('/api', '').replaceFirst('http', 'ws');
    _socket = io.io(
      '$wsUrl/webrtc',
      io.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build(),
    );
    // Listen for call-ended or call-cancelled from caller side
    _socket!.on('call-ended', (_) {
      if (mounted) {
        _autoDeclineTimer?.cancel();
        Navigator.of(context).pop();
      }
    });
    _socket!.on('call-cancelled', (_) {
      if (mounted) {
        _autoDeclineTimer?.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  void _accept() {
    _autoDeclineTimer?.cancel();
    _socket?.disconnect();
    if (mounted) {
      // Navigate to video call screen
      context.pushReplacement('/video-call/${widget.roomId}');
    }
  }

  void _decline() {
    _autoDeclineTimer?.cancel();
    // Notify caller that call was declined
    _socket?.emit('call-declined', {
      'roomId': widget.roomId,
      'callerSocketId': widget.callerSocketId,
    });
    _socket?.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _autoDeclineTimer?.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    _socket?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D2137), Color(0xFF071020)],
              ),
            ),
          ),

          // Animated rings
          Center(
            child: AnimatedBuilder(
              animation: _ringAnim,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  _buildRing(180, 0.15 - _ringAnim.value * 0.1),
                  _buildRing(230, 0.10 - _ringAnim.value * 0.08),
                  _buildRing(280, 0.06 - _ringAnim.value * 0.05),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Incoming call label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    '📹 ইনকামিং ভিডিও কল',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 40),

                // Caller avatar - pulsing
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 60),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Caller name
                Text(
                  widget.callerName.startsWith('ডাঃ') || widget.callerName.startsWith('Dr.')
                      ? widget.callerName
                      : 'ডাঃ ${widget.callerName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ইনকামিং ভিডিও কল...',
                  style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 15, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                // Countdown
                Text(
                  '$_secondsLeft সেকেন্ড',
                  style: TextStyle(
                    color: _secondsLeft <= 10 ? const Color(0xFFFF6B6B) : Colors.white38,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline button
                      _CallActionBtn(
                        icon: Icons.call_end_rounded,
                        label: 'প্রত্যাখ্যান',
                        color: const Color(0xFFDC2626),
                        onTap: _decline,
                      ),

                      // Accept button
                      _CallActionBtn(
                        icon: Icons.videocam_rounded,
                        label: 'গ্রহণ করুন',
                        color: const Color(0xFF059669),
                        onTap: _accept,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

class _CallActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
