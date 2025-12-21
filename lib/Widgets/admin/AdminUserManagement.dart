import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({Key? key}) : super(key: key);

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _filterUsers();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _filterUsers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final email = user['email']?.toString().toLowerCase() ?? '';
          final name = user['name']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return email.contains(query) || name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _updateUser(String userId, String newRole, String newName) async {
    try {
      await supabase.from('users').update({
        'role': newRole,
        'name': newName
      }).eq('id', userId);
      
      // Update local state
      final index = _users.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        setState(() {
          _users[index]['role'] = newRole;
          _users[index]['name'] = newName;
          _filterUsers();
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    if (user['role'] == 'admin') return; 

    String selectedRole = user['role'] ?? 'patient';
    final TextEditingController nameController = TextEditingController(text: user['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter full name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Patient'),
                    value: 'patient',
                    groupValue: selectedRole,
                    onChanged: (val) => setStateDialog(() => selectedRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Doctor'),
                    value: 'doctor',
                    groupValue: selectedRole,
                    onChanged: (val) => setStateDialog(() => selectedRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Pharmacy'),
                    value: 'pharmacy',
                    groupValue: selectedRole,
                    onChanged: (val) => setStateDialog(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateUser(user['id'], selectedRole, nameController.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddUserInstruction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('To ensure security, new accounts must be verified via email.'),
             SizedBox(height: 10),
             Text('1. Log out or open a new browser window.'),
             Text('2. Use the "Sign Up" page to create a new account.'),
             Text('3. Return here to verify and promote the account to Doctor or Pharmacy.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserInstruction,
        label: const Text('Add Account'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                _searchQuery = val;
                _filterUsers();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // extra padding for FAB
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final role = user['role'] ?? 'patient';
                      // Fallback logic for display name
                      String displayName = user['name'] ?? '';
                      if (displayName.trim().isEmpty) {
                         String email = user['email'] ?? '';
                         displayName = email.isNotEmpty ? email.split('@')[0] : 'Unknown ID';
                      }
                      
                      Color roleColor = Colors.grey;
                      if (role == 'doctor') roleColor = Colors.blue;
                      if (role == 'pharmacy') roleColor = Colors.green;
                      if (role == 'admin') roleColor = Colors.red;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withOpacity(0.1),
                            child: Icon(Icons.person, color: roleColor),
                          ),
                          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${user['email'] ?? 'No Email'}\nRole: $role'),
                          isThreeLine: true,
                          trailing: role == 'admin' 
                            ? const Chip(label: Text('Admin'), backgroundColor: Colors.redAccent)
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
