import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/Prescription.dart';

class PharmacyPending extends StatefulWidget {
  const PharmacyPending({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PharmacyPending> createState() => _PharmacyPendingState();
}

class _PharmacyPendingState extends State<PharmacyPending> {
  final _supabase = Supabase.instance.client;
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  bool _isFilling = false;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('*, doctors:doctor_id(name), patients:patient_id(name), prescription_items(*, medicines(*))')
          .eq('status', 'Pending')
          .order('created_at', ascending: false);
      
      final data = response as List<dynamic>;
      setState(() {
        _prescriptions = data.map((e) => Prescription.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fillPrescription(Prescription prescription) async {
    if (_isFilling) return;
    setState(() => _isFilling = true);

    try {
      // 1. Duyệt qua từng thuốc để kiểm tra và trừ tồn kho
      for (var item in prescription.items) {
        final inventoryRes = await _supabase
            .from('inventory')
            .select('*')
            .eq('medicine_id', item.medicineId)
            .gte('quantity', item.quantity) 
            .order('expiry_date', ascending: true)
            .limit(1);

        final inventoryList = inventoryRes as List<dynamic>;
        if (inventoryList.isEmpty) {
          throw Exception("Không đủ tồn kho cho ${item.medicine?.name ?? 'Thuốc'} (ID: ${item.medicineId})");
        }
        
        final batch = inventoryList.first;
        final newQuantity = (batch['quantity'] as int) - item.quantity;
        
        await _supabase.from('inventory').update({'quantity': newQuantity}).eq('id', batch['id']);
      }

      // 2. Cập nhật trạng thái đơn thuốc thành Đã cấp (Filled)
      await _supabase.from('prescriptions').update({'status': 'Filled'}).eq('id', prescription.id);

      // 3. Cập nhật trạng thái hồ sơ bệnh án thành Hoàn thành (Completed) nếu có recordId
      if (prescription.recordId != null) {
         await _supabase.from('records').update({'status': 'Completed'}).eq('id', prescription.recordId!);
         
         // 4. Cũng cập nhật trạng thái lịch hẹn thành Hoàn thành (Completed)
         try {
           await _supabase.from('appointments').update({'status': 'Completed'}).eq('record_id', prescription.recordId!);
         } catch (_) {}
      }

      if (mounted) {
        // Safe UI feedback
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ Đã cấp thuốc thành công!'),
                    backgroundColor: Colors.green,
                ),
               );
            }
        });
        _fetchPrescriptions();
      }

    } catch (e) {
      if (mounted) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('⚠️ Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                ),
               );
            }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isFilling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng theme sáng sạch, đồng bộ
    return Column(
      children: [
        if (_isFilling) 
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFE2E8F0),
            color: Color(0xFF2196F3),
            minHeight: 4,
          ),
          
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _prescriptions.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final item = _prescriptions[index];
                    return _buildPrescriptionCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có đơn thuốc chờ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã hoàn thành tất cả!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & ID
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} • ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFEB2B2)),
                  ),
                  child: const Text(
                    'Cần cấp thuốc',
                    style: TextStyle(
                      color: Color(0xFFC53030),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient & Doctor Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEBF8FF),
                      child: const Icon(Icons.person, color: Color(0xFF3182CE)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.patientName ?? 'Bệnh nhân ẩn danh',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kê đơn bởi Bs. ${item.doctorName ?? 'Không rõ'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Medicines List
                const Text(
                  'DANH SÁCH THUỐC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFFA0AEC0),
                  ),
                ),
                const SizedBox(height: 8),
                ...item.items.map((pi) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication_outlined, size: 16, color: Color(0xFF4A5568)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pi.medicine?.name ?? 'Thuốc không rõ tên',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            if (pi.medicine?.description != null)
                              Text(
                                pi.medicine!.description!,
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'x${pi.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                const SizedBox(height: 20),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isFilling ? null : () => _fillPrescription(item),
                    icon: _isFilling 
                      ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.check_circle_outline),
                    label: Text(_isFilling ? 'Đang xử lý...' : 'Cấp Thuốc Ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}