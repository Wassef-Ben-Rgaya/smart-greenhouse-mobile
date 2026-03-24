import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';
import '../models/user.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import '../components/app_bar/gradient_app_bar.dart';
import '../components/buttons/gradient_button.dart';
import '../components/icons/edit_icon_button.dart';
import '../components/icons/delete_icon_button.dart';
import '../constants/styles.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  UserModel? currentUser;
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  bool isLoading = true;
  bool isError = false;
  final TextEditingController searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserModel) {
        setState(() {
          currentUser = args;
        });
        fetchUsers();
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    if (!mounted || currentUser == null) return;

    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      // Retrieve users from Firestore
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      if (!mounted) return;

      setState(() {
        users =
            querySnapshot.docs
                .map(
                  (doc) => UserModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isError = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void filterUsers(String query) {
    setState(() {
      filteredUsers =
          users.where((user) {
            final name =
                '${user.firstName ?? ''} ${user.lastName ?? ''}'.toLowerCase();
            final email = user.email.toLowerCase();
            final username = user.username.toLowerCase();
            final searchLower = query.toLowerCase();
            return name.contains(searchLower) ||
                email.contains(searchLower) ||
                username.contains(searchLower);
          }).toList();
    });
  }

  Future<void> _refreshUsers() async {
    await fetchUsers();
  }

  Future<void> _deleteUser(String userId) async {
    if (!mounted || currentUser == null) return;

    try {
      // Delete user from Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // If the user is deleted from Firebase Authentication (optional, only for admins)
      // Note: This requires admin privileges or a Cloud Function to delete a user
      // await FirebaseAuth.instance.currentUser?.delete(); // Implement server-side if needed

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
      await fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${user.firstName ?? ''} ${user.lastName ?? ''}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('ID', user.id),
                  _buildDetailRow('Email', user.email),
                  _buildDetailRow('Username', user.username),
                  _buildDetailRow('Role', user.role),
                  _buildDetailRow('Gender', user.gender),
                  _buildDetailRow(
                    'Date of Birth',
                    user.birthDate != null
                        ? _dateFormat.format(_dateFormat.parse(user.birthDate!))
                        : null,
                  ),
                  _buildDetailRow('Phone', user.phoneNumber),
                  _buildDetailRow('Address', user.address),
                  _buildDetailRow('City', user.city),
                  _buildDetailRow('Country', user.country),
                  _buildDetailRow('Postal Code', user.postalCode),
                  if (user.createdAt != null)
                    _buildDetailRow(
                      'Created On',
                      _dateFormat.format(user.createdAt!),
                    ),
                  if (user.updatedAt != null)
                    _buildDetailRow(
                      'Updated On',
                      _dateFormat.format(user.updatedAt!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'Unknown')),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUserScreen(onUserAdded: _refreshUsers),
      ),
    );
  }

  void _navigateToEditUser(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditUserScreen(
              user: user,
              token: FirebaseAuth.instance.currentUser?.uid ?? '',
              onUserUpdated: _refreshUsers,
            ),
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Do you really want to delete ${user.firstName ?? 'this user'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (user.id != null) {
                    await _deleteUser(user.id!);
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'User Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: CustomDrawer(user: currentUser!),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddUser,
        backgroundColor: AppStyles.secondaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              gradient: AppStyles.appBarGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: filterUsers,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshUsers,
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : isError
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Failed to Load Users',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            GradientButton(
                              text: 'Retry',
                              icon: Icons.refresh,
                              onPressed: fetchUsers,
                            ),
                          ],
                        ),
                      )
                      : filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : _buildUsersTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 50, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Users Found', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          GradientButton(
            text: 'Add User',
            icon: Icons.add,
            onPressed: _navigateToAddUser,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 80,
            columnSpacing: 30,
            horizontalMargin: 12,
            columns: const [
              DataColumn(
                label: Text('User', style: AppStyles.dataTableHeaderStyle),
              ),
              DataColumn(
                label: Text('Email', style: AppStyles.dataTableHeaderStyle),
              ),
              DataColumn(
                label: Text('Role', style: AppStyles.dataTableHeaderStyle),
              ),
              DataColumn(
                label: Text('Actions', style: AppStyles.dataTableHeaderStyle),
              ),
            ],
            rows:
                filteredUsers.map((user) {
                  return DataRow(
                    onSelectChanged: (_) => _showUserDetails(user),
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF1A781F),
                              child: Text(
                                (user.firstName?.substring(0, 1) ?? '') +
                                    (user.lastName?.substring(0, 1) ?? ''),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${user.firstName ?? ''} ${user.lastName ?? ''}',
                                  style: AppStyles.plantNameStyle,
                                ),
                                Text(
                                  user.username,
                                  style: AppStyles.scientificNameStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            user.email,
                            style: AppStyles.regularTextStyle,
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  user.role == 'admin'
                                      ? AppStyles.statusColor.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role ?? 'user',
                              style: TextStyle(
                                color:
                                    user.role == 'admin'
                                        ? AppStyles.statusColor
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EditIconButton(
                                onPressed: () => _navigateToEditUser(user),
                              ),
                              const SizedBox(width: 8),
                              DeleteIconButton(
                                onPressed: () => _showDeleteConfirmation(user),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
