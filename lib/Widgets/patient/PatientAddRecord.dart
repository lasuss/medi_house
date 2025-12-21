import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class PatientAddRecord extends StatefulWidget {
  const PatientAddRecord({Key? key}) : super(key: key);

  @override
  State<PatientAddRecord> createState() => _PatientAddRecordState();
}

class _PatientAddRecordState extends State<PatientAddRecord> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  final SupabaseClient supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _doctors = [];
  String? _selectedDoctorId;
  bool _randomDoctor = false;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, name, email') // Using 'name' based on previous fix
          .eq('role', 'doctor');
      
      if (mounted) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;
    String? targetDoctorId = _selectedDoctorId;

    if (_randomDoctor) {
      if (_doctors.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No doctors available for random selection.')),
        );
        return;
      }
      final random = Random();
      targetDoctorId = _doctors[random.nextInt(_doctors.length)]['id'];
    }

    if (targetDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor or enable random selection.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      
      await supabase.from('records').insert({
        'patient_id': userId,
        'doctor_id': targetDoctorId,
        'symptoms': _symptomsController.text.trim(),
        'notes': _notesController.text.trim(), // Assuming 'notes' column exists for patient notes or context
        'status': 'Pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record submitted successfully!')),
        );
        context.pop(); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting record: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Create New Record', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Describe your condition',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _symptomsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe your symptoms, pain levels, duration...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => 
                        value == null || value.isEmpty ? 'Please enter your symptoms' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Additional notes (optional)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Select Doctor',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Assign Random Doctor'),
                            subtitle: const Text('We will find a suitable doctor for you'),
                            value: _randomDoctor,
                            activeColor: Colors.blue,
                            onChanged: (bool value) {
                              setState(() {
                                _randomDoctor = value;
                                if (value) _selectedDoctorId = null;
                              });
                            },
                          ),
                          if (!_randomDoctor) ...[
                            const Divider(),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Choose a doctor'),
                                value: _selectedDoctorId,
                                items: _doctors.map((doctor) {
                                  return DropdownMenuItem<String>(
                                    value: doctor['id'],
                                    child: Text(doctor['name'] ?? doctor['email'] ?? 'Unknown'),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedDoctorId = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Record',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
