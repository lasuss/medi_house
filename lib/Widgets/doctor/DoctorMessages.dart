//have access on Doctor Bottom Navigation

import 'package:flutter/material.dart';

class DoctorMessages extends StatefulWidget {
  const DoctorMessages({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<DoctorMessages> createState() => _DoctorMessagesState();
}

class _DoctorMessagesState extends State<DoctorMessages> {
  // Mock data for messages
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Nguyen Van A',
      'message': 'Thank you, Doctor. Does he need any medication?',
      'time': '10:30 AM',
      'unread': 2,
      'isOnline': true,
      'image': null
    },
    {
      'sender': 'Tran Thi B',
      'message': 'I will book an appointment for next week.',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'image': null
    },
    {
      'sender': 'Le Van C',
      'message': 'The pain has subsided significantly.',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': true,
      'image': null
    },
    {
      'sender': 'Pham Thi D',
      'message': 'Can I reschedule my appointment?',
      'time': 'Oct 20',
      'unread': 1,
      'isOnline': false,
      'image': null
    },
  ];

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
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Patients', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Groups', false),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _messages.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 82),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return InkWell(
                  onTap: () {
                    // Navigate to chat detail
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  msg['sender'].substring(0, 1),
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                            if (msg['isOnline'])
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    msg['sender'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  Text(
                                    msg['time'],
                                    style: TextStyle(
                                      color: msg['unread'] > 0
                                          ? Colors.blue
                                          : Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: msg['unread'] > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      msg['message'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: msg['unread'] > 0
                                            ? const Color(0xFF2D3748)
                                            : Colors.grey[600],
                                        fontWeight: msg['unread'] > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (msg['unread'] > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        msg['unread'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Chip(
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
    );
  }
}
