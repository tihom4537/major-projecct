import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'user_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiService>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ApiService>().fetchUsers(),
          ),
        ],
      ),
      body: Consumer<ApiService>(
        builder: (context, apiService, child) {
          return Column(
            children: [
              _buildStatisticsCards(apiService),
              _buildSearchAndFilter(),
              Expanded(
                child: apiService.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : apiService.error != null
                    ? _buildErrorWidget(apiService.error!)
                    : _buildUsersTable(apiService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(ApiService apiService) {
    final counts = apiService.signalStatusCounts;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total', apiService.users.length, Colors.blue),
          const SizedBox(width: 8),
          _buildStatCard('Strong', counts['Strong'] ?? 0, Colors.green),
          const SizedBox(width: 8),
          _buildStatCard('Good', counts['Good'] ?? 0, Colors.lightGreen),
          const SizedBox(width: 8),
          _buildStatCard('Weak', counts['Weak'] ?? 0, Colors.orange),
          const SizedBox(width: 8),
          _buildStatCard('No Data', counts['No Data'] ?? 0, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: ['All', 'Strong', 'Good', 'Weak', 'No Data']
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status, style: const TextStyle(fontSize: 14)),
              ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedFilter = value ?? 'All'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ApiService>().fetchUsers(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(ApiService apiService) {
    List<UserModel> filteredUsers = apiService.searchUsers(_searchQuery);

    if (_selectedFilter != 'All') {
      filteredUsers = filteredUsers
          .where((user) => user.signalStatus == _selectedFilter)
          .toList();
    }

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surfaceVariant,
          ),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Age', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Blood', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NIR', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Red (630nm)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Clear', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Signal', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Last Reading', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredUsers.map((user) => _buildDataRow(user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(UserModel user) {
    final reading = user.latestReading;

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: user.statusColor.withOpacity(0.2),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    color: user.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text('${user.age}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.gender == 'Male' ? Icons.male : Icons.female,
                size: 16,
                color: user.gender == 'Male' ? Colors.blue : Colors.pink,
              ),
              const SizedBox(width: 4),
              Text(user.gender),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user.bloodGroup,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Text(
            reading != null ? '${reading.channels.nir}' : '-',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[700]),
          ),
        ),
        DataCell(
          Text(
            reading != null ? '${reading.channels.f7_630nm}' : '-',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
        ),
        DataCell(
          Text(
            reading != null ? '${reading.channels.clearChannel}' : '-',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.signalStatus,
              style: TextStyle(
                color: user.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            reading != null ? _formatDateTime(reading.readingTakenAt) : 'Never',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _navigateToUserDetail(user),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _confirmDelete(user),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  void _navigateToUserDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(userId: user.id!),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? All readings will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ApiService>().deleteUser(user.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}