import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:medi_house/Widgets/common/CCCDScanner.dart';
import 'package:medi_house/helpers/UserManager.dart';

class PatientAddProfile extends StatefulWidget {
  const PatientAddProfile({Key? key}) : super(key: key);

  @override
  State<PatientAddProfile> createState() => _PatientAddProfileState();
}

class _PatientAddProfileState extends State<PatientAddProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalIdController = TextEditingController(); // CCCD
  final _bhytController = TextEditingController(); // Health Insurance
  final _jobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressStreetController = TextEditingController();

  // Selections
  String _gender = 'Nam';
  bool _useMyInfo = false;
  String? _selectedJob;
  String? _selectedCountry = 'Việt Nam';
  String? _selectedEthnicity;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  // Mock Data
  final List<String> _jobs = ['Học sinh/Sinh viên', 'Nhân viên văn phòng', 'Công nhân', 'Kinh doanh tự do', 'Hưu trí', 'Khác'];
  final List<String> _ethnicities = ['Kinh', 'Tày', 'Thái', 'Mường', 'Khmer', 'Hoa', 'Nùng', 'H\'Mông'];
  final List<String> _countries = ['Việt Nam', 'Khác'];
  final List<String> _provinces = ['TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ', 'Hải Phòng', 'Bình Dương'];
  
  bool _isLoading = false;

  Future<void> _submit() async { // Submit form
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      // Basic date parsing (DD/MM/YYYY)
      final parts = _dobController.text.split('/');
      final dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));

      await supabase.from('patient_profiles').insert({
        'user_id': supabase.auth.currentUser!.id,
        'full_name': _nameController.text.trim(),
        'dob': dob.toIso8601String(),
        'gender': _gender,
        'national_id': _nationalIdController.text.trim(),
        'health_insurance_code': _bhytController.text.trim(),
        'job': _selectedJob,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'country': _selectedCountry,
        'ethnicity': _selectedEthnicity,
        'address_province': _selectedProvince,
        'address_district': _selectedDistrict,
        'address_ward': _selectedWard,
        'address_street': _addressStreetController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo hồ sơ thành công!')));
        context.pop(true); // Return result to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleScanCCCD() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CCCDScanner(),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _nameController.text = result['name'] ?? '';
        _dobController.text = result['dob'] ?? '';
        _nationalIdController.text = result['id'] ?? '';
        _gender = (result['gender'] == 'Nam' || result['gender'] == 'Nữ') ? result['gender']! : 'Nam';
        _addressStreetController.text = result['address'] ?? ''; // Tạm dùng toàn bộ địa chỉ cho street, có thể reset dropdown hoặc để người dùng chỉnh lại
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã điền thông tin từ CCCD!')),
      );
    }
  }

  Future<void> _syncInfo(bool? value) async { // Đồng bộ hóa thông tin từ tài khoản
    setState(() => _useMyInfo = value ?? false);
    
    if (_useMyInfo) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        try {
          final data = await supabase.from('users').select().eq('id', user.id).single();
          if (mounted) {
            setState(() {
              _nameController.text = data['name'] ?? '';
              
              // Handle DOB
              final dobStr = data['dob'];
              if (dobStr != null) {
                 // Try parsing YYYY-MM-DD
                 try {
                   final date = DateTime.parse(dobStr);
                   _dobController.text = DateFormat('dd/MM/yyyy').format(date);
                 } catch (_) {
                   _dobController.text = dobStr; 
                 }
              }

              _nationalIdController.text = data['national_id'] ?? '';
              _gender = data['gender'] ?? 'Nam';
              _phoneController.text = data['phone'] ?? '';
              _emailController.text = data['email'] ?? '';
              _addressStreetController.text = data['address'] ?? '';
              
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đồng bộ thông tin của bạn')));
          }
        } catch (e) {
           if(mounted) setState(() => _isLoading = false);
        }
      }
    } else {
      // Khi người dùng bỏ chọn, nên reset các trường để tránh nhầm lẫn hoặc cho phép nhập thủ công nếu cần
      setState(() {
        _nameController.clear();
        _dobController.clear();
        _nationalIdController.clear();
        _phoneController.clear();
        _emailController.clear();
        _addressStreetController.clear();
        _gender = 'Nam';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo mới hồ sơ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.blue.withOpacity(0.05),
              child: const Text(
                'Vui lòng cung cấp thông tin chính xác để được phục vụ tốt nhất.',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SCAN BUTTON & SYNC
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _useMyInfo ? null : _handleScanCCCD, // Tắt chức năng quét nếu sử dụng thông tin của tôi.
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('QUÉT MÃ BHYT/CCCD'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    
                    CheckboxListTile(
                      value: _useMyInfo, 
                      onChanged: _syncInfo,
                      title: const Text("Sử dụng thông tin của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    
                    // Helper text matching Edit Profile
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Các thông tin định danh (Tên, CCCD, Ngày sinh, Địa chỉ, Giới tính) được tự động điền từ QR CCCD và không thể sửa thủ công.',
                              style: TextStyle(color: Colors.orange[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION: Info Header
                    const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    _buildTextField(label: 'Họ và tên (có dấu)', controller: _nameController, hint: 'Tự động điền', required: true, readOnly: true),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Ngày sinh', 
                            controller: _dobController, 
                            hint: 'DD/MM/YYYY', 
                            required: true,
                            isDate: true,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                         // Gender is locked, display as disabled dropdown or text field
                        Expanded(child: _buildTextField(label: 'Giới tính', controller: TextEditingController(text: _gender), readOnly: true)),
                      ],
                    ),

                    _buildTextField(label: 'Mã định danh/CCCD', controller: _nationalIdController, hint: 'Tự động điền', required: true, subLabel: 'Vui lòng nhập đúng để không bị từ chối', readOnly: true),
                    _buildTextField(label: 'Mã bảo hiểm y tế', controller: _bhytController, hint: 'Mã bảo hiểm y tế'),
                    
                    _buildDropdown(label: 'Nghề nghiệp', value: _selectedJob, items: _jobs, hint: 'Chọn nghề nghiệp', onChanged: (v) => setState(() => _selectedJob = v)),
                    
                    _buildTextField(label: 'Số điện thoại', controller: _phoneController, hint: '09xxxxxxxx', required: true, prefix: '+84'),
                    _buildTextField(label: 'Email (nhận phiếu khám)', controller: _emailController, hint: 'Email'),

                    _buildDropdown(label: 'Quốc gia', value: _selectedCountry, items: _countries, onChanged: (v) => setState(() => _selectedCountry = v), required: true),
                    _buildDropdown(label: 'Dân tộc', value: _selectedEthnicity, items: _ethnicities, hint: 'Chọn Dân tộc', onChanged: (v) => setState(() => _selectedEthnicity = v), required: true),

                    const SizedBox(height: 24),
                    const Text('Địa chỉ theo CCCD (cũ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Address fields locked as they come from QR
                    _buildTextField(
                      label: 'Địa chỉ đầy đủ', 
                      controller: _addressStreetController, 
                      hint: 'Tự động điền', 
                      required: true,
                      readOnly: true,
                      maxLines: 2
                    ),
                    // Hide individual dropdowns if we use full address, or keep them for refinement if needed?
                    // User asked to match EditProfile which has one address field. 
                    // I'll hide the dropdowns to simplify and match "Read Only" constraint effectively.

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Tạo mới hồ sơ', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required TextEditingController controller, 
    String? hint, 
    bool required = false,
    String? subLabel,
    String? prefix,
    bool isDate = false,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              children: required ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
            ),
          ),
          if (subLabel != null)
             Padding(
               padding: const EdgeInsets.only(top: 4, bottom: 4),
               child: Text(subLabel, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
             ), 
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixText: prefix != null ? '$prefix ' : null,
              filled: true,
              fillColor: readOnly ? Colors.grey[100] : Colors.white,
              suffixIcon: readOnly ? const Icon(Icons.lock, size: 16, color: Colors.grey) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: required ? (v) => v!.isEmpty ? 'Vui lòng nhập thông tin' : null : null,
            keyboardType: isDate || prefix != null ? TextInputType.number : TextInputType.text,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              children: required ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            validator: required ? (v) => v == null ? 'Vui lòng chọn' : null : null,
          ),
        ],
      ),
    );
  }
}
