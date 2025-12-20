
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_house/Widgets/model/Prescription.dart';

class PharmacyFilled extends StatefulWidget {
  const PharmacyFilled({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PharmacyFilled> createState() => _PharmacyFilledState();
}

class _PharmacyFilledState extends State<PharmacyFilled> {
  final _supabase = Supabase.instance.client;
  List<Prescription> _filledPrescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFilledPrescriptions();
  }

  Future<void> _fetchFilledPrescriptions() async {
    print("--- [PharmacyFilled] Start Fetching ---");
    try {
      final response = await _supabase
          .from('prescriptions')
          .select('*, doctors:doctor_id(name), patients:patient_id(name), prescription_items(*, medicines(*))')
          .eq('status', 'Filled')
          .order('created_at', ascending: false);
      
      print("--- [PharmacyFilled] Got Response ---");
      // print("Response data: $response");

      final data = response as List<dynamic>;
      print("--- [PharmacyFilled] Data items count: ${data.length} ---");

      final List<Prescription> parsedList = [];
      for (var json in data) {
         try {
             // Debug print item ID if possible
             // print("Parsing item: ${json['id']}");
             final p = Prescription.fromJson(json);
             parsedList.add(p);
         } catch (parseErr) {
             print("!!! [PharmacyFilled] Parse Error for item ${json['id']}: $parseErr");
         }
      }
      
      if (mounted) {
        setState(() {
          _filledPrescriptions = parsedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('!!! [PharmacyFilled] Error fetching history: $e');
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Light Theme Design matching Pending Screen
    return Column(
      children: [
        // Optional Header or Filter could go here
        
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _filledPrescriptions.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  itemCount: _filledPrescriptions.length,
                  itemBuilder: (context, index) {
                    final item = _filledPrescriptions[index];
                    return _buildHistoryCard(item);
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
          Icon(Icons.history_edu, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Filled Prescriptions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your history will appear here.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Prescription item) {
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
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent),
        tilePadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC6F6D5),
          child: const FaIcon(FontAwesomeIcons.check, size: 16, color: Color(0xFF2F855A)),
        ),
        title: Text(
          item.patientName ?? 'Unknown Patient',
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Color(0xFF2D3748),
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Dr. ${item.doctorName ?? 'Unknown'}',
               style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            Text(
              'Filled on: ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2,'0')}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF7FAFC),
            child: Text(
              'MEDICATIONS (${item.items.length})',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey
              ),
            ),
          ),
          ...item.items.map((pi) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.medication_outlined, size: 18, color: Colors.grey),
              title: Text(pi.medicine?.name ?? 'Unknown Medicine', 
                style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF4A5568))),
              subtitle: Text(pi.instructions ?? 'No instructions', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text('x${pi.quantity}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          )).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
