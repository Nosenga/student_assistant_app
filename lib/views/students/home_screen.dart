import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import '../admininstrator/admin_screen.dart';

import '../students/student_detail.dart';
//import '../students/login_screen.dart';
//import '../students/student_detail.dart';
//import '../../viewModel/admin_viewModel.dart';
import '../../viewModel/application_viewModel.dart';
import '../../viewModel/auth_viewModel.dart';
import '../students/student_form.dart';

import '../../models/application_model.dart';
import '../../utils/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load applications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationViewModel>().loadApplications();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Consumer<ApplicationViewModel>(
        builder: (_, vm, __) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => vm.loadApplications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (vm.applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No applications yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Apply Now'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ApplicationFormScreen(),
                      ),
                    ).then((_) => vm.loadApplications()),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vm.applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final app = vm.applications[index];
              return _ApplicationCard(
                app: app,
                statusColor: _statusColor(app.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ApplicationDetailScreen(application: app),
                  ),
                ).then((_) => vm.loadApplications()),
              );
            },
          );
        },
      ),
      // FAB only shown if no application exists
      floatingActionButton: Consumer<ApplicationViewModel>(
        builder: (_, vm, __) {
          if (vm.applications.isNotEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('New Application'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApplicationFormScreen()),
            ).then((_) => vm.loadApplications()),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel app;
  final Color statusColor;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.app,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.assignment, color: statusColor),
        ),
        title: Text(
          'Module: ${app.module1Name}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Year ${app.yearOfStudy} • Level: ${app.module1Level}'),
            if (app.module2Name != null)
              Text(
                '+ ${app.module2Name}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            app.status.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          backgroundColor: statusColor.withOpacity(0.12),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: onTap,
      ),
    );
  }
}
