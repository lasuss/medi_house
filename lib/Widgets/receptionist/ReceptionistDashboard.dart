import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({Key? key}) : super(key: key);

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _historyRequests = [];
  bool _isLoadingHistory = false;
  
  // Các biến dữ liệu
  List<Map<String, dynamic>> _triageRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTriageRequests();
    _fetchHistoryRequests();
  }

  Future<void> _fetchTriageRequests() async {
    try {
      final res = await supabase
          .from('records')
          .select('*, patient:patient_id(id, name, avatar_url, national_id, phone)')
          .isFilter('doctor_id', null)
          .not('triage_data', 'is', null) 
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _triageRequests = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching triage requests: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHistoryRequests() async {
    setState(() => _isLoadingHistory = true);
    try {
      // Lấy các bản ghi đã xử lý (đã có bác sĩ phụ trách)
      final res = await supabase
          .from('records')
          .select('*, patient:patient_id(id, name, avatar_url, national_id, phone), doctor:doctor_id(name)')
          .not('doctor_id', 'is', null) // Đã được phân công
          .not('triage_data', 'is', null)
          .order('updated_at', ascending: false)
          .limit(50); // Giới hạn số lượng để tối ưu hiệu năng
      
      if (mounted) {
        setState(() {
          _historyRequests = List<Map<String, dynamic>>.from(res);
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold( // Use Scaffold here to host AppBar with Tabs, but AppShell wraps it. 
         // Wait, AppShell provides AppBar title. We can't easily inject Tabs into AppShell's AppBar.
         // We should use a Column structure with TabBar.
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: "Chờ xử lý"),
                  Tab(text: "Lịch sử"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                   // Tab 1: Chờ xử lý
                  _buildList(_triageRequests, _isLoading, _fetchTriageRequests),
                   // Tab 2: Lịch sử
                  _buildList(_historyRequests, _isLoadingHistory, _fetchHistoryRequests, isHistory: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool loading, Function() onRefresh, {bool isHistory = false}) {
     if (loading) return const Center(child: CircularProgressIndicator());
     
     return RefreshIndicator(
       onRefresh: () async {
         await onRefresh();
         if (isHistory) _fetchTriageRequests(); // Nên làm mới cả hai danh sách vì dữ liệu liên quan
         else _fetchHistoryRequests();
       },
       child: items.isEmpty
         ? _buildEmptyState(isHistory ? "Chưa có lịch sử xử lý" : "Không có yêu cầu nào")
         : ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: items.length,
             itemBuilder: (context, index) {
               return _buildRequestCard(items[index], isHistory: isHistory);
             },
           ),
     );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, {bool isHistory = false}) {
    final patient = req['patient'] ?? {};
    final triageData = req['triage_data'] ?? {};
    final created = DateTime.parse(req['created_at']).toLocal();
    final timeAgo = _timeAgo(created);
    
    // Trích xuất thông tin chính
    final symptoms = triageData['main_symptoms'] ?? 'Không rõ';
    final severity = triageData['severity'] ?? 0;
    final dangerousSigns = triageData['dangerous_signs'] as List?;
    final hasDangerousSigns = dangerousSigns != null && dangerousSigns.isNotEmpty;
    
    // Thông tin bác sĩ nếu là lịch sử
    String? assignedDoctor;
    if (isHistory && req['doctor'] != null) {
       assignedDoctor = req['doctor']['name'];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: isHistory ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: () async {
          await context.push('/receptionist/triage/${req['id']}');
          _fetchTriageRequests(); // Refresh both on return
          _fetchHistoryRequests();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: patient['avatar_url'] != null ? NetworkImage(patient['avatar_url']) : null,
                        child: patient['avatar_url'] == null 
                          ? Text((patient['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: Colors.blue[800])) 
                          : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient['name'] ?? 'Bệnh nhân ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  _buildSeverityBadge(severity),
                ],
              ),
              const Divider(height: 24),
              Text(
                "Triệu chứng: $symptoms", 
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasDangerousSigns) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Có dấu hiệu nguy hiểm!", 
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
              if (isHistory && assignedDoctor != null) ...[
                 const SizedBox(height: 12),
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                   child: Row(
                     children: [
                       const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                       const SizedBox(width: 6),
                       Expanded(child: Text("Đã chuyển: $assignedDoctor", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))),
                       const Text("Chỉnh sửa", style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline)),
                     ],
                   ),
                 )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(dynamic severity) {
    int val = 0;
    if (severity is int) val = severity;
    if (severity is double) val = severity.round();

    Color color = Colors.green;
    String label = 'Nhẹ';
    if (val > 7) {
      color = Colors.red;
      label = 'Khẩn cấp';
    } else if (val > 4) {
      color = Colors.orange;
      label = 'Trung bình';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        "$label ($val/10)",
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }
}
