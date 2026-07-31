import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await ApiClient.getChatList();
      if (mounted) {
        setState(() {
          _chats = List<Map<String, dynamic>>.from(chats);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('মেসেজ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _chats.isEmpty
              ? const Center(child: Text('কোনো মেসেজ নেই', style: TextStyle(color: Color(0xFF94A3B8))))
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final user = chat['user'];
                      final lastMessage = chat['lastMessage'];
                      
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE3F2FD),
                            child: Text(user['name']?[0] ?? 'U', style: const TextStyle(color: Color(0xFF1565C0))),
                          ),
                          title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(lastMessage ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            context.push('/chat/${user['id']}?name=${Uri.encodeComponent(user['name'] ?? '')}').then((_) => _loadChats());
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
