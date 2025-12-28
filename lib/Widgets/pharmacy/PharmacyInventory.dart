
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/Inventory.dart';

class PharmacyInventory extends StatefulWidget {
  const PharmacyInventory({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyInventory> createState() => _PharmacyInventoryState();
}

class _PharmacyInventoryState extends State<PharmacyInventory> {
  final _supabase = Supabase.instance.client;
  List<Inventory> _inventoryList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      print('Current User ID: ${user?.id}');
      
      final response = await _supabase
          .from('inventory')
          .select('*, medicines(*)')
          .order('quantity', ascending: true);
      
      print('Inventory Response: $response'); // Debug print

      final data = response as List<dynamic>;
      setState(() {
        _inventoryList = data.map((e) => Inventory.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Color _getStatusColor(int quantity) {
    if (quantity <= 10) return Colors.red;
    if (quantity <= 50) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(int quantity) {
    if (quantity <= 10) return 'Sắp hết';
    if (quantity <= 50) return 'Cảnh báo';
    return 'Đủ';
  }

  List<Inventory> get _filteredInventory {
    if (_searchQuery.isEmpty) return _inventoryList;
    return _inventoryList.where((item) {
      final name = item.medicine?.name.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thanh tìm kiếm
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm thuốc...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Hàng thống kê
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('Tổng số loại', '${_inventoryList.length}', Colors.blue),
                _buildStatCard(
                  'Sắp hết', 
                  '${_inventoryList.where((i) => i.quantity <= 10).length}', 
                  Colors.red
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danh sách tồn kho
            Expanded(
              child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _filteredInventory.length,
                itemBuilder: (context, index) {
                  final item = _filteredInventory[index];
                  final medicineName = item.medicine?.name ?? 'Thuốc không rõ';
                  final unit = item.medicine?.unit ?? 'đơn vị';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0, 
                    color: Colors.white,
                     shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(FontAwesomeIcons.pills, color: Colors.blue, size: 16),
                      ),
                      title: Text(
                        medicineName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${item.quantity} $unit hiện có' + (item.expiryDate != null ? '\nHSD: ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}' : '')),
                      isThreeLine: item.expiryDate != null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.quantity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(item.quantity),
                          style: TextStyle(
                            color: _getStatusColor(item.quantity),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicineDialog,
        backgroundColor: const Color(0xFF38B2AC),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddMedicineDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _ingredientController = TextEditingController();
    final _quantityController = TextEditingController();
    final _unitController = TextEditingController();
    final _priceController = TextEditingController();
    final _expiryController = TextEditingController();
    DateTime? _selectedExpiryDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thuốc mới'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên thuốc', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ingredientController,
                  decoration: const InputDecoration(labelText: 'Hoạt chất', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Số lượng', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty == true ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Đơn vị (VD: Hộp, Vỉ)', border: OutlineInputBorder()),
                        validator: (value) => value?.isEmpty == true ? 'Bắt buộc' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Giá tiền', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _expiryController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Hạn sử dụng', 
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      _selectedExpiryDate = date;
                      _expiryController.text = "${date.day}/${date.month}/${date.year}";
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  // 1. Thêm thông tin thuốc vào bảng medicines
                  final medicineRes = await _supabase.from('medicines').insert({
                    'name': _nameController.text,
                    'active_ingredient': _ingredientController.text,
                    'unit': _unitController.text,
                    'price': double.tryParse(_priceController.text),
                  }).select().single(); // select() needed to get ID back

                  final medicineId = medicineRes['id'];

                  // 2. Thêm thông tin tồn kho vào bảng inventory
                  await _supabase.from('inventory').insert({
                    'medicine_id': medicineId,
                    'quantity': int.parse(_quantityController.text),
                    'expiry_date': _selectedExpiryDate?.toIso8601String(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    _fetchInventory(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm thành công')));
                  }
                } catch (e) {
                  debugPrint('Error adding medicine: $e');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
