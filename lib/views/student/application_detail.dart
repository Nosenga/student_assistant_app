import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_assistant_app/viewmodels/applications_viewmodel.dart';
import 'package:student_assistant_app/services/application_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

class ApplicationDetail extends StatefulWidget {
  const ApplicationDetail({super.key});

  @override
  State<ApplicationDetail> createState() => _ApplicationDetailState();
}

class _ApplicationDetailState extends State<ApplicationDetail> {
  Map<String, dynamic>? application;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    //Ensure Context is ready
    WidgetsBinding.instance.addPostFrameCallback((_){
       _loadApplicationDetail();
    });
   
  }

  Future<void> _loadApplicationDetail() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final String? appId = args as String?;

    if (appId == null) {
      setState(() {
        _errorMessage = 'No application ID provided.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('applications')
          .select('*, module_applications(*)')
          .eq('id', appId)
          .single();

      setState(() {
        application = response as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteApplication() async {
    final appId = application!['id'] as String;
    final vm = context.read<ApplicationsViewModel>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting application...')),
    );

    try {
      await vm.deleteApplication(appId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application deleted successfully.')),
        );
        Navigator.pop(context,true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    final status = application!['status']?.toString() ?? 'Unknown';
    final isPending = status.toLowerCase() == 'pending';
    final modules = application!['module_applications'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Detail'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (isPending)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Navigate to the edit screen
               final result = await Navigator.pushNamed(context, '/application/edit', arguments: application!['id']);
               if(result == true){
                //Refresh after returning
                _loadApplicationDetail();
               }
              },
            ),
            if (isPending)
            IconButton(
              // Delete button
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 16),
            _buildApplicantInfo(),
            const SizedBox(height: 16),
            _buildModulesCardList(modules),
            const SizedBox(height: 16),
            _buildDocumentCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color color;
    String statusText;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        color = Colors.orange;
        statusText = 'Pending Review';
    }

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == 'approved' ? Icons.check : (status == 'rejected' ? Icons.close : Icons.hourglass_empty),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Application Status',
                    style: TextStyle(fontSize: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantInfo() {
    final year = application!['year_of_study']?.toString() ?? 'Unknown';
    final createdAt = application!['created_at'] != null
        ? DateTime.parse(application!['created_at']).toLocal().toString().substring(0, 16)
        : 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applicant Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Year of Study'),
              subtitle: Text(year),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Submitted'),
              subtitle: Text(createdAt),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesCardList(List<dynamic> modules) {
    if (modules.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text('No modules selected.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applied Modules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...modules.asMap().entries.map((entry) {
              final idx = entry.key;
              final module = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module ${idx + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text('Level: ${module['academic_level']}'),   // ✅ fixed interpolation
                      Text('Module: ${module['module_name']}'),     // ✅ fixed interpolation
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to delete this application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);  // ✅ removed extra comma
              _deleteApplication();     // ✅ correct method name
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  Widget _buildDocumentCard() {
  final docUrl = application?['supporting_doc_url']?.toString();
  
  if (docUrl == null || docUrl.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Supporting Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No documents uploaded'),
            ),
          ],
        ),
      ),
    );
  }
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supporting Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: const Text('Uploaded Document'),
            subtitle: Text(docUrl.split('/').last),  // Show filename from URL
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async {
                final url = docUrl;
                if(await canLaunchUrl(Uri.parse(url))){
                  await launchUrl(Uri.parse(url));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to download document: $url'))
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}

