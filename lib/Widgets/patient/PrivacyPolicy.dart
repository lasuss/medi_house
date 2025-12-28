
import 'package:flutter/material.dart';

/// Widget hiển thị màn hình Chi tiết Chính sách bảo mật cho người dùng.
class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách bảo mật'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Chính sách bảo mật MediHouse',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Thu thập thông tin\n'
              'Chúng tôi thu thập thông tin cá nhân của bạn như tên, email, số điện thoại và thông tin sức khỏe khi bạn đăng ký và sử dụng dịch vụ.\n\n'
              '2. Sử dụng thông tin\n'
              'Thông tin của bạn được sử dụng để cung cấp dịch vụ y tế, quản lý lịch hẹn và cải thiện trải nghiệm người dùng.\n\n'
              '3. Chia sẻ thông tin\n'
              'Chúng tôi không chia sẻ thông tin cá nhân của bạn với bên thứ ba trừ khi có sự đồng ý của bạn hoặc theo yêu cầu của pháp luật.\n\n'
              '4. Bảo mật dữ liệu\n'
              'Chúng tôi áp dụng các biện pháp bảo mật tiên tiến để bảo vệ thông tin của bạn khỏi truy cập trái phép.\n\n'
              '5. Quyền của bạn\n'
              'Bạn có quyền truy cập, chỉnh sửa hoặc xóa thông tin cá nhân của mình bất cứ lúc nào.\n\n'
              'Liên hệ với chúng tôi nếu bạn có thắc mắc về chính sách bảo mật này.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
