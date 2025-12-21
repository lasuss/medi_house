
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/PatientChatScreen.dart';
import 'package:medi_house/Widgets/model/Message.dart';

class PatientMessages extends StatefulWidget {
  const PatientMessages({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientMessages> createState() => _PatientMessagesState();
}

class _PatientMessagesState extends State<PatientMessages> {
  final _supabase = Supabase.instance.client;
  late final String _myId;
  
  // Map of userId -> {name, avatar, etc}
  Map<String, Map<String, dynamic>> _userCache = {};
  
  // Using Stream builder for messages list might be heavy if many messages.
  // But for "Recent Conversations" usually we query a view.
  // I will stream all my messages and group them client side.
  late Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _myId = _supabase.auth.currentUser!.id;
    _setupConversationsStream();
  }

  void _setupConversationsStream() {
    _conversationsStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // Latest first
        .asyncMap((data) async {
          final messages = data.map((e) => Message.fromJson(e)).toList();
          
          // Filter messages involving me AND are direct messages (not channel)
          final myMessages = messages.where((m) => 
            (m.senderId == _myId || m.receiverId == _myId) &&
            m.channelId == null && 
            m.receiverId != null // Ensure DM
          ).toList();

          // Group by other user
          // Group by other user and count unread
          final Map<String, Message> lastMessages = {};
          final Map<String, int> unreadCounts = {};
          final Set<String> userIdsToFetch = {};

          for (var msg in myMessages) {
            // Safe to bang ! because of filter above
            final otherId = (msg.senderId == _myId ? msg.receiverId : msg.senderId)!;
            
            // Track unread: if I am receiver and !isRead
            if (msg.receiverId == _myId && !msg.isRead) {
               unreadCounts[otherId] = (unreadCounts[otherId] ?? 0) + 1;
            }

            // Track last message (assuming list is sorted Descending latest first)
            // Since we iterate list, first encounter is latest
            if (!lastMessages.containsKey(otherId)) {
              lastMessages[otherId] = msg;
              userIdsToFetch.add(otherId);
            }
          }

          // Fetch user details ... (omitted same logic)
          // (Logic repeated for clarity, but I will just replace the block)
          final idsToQuery = userIdsToFetch.where((id) => !_userCache.containsKey(id)).toList();
          if (idsToQuery.isNotEmpty) {
             try {
                final response = await _supabase
                  .from('users')
                  .select('id, name, avatar_url, role')
                  .filter('id', 'in', idsToQuery);
                for (var user in response) {
                  _userCache[user['id']] = user;
                }
             } catch (e) {
               debugPrint('Error fetching users: $e');
             }
          }

          // Construct conversation objects
          return lastMessages.entries.map((entry) {
            final otherId = entry.key;
            final message = entry.value;
            final user = _userCache[otherId] ?? {'name': 'Unknown', 'avatar_url': null, 'role': 'User'};
            
            return {
              'userId': otherId,
              'name': user['name'],
              'avatar': user['avatar_url'],
              'role': user['role'],
              'lastMessage': message.content,
              // Convert to Local Time for display
              'time': _formatTime(message.createdAt.toLocal()),
              'unreadCount': unreadCounts[otherId] ?? 0,
            };
          }).toList();
        });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    // Use simple comparison
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _conversationsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final conversations = snapshot.data!;
                  if (conversations.isEmpty) {
                    return const Center(child: Text('Chưa có tin nhắn nào'));
                  }

                  return ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey.withOpacity(0.2),
                      height: 1,
                      indent: 80,
                    ),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final bool isUnread = (conversation['unreadCount'] as int) > 0;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          backgroundImage: conversation['avatar'] != null ? NetworkImage(conversation['avatar']) : null,
                          child: conversation['avatar'] == null
                              ? Text((conversation['name'] as String)[0].toUpperCase(), style: const TextStyle(color: Colors.blue))
                              : null,
                        ),
                        title: Text(
                          conversation['name'] ?? 'Không xác định',
                          style: TextStyle(
                            color: isUnread ? Colors.black : Colors.black87,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          conversation['lastMessage'],
                          style: TextStyle(
                            color: isUnread ? Colors.black87 : Colors.grey[600],
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              conversation['time'],
                              style: TextStyle(
                                color: isUnread ? Colors.blue : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientChatScreen(
                                name: conversation['name'],
                                receiverId: conversation['userId'],
                                avatarUrl: conversation['avatar'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tin nhắn...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
