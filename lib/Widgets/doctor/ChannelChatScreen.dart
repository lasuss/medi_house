
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/Message.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChannelChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelChatScreen({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final String _myId;
  Stream<List<Message>>? _messagesStream;
  Map<String, String> _userNames = {}; // Cache for sender names

  @override
  void initState() {
    super.initState();
    _myId = _supabase.auth.currentUser!.id;
    _setupMessageStream();
  }

  void _setupMessageStream() {
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', widget.channelId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          final messages = data.map((e) => Message.fromJson(e)).toList();
          
          await _fetchSenders(messages);
          
          return messages;
        });
  }

  Future<void> _fetchSenders(List<Message> messages) async {
    final unknownIds = messages
        .map((m) => m.senderId)
        .where((id) => !_userNames.containsKey(id) && id != _myId)
        .toSet();

    if (unknownIds.isNotEmpty) {
      try {
        final response = await _supabase
            .from('users')
            .select('id, name')
            .filter('id', 'in', unknownIds.toList());
        
        if (mounted) {
          setState(() {
            for (var user in response) {
              _userNames[user['id']] = user['name'] ?? 'Unknown';
            }
          });
        }
      } catch (e) {
        debugPrint('Error fetching users: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': _myId,
        'channel_id': widget.channelId, // Send to channel
        'content': text,
      });
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }
  
  String _getSenderName(String userId) {
    if (userId == _myId) return 'Bạn';
    return _userNames[userId] ?? 'Người dùng';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle
              ),
              child: const FaIcon(FontAwesomeIcons.users, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 10),
            Text(
              widget.channelName,
              style: const TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Chào mừng bạn đến với ${widget.channelName}!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _myId;
                    final showHeader = index == 0 || messages[index - 1].senderId != message.senderId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe && showHeader)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 2, top: 4),
                              child: Text(
                                _getSenderName(message.senderId),
                                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2)
                                )
                              ]
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0, left: 4, right: 4),
                            child: Text(
                              "${message.createdAt.toLocal().hour}:${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}",
                              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
