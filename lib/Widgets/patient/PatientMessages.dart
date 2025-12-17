import 'package:flutter/material.dart';
import 'package:medi_house/Widgets/patient/PatientChatScreen.dart';

class PatientMessages extends StatefulWidget {
 const PatientMessages({Key? key, this.title}) : super(key: key);
 final String? title;
 @override
 State<PatientMessages> createState() => _PatientMessagesState();
}

class _PatientMessagesState extends State<PatientMessages> {
 final List<Map<String, dynamic>> _conversations = [
   {
     'name': 'Dr. Evelyn Reed',
     'role': 'Doctor',
     'lastMessage': 'You: Thanks for the clarification!',
     'time': '10:42 AM',
     'unreadCount': 0,
     'avatar': 'ER'
   },
   {
     'name': 'Downtown Pharmacy',
     'role': 'Pharmacy',
     'lastMessage': 'Your prescription is ready for pickup.',
     'time': 'Yesterday',
     'unreadCount': 1,
     'avatar': 'DP'
   },
   {
     'name': 'Dr. Alan Grant',
     'role': 'Doctor',
     'lastMessage': 'Please schedule a follow-up appointment.',
     'time': 'Tue',
     'unreadCount': 0,
     'avatar': 'AG'
   },
 ];

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: Colors.white, 
     appBar: AppBar(
       title: const Text(
         'Messages',
         style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), 
       ),
       backgroundColor: Colors.white, 
       elevation: 0,
     ),
     body: SafeArea(
       child: Column(
         children: [
           _buildSearchBar(),
           _buildConversationList(),
         ],
       ),
     ),
   );
 }

 Widget _buildSearchBar() {
   return Padding(
     padding: const EdgeInsets.all(16.0),
     child: TextField(
       decoration: InputDecoration(
         hintText: 'Search messages...',
         hintStyle: TextStyle(color: Colors.grey[600]), 
         prefixIcon: Icon(Icons.search, color: Colors.grey[600]), 
         filled: true,
         fillColor: Colors.grey[200], 
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8.0),
           borderSide: BorderSide.none,
         ),
       ),
     ),
   );
 }

 Widget _buildConversationList() {
   return Expanded(
     child: ListView.separated(
       itemCount: _conversations.length,
       separatorBuilder: (context, index) => Divider(
         color: Colors.grey.withOpacity(0.2),
         height: 1,
         indent: 80,
       ),
       itemBuilder: (context, index) {
         final conversation = _conversations[index];
         return ListTile(
           leading: CircleAvatar(
             backgroundColor: Colors.blue, 
             child: Text(
               conversation['avatar'],
               style: const TextStyle(color: Colors.white),
             ),
           ),
           title: Text(
             conversation['name'],
             style: const TextStyle(
               color: Colors.blue, 
               fontWeight: FontWeight.bold,
             ),
           ),
           subtitle: Text(
             conversation['lastMessage'],
             style: TextStyle(color: Colors.grey[600]), 
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
           ),
           trailing: Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                 conversation['time'],
                 style: TextStyle(
                   color: conversation['unreadCount'] > 0 ? Colors.blue : Colors.grey[600], 
                   fontSize: 12,
                 ),
               ),
               const SizedBox(height: 4),
               if (conversation['unreadCount'] > 0)
                 Container(
                   padding: const EdgeInsets.all(6),
                   decoration: const BoxDecoration(
                     color: Colors.blue, 
                     shape: BoxShape.circle,
                   ),
                   child: Text(
                     conversation['unreadCount'].toString(),
                     style: const TextStyle(
                       color: Colors.white,
                       fontSize: 10,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 )
               else
                 const SizedBox(height: 22), // to align with unread count
             ],
           ),
           onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientChatScreen(name: conversation['name']),
                ),
              );
           },
         );
       },
     ),
   );
 }
}
