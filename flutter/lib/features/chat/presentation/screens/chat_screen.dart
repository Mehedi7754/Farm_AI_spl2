import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  const ChatScreen({super.key, required this.otherUserId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      setState(() {
        _messages = List<Map<String, dynamic>>.from(msgs);
        if (!silent) _isLoading = false;
      });
      if (!silent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
        'id': DateTime.now().toString(),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বার্তা পাঠানো যায়নি')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ApiClient.currentUser?['id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _messages.isEmpty
                    ? const Center(child: Text('কোনো বার্তা নেই। প্রথম বার্তা পাঠান!', style: TextStyle(color: Color(0xFF94A3B8))))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == currentUserId;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF1565C0) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 16),
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'বার্তা লিখুন...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
