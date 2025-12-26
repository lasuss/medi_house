
import  'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/PatientChatScreen.dart'; // Reuse for now
import 'package:medi_house/Widgets/model/Message.dart';
import 'package:medi_house/Widgets/doctor/ChannelChatScreen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
///Hàm thiết lập và xử lý luồng cuộc trò chuyện
  void _setupConversationsStream() {
    _conversationsStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final messages = data.map((e) => Message.fromJson(e)).toList();
          final myMessages = messages.where((m) => 
            (m.senderId == _myId || m.receiverId == _myId) && 
            m.channelId == null && 
            m.receiverId != null
          ).toList();
          final Map<String, Message> lastMessages = {};
          final Map<String, int> unreadCounts = {};
          final Set<String> userIdsToFetch = {};

          for (var msg in myMessages) {
            final otherId = (msg.senderId == _myId ? msg.receiverId : msg.senderId)!;
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
  ///Hàm định dạng thời gian
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
///Hàm tải và lọc các kênh trò chuyện theo chuyên khoa
  Future<List<Map<String, dynamic>>> _getFilteredChannels() async {
    try {
      // 1. Get doctor specialty
      final docInfo = await _supabase
          .from('doctor_info')
          .select('specialty')
          .eq('user_id', _myId)
          .maybeSingle();
      
      final specialty = docInfo?['specialty'] as String?;
      debugPrint('Doctor Specialty: $specialty');

      debugPrint('Doctor Specialty: $specialty');

      // 2. Fetch ALL channels and filter client-side for robust string matching
      final response = await _supabase
          .from('channels')
          .select()
          .order('name', ascending: true);
      
      final List<Map<String, dynamic>> allChannels = List<Map<String, dynamic>>.from(response);

      final filteredChannels = allChannels.where((channel) {
        final name = channel['name'] as String;
        if (name == 'General') return true;
        
        if (specialty != null) {
          final sName = name.toLowerCase().trim();
          final sSpecialty = specialty.toLowerCase().trim();
          if (sName == sSpecialty) return true;
          if (sSpecialty.contains(sName) || sName.contains(sSpecialty)) return true;
        }
        
        return false;
      }).toList();
      
      debugPrint('Filtered Channels: $filteredChannels');
      return filteredChannels;
          
    } catch (e) {
      debugPrint('Error fetching channels: $e');
      return [];
    }
  }

///Phương thức xây dựng giao diện màn hình tin nhắn
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFilteredChannels(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final channels = snapshot.data!;
                if (channels.isEmpty) return const SizedBox.shrink();
                
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    String displayName = channel['name'];
                    if (displayName == 'General') displayName = 'Đa khoa';

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => ChannelChatScreen(
                                 channelId: channel['id'], 
                                 channelName: displayName 
                               ),
                             ),
                           );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: FaIcon(FontAwesomeIcons.users, color: Colors.indigo, size: 20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName, 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _conversationsStream,
              builder: (context, snapshot) {
                 if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                 
                 final conversations = snapshot.data!;

                 if (conversations.isEmpty) return const Center(child: Text('Chưa có tin nhắn'));

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
}
