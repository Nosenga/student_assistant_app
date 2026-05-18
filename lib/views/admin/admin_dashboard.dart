import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant_app/viewmodels/applications_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_assistant_app/viewmodels/applications_viewmodel.dart';

/*
  Group Names

- 223081994 - Kekeletso Malebo
- 224093660 - Mamello Dlamini
- 223044569 - Fusi Leeu
- 223058971 - Rinae Sinthumule
- 222033939 - Tshifhiwa Mafunisa
- 224079714 - Katleho Maema
- 223066258 - Bongani Nosenga
- 221010874 - Keletso Tladi
- 221007662 - Mpho Lesako
- 219013255 -  Bokhutlo  Makwele

*/

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _filterStatus = 'all'; // 'all', 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications();
    });
  }

  Future<void> _loadApplications() async {
    await context.read<ApplicationsViewModel>().loadAllApplications();
  }

  // Calculate summary counts
  Map<String, int> _getSummaryCounts(List<Map<String, dynamic>> applications) {
    int total = applications.length;
    int pending = applications.where((a) => a['status'] == 'pending').length;
    int approved = applications.where((a) => a['status'] == 'approved').length;
    int rejected = applications.where((a) => a['status'] == 'rejected').length;
    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          // Filter dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Applications')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.applications.isEmpty
              ? const Center(child: Text('No applications found'))
              : Column(
                  children: [
                    // Summary Cards
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _buildSummaryCard('Total', _getSummaryCounts(vm.applications)['total'].toString(), Colors.blue),
                          const SizedBox(width: 8),
                          _buildSummaryCard('Pending', _getSummaryCounts(vm.applications)['pending'].toString(), Colors.orange),
                          const SizedBox(width: 8),
                          _buildSummaryCard('Approved', _getSummaryCounts(vm.applications)['approved'].toString(), Colors.green),
                          const SizedBox(width: 8),
                          _buildSummaryCard('Rejected', _getSummaryCounts(vm.applications)['rejected'].toString(), Colors.red),
                        ],
                      ),
                    ),
                    // Applications List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.applications.length,
                        itemBuilder: (context, index) {
                          final app = vm.applications[index];
                          final status = app['status'] ?? 'pending';
                          
                          // Apply filter
                          if (_filterStatus != 'all' && status.toLowerCase() != _filterStatus) {
                            return const SizedBox.shrink();
                          }
                          
                          // Get student email (handle both nested and direct)
                          String studentEmail = 'Unknown email';
                          if (app['profiles'] != null) {
                            studentEmail = app['profiles']['email'] ?? 'Unknown email';
                          } else if (app['email'] != null) {
                            studentEmail = app['email'];
                          }
                          
                          final yearOfStudy = app['year_of_study'] ?? 'Unknown';
                          final modules = app['module_applications'] as List<dynamic>? ?? [];
                          final createdAt = app['created_at'] != null
                              ? DateTime.parse(app['created_at']).toLocal().toString().substring(0, 16)
                              : 'Unknown date';
                          final docUrl = app['supporting_doc_url'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(status),
                                child: Text(
                                  status[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                studentEmail,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Year: $yearOfStudy'),
                                  Text('Status: ${status.toUpperCase()}'),
                                  Text('Modules: ${modules.length}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(status.toUpperCase()),
                                backgroundColor: _getStatusColor(status).withOpacity(0.2),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Application Details
                                      const Text(
                                        'Application Details',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Student ID', app['user_id'] ?? 'Unknown'),
                                      _buildDetailRow('Year of Study', yearOfStudy),
                                      _buildDetailRow('Submitted', createdAt),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Modules
                                      const Text(
                                        'Modules Applied For',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: modules.map((module) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Text('• ${module['module_name']} (${module['academic_level']})'),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Supporting Documents
                                      const Text(
                                        'Supporting Documents',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      if (docUrl != null && docUrl.isNotEmpty)
                                        TextButton.icon(
                                          onPressed: () {
                                            // Open document URL
                                            // You can add url_launcher package for this
                                          },
                                          icon: const Icon(Icons.file_download),
                                          label: Text(docUrl.split('/').last),
                                        )
                                      else
                                        const Text('No documents uploaded'),
                                      
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      
                                      // Action Buttons (only for pending)
                                      if (status.toLowerCase() == 'pending')
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _approveApplication(context, app['id']),
                                                icon: const Icon(Icons.check),
                                                label: const Text('Approve'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _rejectApplication(context, app['id']),
                                                icon: const Icon(Icons.close),
                                                label: const Text('Reject'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _deleteApplication(context, app['id']),
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                label: const Text('Delete'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(color: Colors.red),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      
                                      if (status.toLowerCase() != 'pending')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: OutlinedButton.icon(
                                            onPressed: () => _deleteApplication(context, app['id']),
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            label: const Text('Delete Application'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _approveApplication(BuildContext context, String appId) async {
    final vm = context.read<ApplicationsViewModel>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Approving application...')),
    );
    
    try {
      await vm.updateStatus(appId, 'approved');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application approved'), backgroundColor: Colors.green),
        );
        await _loadApplications(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectApplication(BuildContext context, String appId) async {
    final vm = context.read<ApplicationsViewModel>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rejecting application...')),
    );
    
    try {
      await vm.updateStatus(appId, 'rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected'), backgroundColor: Colors.orange),
        );
        await _loadApplications(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteApplication(BuildContext context, String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to delete this application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    final vm = context.read<ApplicationsViewModel>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting application...')),
    );
    
    try {
      await vm.deleteApplication(appId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application deleted'), backgroundColor: Colors.red),
        );
        await _loadApplications(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}