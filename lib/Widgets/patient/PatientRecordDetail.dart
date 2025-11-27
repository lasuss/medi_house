import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientRecordDetail extends StatefulWidget {
  const PatientRecordDetail({Key? key, this.title, required this.patientID})
      : super(key: key);

  final String? title;
  final String patientID;

  @override
  State<PatientRecordDetail> createState() => _PatientRecordDetailState();
}

class _PatientRecordDetailState extends State<PatientRecordDetail> {
  // State variables (để trống)
  String patientName = "";
  String dob = "";
  String gender = "";
  String address = "";
  String phone = "";
  String insurance = "";
  String medicalHistory = "";
  String allergies = "";
  String chronicDiseases = "";

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  Future<void> fetchPatientData() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('patients')
          .select()
          .eq('id', widget.patientID)
          .maybeSingle();

      if (response != null) {
        setState(() {
          patientName = response['full_name'] ?? "";
          dob = response['dob'] ?? "";
          gender = response['gender'] ?? "";
          phone = response['phone'] ?? "";
          address = response['address'] ?? "";
          insurance = response['insurance'] ?? "";
          medicalHistory = response['medical_history'] ?? "";
          allergies = response['allergies'] ?? "";
          chronicDiseases = response['chronic_diseases'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error fetching Supabase data: $e");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFF),
        elevation: 0,
        title: const Text(
          "Hồ sơ bệnh nhân",
          style: TextStyle(fontSize: 22, color: Colors.blue),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Thông tin cá nhân",
              items: {
                "Họ và tên": patientName,
                "Ngày sinh": dob,
                "Giới tính": gender,
                "Số điện thoại": phone,
                "Địa chỉ": address,
              },
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Thông tin bảo hiểm",
              items: {
                "Mã BHYT": insurance,
              },
            ),

            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Tiền sử bệnh",
              items: {
                "Bệnh nền": chronicDiseases,
                "Dị ứng": allergies,
                "Lịch sử khám bệnh": medicalHistory,
              },
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: mở màn hình chỉnh sửa
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E6E6E),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Quay lại",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Lưu",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Map<String, String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 Title — màu xanh
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff2196f3),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...items.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label xám nhạt
                  Text(
                    e.key,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Ô chứa giá trị — giống UI bạn đưa
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e.value.isNotEmpty ? e.value : "(trống)",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}
