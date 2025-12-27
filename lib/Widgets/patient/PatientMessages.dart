import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/PatientChatScreen.dart';
import 'package:medi_house/Widgets/model/Message.dart';

// Widget chính hiển thị danh sách các cuộc trò chuyện gần đây của bệnh nhân
class PatientMessages extends StatefulWidget {
  const PatientMessages({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientMessages> createState() => _PatientMessagesState();
}

// Trạng thái quản lý danh sách tin nhắn và cuộc trò chuyện
class _PatientMessagesState extends State<PatientMessages> {
  // Client Supabase và ID người dùng hiện tại
  final _supabase = Supabase.instance.client;
  late final String _myId;

  // Cache thông tin người dùng (name, avatar, role) để tránh query lặp
  Map<String, Map<String, dynamic>> _userCache = {};

  // Stream dữ liệu các cuộc trò chuyện gần đây
  late Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  // Khởi tạo trạng thái: lấy ID người dùng và thiết lập stream dữ liệu
  void initState() {
    super.initState();
    _myId = _supabase.auth.currentUser!.id;
    _setupConversationsStream();
  }

  // Thiết lập stream theo dõi tin nhắn và xử lý thành danh sách cuộc trò chuyện
  void _setupConversationsStream() {
    _conversationsStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
      final messages = data.map((e) => Message.fromJson(e)).toList();

      // Lọc chỉ tin nhắn trực tiếp (DM) liên quan đến người dùng hiện tại
      final myMessages = messages.where((m) =>
      (m.senderId == _myId || m.receiverId == _myId) &&
          m.channelId == null &&
          m.receiverId != null
      ).toList();

      // Nhóm tin nhắn theo người trò chuyện và tính số tin chưa đọc
      final Map<String, Message> lastMessages = {};
      final Map<String, int> unreadCounts = {};
      final Set<String> userIdsToFetch = {};

      for (var msg in myMessages) {
        final otherId = (msg.senderId == _myId ? msg.receiverId : msg.senderId)!;

        // Đếm tin nhắn chưa đọc (người nhận là mình và chưa đọc)
        if (msg.receiverId == _myId && !msg.isRead) {
          unreadCounts[otherId] = (unreadCounts[otherId] ?? 0) + 1;
        }

        // Lấy tin nhắn mới nhất của mỗi cuộc trò chuyện (do stream đã sort descending)
        if (!lastMessages.containsKey(otherId)) {
          lastMessages[otherId] = msg;
          userIdsToFetch.add(otherId);
        }
      }

      // Lấy thông tin người dùng chưa có trong cache
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

      // Tạo danh sách cuộc trò chuyện để hiển thị
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
          'time': _formatTime(message.createdAt.toLocal()),
          'unreadCount': unreadCounts[otherId] ?? 0,
        };
      }).toList();
    });
  }

  // Định dạng thời gian hiển thị cho tin nhắn mới nhất (hôm nay chỉ giờ, còn lại ngày/giờ)
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  // Xây dựng giao diện danh sách tin nhắn
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            // Danh sách cuộc trò chuyện theo thời gian thực
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

                  // Hiển thị từng cuộc trò chuyện dưới dạng ListTile
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
                        // Avatar của người trò chuyện
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          backgroundImage: conversation['avatar'] != null ? NetworkImage(conversation['avatar']) : null,
                          child: conversation['avatar'] == null
                              ? Text((conversation['name'] as String)[0].toUpperCase(), style: const TextStyle(color: Colors.blue))
                              : null,
                        ),
                        // Tên người trò chuyện
                        title: Text(
                          conversation['name'] ?? 'Không xác định',
                          style: TextStyle(
                            color: isUnread ? Colors.black : Colors.black87,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        // Tin nhắn cuối cùng (cắt ngắn nếu dài)
                        subtitle: Text(
                          conversation['lastMessage'],
                          style: TextStyle(
                            color: isUnread ? Colors.black87 : Colors.grey[600],
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Thời gian và badge chưa đọc
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
                        // Chuyển sang màn hình chat chi tiết khi tap
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

  // Ô tìm kiếm tin nhắn (chưa implement chức năng tìm kiếm thực tế)
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