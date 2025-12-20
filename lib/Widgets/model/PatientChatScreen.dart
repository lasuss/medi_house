
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/Message.dart';

class PatientChatScreen extends StatefulWidget {
  final String name;
  final String receiverId;
  final String? avatarUrl;
  
  const PatientChatScreen({
    Key? key, 
    required this.name, 
    required this.receiverId,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _textController = TextEditingController();
  late final String _myId;
  late final Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _myId = _supabase.auth.currentUser!.id;
    _setupMessageStream();
  }

  void _setupMessageStream() {
    print('Setting up stream for: $_myId and ${widget.receiverId}');
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) {
          final messages = maps.map((map) => Message.fromJson(map)).toList();
          // Filter messages between ME and THEM
          return messages.where((m) => 
            (m.senderId == _myId && m.receiverId == widget.receiverId) ||
            (m.senderId == widget.receiverId && m.receiverId == _myId)
          ).toList();
        });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.receiverId,
        'content': text,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
              child: widget.avatarUrl == null 
                  ? Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12)) 
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        iconTheme: const IconThemeData(color: Colors.blue),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn nào.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _myId;

                    // Mark as read logic
                    if (!isMe && !message.isRead) {
                       Future.microtask(() async {
                          try {
                            await _supabase
                              .from('messages')
                              .update({'is_read': true})
                              .eq('id', message.id!);
                          } catch (_) {}
                       });
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
