import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class StudentHome extends StatefulWidget{
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {



  @override

  void initState(){
    super.initState();
    //Delay loading 
    WidgetsBinding.instance.addPostFrameCallback((_){
      _loadData();
    });
  }

  void _loadData(){
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if(userId!=null){
      context.read<ApplicationsViewModel>().loadMyApplications(userId);
    }
  }

 

  @override
  Widget build(BuildContext context) {
    final vm=context.watch<ApplicationsViewModel>();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if(context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(  16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              alignment: Alignment.center,
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Welcome, Student!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Here you can view your applications and submit new ones.'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/application/new');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Application'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                )
              ],
            ),
            

            const SizedBox(height: 24),

            // Application Status Section
            const Text('My Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.applications.isEmpty
              ? const Center(
                child: Text('No applications found. Start by submitting a new application!'),
              )
              : ListView.builder(
                itemCount: vm.applications.length,
                itemBuilder: (context, index) {
                  final app = vm.applications[index];
                  final status = app['status'] ?? 'Pending';
                  final moduleCount = (app['module_applications'] as List<dynamic>?)?.length ?? 0;

                  final createdAt = app['created_at'] != null
                    ? DateTime.parse(app['created_at']).toString().substring(0,16)
                    : 'Unknown date';


                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status),
                          child: const Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text('Application for ${app['year_of_study']} Year'),
                        subtitle: Text('Submitted on $createdAt\nModules: $moduleCount'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        isThreeLine: true,
                        onTap: () async{
                          // Navigate to detail screen with application ID
                          final result = await Navigator.pushNamed(context, '/application/detail', arguments: app['id']);
                          //Refresh after returning
                          if(result == true){
                            final userId = Supabase.instance.client.auth.currentUser?.id;
                            if(userId !=null){
                              context.read<ApplicationsViewModel>().loadMyApplications(userId);
                            }
                          }
                        },
                    )
                    );
                },
              )
            )

          ],
        ),
      )
    );


  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
