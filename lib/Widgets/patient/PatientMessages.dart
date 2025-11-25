import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/Message.dart';

class PatientMessages extends StatefulWidget {
  const PatientMessages({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientMessages> createState() => _PatientMessagesState();
}

class _PatientMessagesState extends State<PatientMessages> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  late final Stream<List<Message>> _messagesStream;

  // TODO: Replace with actual doctor ID logic (e.g., from selected appointment)
  // For demo purposes, we might need a way to select a doctor or hardcode one for testing if no doctor is selected yet.
  // Assuming we are chatting with a specific doctor.
  String? _receiverId; 

  @override
  void initState() {
    super.initState();
    final myId = _supabase.auth.currentUser?.id;
    if (myId != null) {
      _messagesStream = _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .map((maps) => maps.map((map) => Message.fromJson(map)).toList());
    } else {
      _messagesStream = const Stream.empty();
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập')),
      );
      return;
    }

    // For testing, if no receiver is set, we can't send.
    // In a real app, you'd pass the doctor's ID to this widget.
    if (_receiverId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa chọn người nhận (Bác sĩ)')),
      );
      return;
    }

    try {
      await _supabase.from('messages').insert({
        'sender_id': myId,
        'receiver_id': _receiverId,
        'content': content,
      });
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Tin nhắn')),
      body: Column(
        children: [
          // Temporary Dropdown or Input to select Doctor ID for testing if needed
          // Or just a display if we assume it's passed in.
          if (_receiverId == null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Nhập ID Bác sĩ để chat (Test)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _receiverId = value;
                  });
                },
              ),
            ),

          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                
                final messages = snapshot.data ?? [];
                // Filter messages for current conversation locally if needed, 
                // though RLS should handle security, we might want to filter by specific conversation in UI
                final conversationMessages = messages.where((m) => 
                  (m.senderId == myId && m.receiverId == _receiverId) || 
                  (m.senderId == _receiverId && m.receiverId == myId)
                ).toList();

                if (conversationMessages.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn nào.'));
                }

                return ListView.builder(
                  itemCount: conversationMessages.length,
                  itemBuilder: (context, index) {
                    final message = conversationMessages[index];
                    final isMe = message.senderId == myId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
