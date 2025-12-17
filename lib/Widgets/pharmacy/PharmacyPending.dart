import 'package:flutter/material.dart';

class PharmacyPending extends StatefulWidget {
  const PharmacyPending({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PharmacyPending> createState() => _PharmacyPendingState();
}

class _PharmacyPendingState extends State<PharmacyPending> {
  // Dữ liệu mẫu cho các đơn thuốc đang chờ xử lý
  final List<Map<String, dynamic>> _pendingPrescriptions = [
    {
      'id': '98765',
      'patientName': 'John Appleseed',
      'received': '10/26/2023, 10:05 AM',
      'doctor': 'Dr. Emily Carter',
      'medication': 'Atorvastatin 20mg',
      'status': 'Urgent',
    },
    {
      'id': '12345',
      'patientName': 'Jane Doe',
      'received': '10/26/2023, 9:30 AM',
      'doctor': 'Dr. Alan Grant',
      'medication': 'Lisinopril 10mg',
      'status': 'New',
    },
    {
      'id': '54321',
      'patientName': 'Peter Jones',
      'received': '10/25/2023, 4:15 PM',
      'doctor': 'Dr. Sarah Connor',
      'medication': 'Metformin 500mg',
      'status': 'Refill',
    },
  ];

  // Widget để xây dựng nhãn trạng thái
  Widget _buildStatusTag(String status) {
    Color tagColor;
    String displayText;

    switch (status) {
      case 'Urgent':
        tagColor = const Color(0xFFE53E3E); // Màu đỏ cho trạng thái khẩn cấp
        displayText = 'Urgent';
        break;
      case 'New':
        tagColor = const Color(0xFF3182CE); // Màu xanh cho trạng thái mới
        displayText = 'New';
        break;
      case 'Refill':
        tagColor = const Color(0xFF718096); // Màu xám cho trạng thái nạp lại
        displayText = 'Refill';
        break;
      default:
        tagColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loại bỏ Scaffold và trả về Container chứa nội dung của trang.
    // AppShell sẽ cung cấp Scaffold, AppBar và BottomNavigationBar chung.
    return Container(
      color: const Color(0xFF1A202C), // Giữ lại màu nền tối của trang
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _pendingPrescriptions.length,
        itemBuilder: (context, index) {
          final item = _pendingPrescriptions[index];
          return Card(
            color: const Color(0xFF2D3748), // Màu nền thẻ tối hơn
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Received: ${item['received']}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      _buildStatusTag(item['status']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      text: 'Patient: ',
                      style: TextStyle(color: Colors.grey[300], fontSize: 16),
                      children: [
                        TextSpan(
                          text: '${item['patientName']} (ID: ${item['id']})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['doctor'],
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Medication: ${item['medication']}',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Điều hướng đến màn hình chi tiết
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3182CE), // Màu xanh cho nút
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
