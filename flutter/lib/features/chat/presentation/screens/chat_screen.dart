import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  const ChatScreen({super.key, required this.otherUserId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  // Track the last message ID we've seen — so we can detect new ones
  String? _lastSeenMessageId;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final msgs = await ApiClient.getChatHistory(widget.otherUserId);
      if (!mounted) return;

      final newList = List<Map<String, dynamic>>.from(msgs);
      final currentUserId = ApiClient.currentUser?['id'] ?? '';

      // Detect new incoming messages (not from us)
      if (silent && _lastSeenMessageId != null && newList.isNotEmpty) {
        final latestMsg = newList.last;
        final latestId = latestMsg['id']?.toString() ?? '';
        final latestSenderId = latestMsg['senderId']?.toString() ?? '';

        if (latestId != _lastSeenMessageId && latestSenderId != currentUserId) {
          // New message from the other person — show OS notification
          final content = latestMsg['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            await NotificationService().showChatNotification(
              senderId: widget.otherUserId,
              senderName: widget.otherUserName,
              message: content,
            );
          }
        }
      }

      if (newList.isNotEmpty) {
        _lastSeenMessageId = newList.last['id']?.toString();
      }

      setState(() {
        _messages = newList;
        if (!silent) _isLoading = false;
      });

      if (!silent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      } else if (_messages.isNotEmpty) {
        // Auto-scroll to new message if near bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final pos = _scrollController.position;
            if (pos.maxScrollExtent - pos.pixels < 100) {
              _scrollController.animateTo(
                pos.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    // Optimistic UI update
    final currentUserId = ApiClient.currentUser?['id'] ?? '';
    setState(() {
      _messages.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'content': text,
        'senderId': currentUserId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await ApiClient.sendMessage(receiverId: widget.otherUserId, content: text);
      _loadMessages(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('বার্তা পাঠানো যায়নি')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ApiClient.currentUser?['id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
            ),
          ],
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF047857), size: 36),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'কোনো তথ্য আদান-প্রদান হয়নি',
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'প্রথম বার্তা পাঠিয়ে কথোপকথন শুরু করুন!',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == currentUserId;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.76,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe
                                    ? const LinearGradient(
                                        colors: [Color(0xFF059669), Color(0xFF047857)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isMe ? null : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: isMe
                                        ? const Color(0xFF059669).withValues(alpha: 0.2)
                                        : const Color(0x0A0F172A),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'আপনার বার্তা লিখুন...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
