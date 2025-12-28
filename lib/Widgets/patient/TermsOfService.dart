
import 'package:flutter/material.dart';

/// Widget hiển thị màn hình Điều khoản sử dụng dịch vụ.
class TermsOfService extends StatelessWidget {
  const TermsOfService({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản sử dụng'),
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
              'Điều khoản sử dụng MediHouse',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Giới thiệu\n'
              'Chào mừng bạn đến với MediHouse. Khi sử dụng ứng dụng của chúng tôi, bạn đồng ý tuân thủ các điều khoản sau đây.\n\n'
              '2. Tài khoản người dùng\n'
              'Bạn chịu trách nhiệm bảo mật thông tin tài khoản và mật khẩu của mình. Mọi hoạt động diễn ra dưới tài khoản của bạn là trách nhiệm của bạn.\n\n'
              '3. Quyền riêng tư\n'
              'Chúng tôi coi trọng quyền riêng tư của bạn. Vui lòng xem Chính sách bảo mật để hiểu rõ hơn về cách chúng tôi thu thập và sử dụng thông tin của bạn.\n\n'
              '4. Sử dụng dịch vụ\n'
              'Bạn cam kết không sử dụng ứng dụng cho các mục đích vi phạm pháp luật hoặc gây hại cho người khác.\n\n'
              '5. Thay đổi điều khoản\n'
              'Chúng tôi có quyền thay đổi các điều khoản này bất cứ lúc nào và sẽ thông báo cho bạn về những thay đổi quan trọng.\n\n'
              'Liên hệ với chúng tôi nếu bạn có bất kỳ câu hỏi nào về các điều khoản này.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
