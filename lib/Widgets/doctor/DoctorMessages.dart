
import  'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/PatientChatScreen.dart'; // Reuse for now
import 'package:medi_house/Widgets/model/Message.dart';

class DoctorMessages extends StatefulWidget {
  const DoctorMessages({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<DoctorMessages> createState() => _DoctorMessagesState();
}

class _DoctorMessagesState extends State<DoctorMessages> {
  final _supabase = Supabase.instance.client;
  late final String _myId;
  Map<String, Map<String, dynamic>> _userCache = {};
  late Stream<List<Map<String, dynamic>>> _conversationsStream;
  String _filter = 'All'; // 'All', 'Unread', 'Patients'

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
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final messages = data.map((e) => Message.fromJson(e)).toList();
          final myMessages = messages.where((m) => m.senderId == _myId || m.receiverId == _myId).toList();

          // Group by other user and count unread
          final Map<String, Message> lastMessages = {};
          final Map<String, int> unreadCounts = {};
          final Set<String> userIdsToFetch = {};

          for (var msg in myMessages) {
            final otherId = msg.senderId == _myId ? msg.receiverId : msg.senderId;
            
            // Track unread
            if (msg.receiverId == _myId && !msg.isRead) {
               unreadCounts[otherId] = (unreadCounts[otherId] ?? 0) + 1;
            }

            if (!lastMessages.containsKey(otherId)) {
              lastMessages[otherId] = msg;
              userIdsToFetch.add(otherId);
            }
          }

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
              'time': _formatTime(message.createdAt.toLocal()), // Convert to local
              'unreadCount': unreadCounts[otherId] ?? 0,
            };
          }).toList();
        });
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF2D3748)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFF2D3748)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', _filter == 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', _filter == 'Unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Patients', _filter == 'Patients'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _conversationsStream,
              builder: (context, snapshot) {
                 if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                 
                 final allConversations = snapshot.data!;
                 final conversations = _filterConversations(allConversations);

                 if (conversations.isEmpty) return const Center(child: Text('No messages'));

                 return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 82),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final bool isUnread = (conversation['unreadCount'] as int) > 0;
                    
                    return InkWell(
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                    radius: 28, 
                                    backgroundColor: Colors.blue[100],
                                    backgroundImage: conversation['avatar'] != null 
                                        ? NetworkImage(conversation['avatar']) 
                                        : null,
                                    child: conversation['avatar'] == null
                                        ? Text(
                                            (conversation['name'] as String).isNotEmpty 
                                                ? (conversation['name'] as String)[0].toUpperCase() 
                                                : '?',
                                            style: TextStyle(
                                              color: Colors.blue[800],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          )
                                        : null,
                                ),
                                if (isUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        conversation['name'],
                                        style: TextStyle(
                                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.bold, // Already bold, but make it blacker?
                                          fontSize: 16,
                                          color: isUnread ? Colors.black : const Color(0xFF2D3748),
                                        ),
                                      ),
                                      Text(
                                        conversation['time'],
                                        style: TextStyle(
                                          color: isUnread ? Colors.blue : Colors.grey[500],
                                          fontSize: 12,
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    conversation['lastMessage'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isUnread ? Colors.black87 : Colors.grey[600],
                                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterConversations(List<Map<String, dynamic>> all) {
    if (_filter == 'Unread') return all.where((c) => (c['unreadCount'] as int) > 0).toList();
    if (_filter == 'Patients') return all.where((c) => c['role'] == 'patient').toList();
    return all;
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2D3748),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor:
            isSelected ? const Color(0xFF3182CE) : const Color(0xFFEDF2F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}
