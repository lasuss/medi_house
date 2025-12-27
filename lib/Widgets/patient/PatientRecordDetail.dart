import  'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/Widgets/model/PatientChatScreen.dart';

// Widget chính hiển thị chi tiết một hồ sơ khám bệnh (record)
class PatientRecordDetail extends StatefulWidget {
  // ID của record được truyền vào (tên biến là patientID để tương thích router cũ)
  final String patientID;

  const PatientRecordDetail({Key? key, required this.patientID}) : super(key: key);

  @override
  State<PatientRecordDetail> createState() => _PatientRecordDetailState();
}

// Trạng thái quản lý dữ liệu chi tiết hồ sơ khám
class _PatientRecordDetailState extends State<PatientRecordDetail> {
  // Client Supabase
  final SupabaseClient supabase = Supabase.instance.client;

  // Trạng thái loading và các dữ liệu liên quan
  bool _isLoading = true;
  Map<String, dynamic>? _record;
  Map<String, dynamic>? _doctor;
  Map<String, dynamic>? _prescription;
  Map<String, dynamic>? _appointment;
  List<Map<String, dynamic>> _prescriptionItems = [];

  @override
  // Khởi tạo trạng thái: lấy dữ liệu chi tiết khi mở màn hình
  void initState() {
    super.initState();
    _fetchRecordDetails();
  }

  // Lấy toàn bộ dữ liệu liên quan đến record (record, doctor, prescription, appointment, items thuốc)
  Future<void> _fetchRecordDetails() async {
    try {
      final recordId = widget.patientID;

      final res = await supabase
          .from('records')
          .select('*, doctor:doctor_id(*)')
          .eq('id', recordId)
          .single();

      final presRes = await supabase
          .from('prescriptions')
          .select('*')
          .eq('record_id', recordId)
          .maybeSingle();

      final apptRes = await supabase
          .from('appointments')
          .select('*')
          .eq('record_id', recordId)
          .maybeSingle();

      List<Map<String, dynamic>> items = [];
      if (presRes != null) {
        final itemsRes = await supabase
            .from('prescription_items')
            .select('*, medicine:medicine_id(*)')
            .eq('prescription_id', presRes['id']);

        items = List<Map<String, dynamic>>.from(itemsRes);
      }

      if (mounted) {
        setState(() {
          _record = res;
          _doctor = res['doctor'];
          _prescription = presRes;
          _prescriptionItems = items;
          _appointment = apptRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching record: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Xử lý hủy lịch hẹn: xóa toàn bộ dữ liệu liên quan (items → prescription → appointment → record)
  Future<void> _cancelAppointment() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch hẹn?'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn này không? Chi phí đã thanh toán sẽ được hoàn lại vào ví của bạn trong vòng 24h.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy lịch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      setState(() => _isLoading = true);
      try {
        final presList = await supabase
            .from('prescriptions')
            .select('id')
            .eq('record_id', widget.patientID);

        for (var p in presList) {
          await supabase.from('prescription_items').delete().eq('prescription_id', p['id']);
        }
        await supabase.from('prescriptions').delete().eq('record_id', widget.patientID);

        await supabase.from('appointments').delete().eq('record_id', widget.patientID);

        await supabase.from('records').delete().eq('id', widget.patientID);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa lịch hẹn và hồ sơ thành công.")));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xóa dữ liệu: $e")));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  // Xây dựng giao diện chính chi tiết hồ sơ khám
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
          ? const Center(child: Text("Không tìm thấy hồ sơ"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildDoctorCard(),
            const SizedBox(height: 20),
            _buildInfoSection(),
            if (_prescription != null) ...[
              const SizedBox(height: 20),
              _buildPrescriptionDetailSection(),
            ] else if (_record?['prescription'] != null) ...[
              const SizedBox(height: 20),
              _buildPrescriptionSectionLegacy(),
            ],
            if (_record?['attachments'] != null) ...[
              const SizedBox(height: 20),
              _buildAttachmentsSection(),
            ],
            const SizedBox(height: 30),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  // Thẻ header hiển thị triệu chứng, thời gian tạo và trạng thái hồ sơ
  Widget _buildHeaderCard() {
    final created = DateTime.parse(_record!['created_at']).toLocal();
    final status = _record!['status'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.article, color: Colors.blue[700], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _record!['symptoms'] ?? 'Phiếu khám',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(created),
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status == 'Completed' ? Colors.green[50] : (status == 'Cancelled' ? Colors.red[50] : Colors.orange[50]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'Completed' ? 'Hoàn thành' : (status == 'Cancelled' ? 'Đã hủy' : (status == 'Pending' ? 'Đang xử lý' : 'Không xác định')),
                  style: TextStyle(
                    color: status == 'Completed' ? Colors.green[700] : (status == 'Cancelled' ? Colors.red[700] : Colors.orange[700]),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // Thẻ thông tin bác sĩ phụ trách kèm nút chat
  Widget _buildDoctorCard() {
    if (_doctor == null) return const SizedBox.shrink();
    final name = _doctor!['name'] ?? 'Bác sĩ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: _doctor!['avatar_url'] != null
                ? NetworkImage(_doctor!['avatar_url'])
                : const NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bác sĩ phụ trách", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          IconButton(
            icon: const FaIcon(FontAwesomeIcons.message, color: Colors.blue),
            onPressed: () {
              if (_doctor != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientChatScreen(
                      name: name,
                      receiverId: _doctor!['id'],
                      avatarUrl: _doctor!['avatar_url'],
                    ),
                  ),
                );
              }
            },
          )
        ],
      ),
    );
  }

  // Phần thông tin chẩn đoán và ghi chú/lời dặn của bác sĩ
  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelValue("Chẩn đoán", _record!['diagnosis'] ?? 'Chưa có chẩn đoán'),
          const Divider(height: 24),
          _buildLabelValue("Ghi chú / Lời dặn", _record!['notes'] ?? 'Không có ghi chú'),
        ],
      ),
    );
  }

  // Phần hiển thị chi tiết đơn thuốc (danh sách thuốc + trạng thái cấp phát)
  Widget _buildPrescriptionDetailSection() {
    final status = _prescription!['status'] ?? 'Pending';
    final isFilled = status == 'Filled' || status == 'Completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(FontAwesomeIcons.pills, color: Colors.green),
                  SizedBox(width: 8),
                  Text("Đơn thuốc", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFilled ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFilled ? "Đã cấp phát" : "Chờ cấp phát",
                  style: TextStyle(
                      color: isFilled ? Colors.green[700] : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_prescriptionItems.isEmpty)
            const Text("Không có thuốc trong đơn này.", style: TextStyle(color: Colors.grey)),

          ..._prescriptionItems.map((item) {
            final med = item['medicine'] ?? {};
            final name = med['name'] ?? 'Thuốc';
            final qty = item['quantity'] ?? 0;
            final unit = med['unit'] ?? 'viên';
            final instruct = item['instructions'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.medication, color: Colors.blue[300], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text("$qty $unit", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        if (med['description'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(med['description'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ),
                        if (instruct.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(instruct, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Phần hiển thị đơn thuốc dạng text cũ (legacy) nếu không có dữ liệu chi tiết
  Widget _buildPrescriptionSectionLegacy() {
    final prescription = _record!['prescription'].toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medication, color: Colors.green),
              SizedBox(width: 8),
              Text("Đơn thuốc (Ghi chú)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(prescription, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  // Placeholder cho phần tài liệu đính kèm
  Widget _buildAttachmentsSection() {
    return Container(
      child: const Text("Tài liệu đính kèm (Placeholder)"),
    );
  }

  // Widget hiển thị nhãn và giá trị (dùng trong phần chẩn đoán, ghi chú)
  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
      ],
    );
  }

  // Nút hủy lịch hẹn/yêu cầu (chỉ hiển thị khi đủ điều kiện)
  Widget _buildCancelButton() {
    final isTriage = _record!['triage_data'] != null;

    if (_appointment == null && !isTriage) return const SizedBox.shrink();

    if (_appointment != null) {
      final status = _appointment!['status'] ?? 'Pending';
      if (status != 'Pending') return const SizedBox.shrink();

      final dateStr = _appointment!['date'];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        if (!isTriage && date.isBefore(now)) return const SizedBox.shrink();
      }
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _cancelAppointment,
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        label: const Text("Hủy Lịch Hẹn / Yêu Cầu", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}