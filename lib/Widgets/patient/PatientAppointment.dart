import 'package:flutter/material.dart';

class PatientAppointment extends StatefulWidget {
  const PatientAppointment({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  State<PatientAppointment> createState() => _PatientAppointmentState();
}

class _PatientAppointmentState extends State<PatientAppointment> {
  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'doctor': 'Dr. Evelyn Reed',
      'specialty': 'Dermatologist',
      'date': 'Nov 10, 2023',
      'time': '11:00 AM',
      'avatar': 'ER'
    },
    {
      'doctor': 'Dr. Alan Grant',
      'specialty': 'Cardiologist',
      'date': 'Nov 15, 2023',
      'time': '2:30 PM',
      'avatar': 'AG'
    },
  ];

  final List<Map<String, dynamic>> _pastAppointments = [
    {
      'doctor': 'Dr. Sarah Johnson',
      'specialty': 'General Practitioner',
      'date': 'Sep 21, 2023',
      'time': '9:00 AM',
      'avatar': 'SJ'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lịch hẹn',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () {
              // Handle booking new appointment
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Upcoming'),
          const SizedBox(height: 10),
          ..._upcomingAppointments.map((appt) => _buildAppointmentCard(appt, isUpcoming: true)),
          const SizedBox(height: 20),
          _buildSectionTitle('Past'),
          const SizedBox(height: 10),
          ..._pastAppointments.map((appt) => _buildAppointmentCard(appt, isUpcoming: false)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(appointment['avatar'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['doctor'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      appointment['specialty'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(appointment['date'], style: TextStyle(color: Colors.grey[800])),
                const Spacer(),
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(appointment['time'], style: TextStyle(color: Colors.grey[800])),
              ],
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Reschedule', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
