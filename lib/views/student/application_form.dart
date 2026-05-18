import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_assistant_app/viewmodels/applications_viewmodel.dart';
import 'package:student_assistant_app/services/application_service.dart';

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

class ApplicationForm extends StatefulWidget {
  const ApplicationForm({super.key});

  @override
  State<ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<ApplicationForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedYear;
  bool _hasSecondModule = false;
  String? _module1Level;
  String? _module1Name;
  String? _module2Level;
  String? _module2Name;
  bool _eligibilityConfirmed = false;

  final List<String> _academicYears = ['1st', '2nd', '3rd'];
  final List<String> _academicLevels = ['1st Year', '2nd Year', '3rd Year'];
  final List<String> _moduleNames = [
    'COS101 - Introduction to Computing',
    'COS102 - Programming Fundamentals',
    'COS201 - Data Structures',
    'COS202 - Algorithms',
    'COS301 - Software Engineering',
    'COS302 - Operating Systems',
  ];

  String? _documentURL;
  bool _isUploading = false;
  String? _selectedFileName;

  //-----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated. Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Application Form'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Student Information', Icons.person),
              const SizedBox(height: 8),
              _buildYearDropdown(),
              const SizedBox(height: 16),

              _buildSectionTitle('Module 1 Application Required', Icons.library_books),
              const SizedBox(height: 8),
              _buildModule1LevelDropdown(),
              const SizedBox(height: 16),
              _buildModule1NameDropdown(),
              const SizedBox(height: 16),

              _buildSectionTitle('Module 2 Application (Optional)', Icons.add_circle_outline),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Apply for a second module?'),
                value: _hasSecondModule,
                onChanged: (value) {
                  setState(() {
                    _hasSecondModule = value;
                    if (!value) {
                      _module2Level = null;
                      _module2Name = null;
                    }
                  });
                },
                activeColor: Colors.blue.shade600,
              ),
              if (_hasSecondModule) ...[
                const SizedBox(height: 8),
                _buildModule2LevelDropdown(),
                const SizedBox(height: 16),
                _buildModule2NameDropdown(),
              ],
              const SizedBox(height: 16),

              _buildSectionTitle('Eligibility Confirmation', Icons.verified_user),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('I confirm that I meet all the minimum requirements for this position.'),
                subtitle: const Text('This includes academic performance, attendance, and any other criteria.'),
                value: _eligibilityConfirmed,
                onChanged: (value) => setState(() => _eligibilityConfirmed = value ?? false),
                activeColor: Colors.blue.shade600,
              ),
              const SizedBox(height: 24),
              // Add this after the eligibility CheckboxListTile


              // File Upload Section
              _buildSectionTitle('Supporting Documents', Icons.attach_file),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : () => _uploadDocument(userId),
                            icon: _isUploading 
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.upload_file),
                              label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.blue.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_selectedFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                              _selectedFileName!,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),



              Consumer<ApplicationsViewModel>(
                builder: (context, vm, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () => _submitApplication(vm, userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Application',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade600),
        ),
      ],
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
      items: _academicYears.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
      onChanged: (value) => setState(() => _selectedYear = value),
      validator: (value) => value == null ? 'Please select your academic year' : null,
    );
  }

  Widget _buildModule1LevelDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Module 1 Academic Level', border: OutlineInputBorder()),
      items: _academicLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
      onChanged: (value) => setState(() => _module1Level = value),
      validator: (value) => value == null ? 'Please select the academic level for Module 1' : null,
    );
  }

  Widget _buildModule1NameDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Module 1 Name', border: OutlineInputBorder()),
      items: _moduleNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
      onChanged: (value) => setState(() => _module1Name = value),
      validator: (value) => value == null ? 'Please select the module name for Module 1' : null,
    );
  }

  Widget _buildModule2LevelDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Module 2 Academic Level', border: OutlineInputBorder()),
      items: _academicLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
      onChanged: (value) => setState(() => _module2Level = value),
    );
  }

  Widget _buildModule2NameDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Module 2 Name', border: OutlineInputBorder()),
      items: _moduleNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
      onChanged: (value) => setState(() => _module2Name = value),
    );
  }

  Future<void> _submitApplication(ApplicationsViewModel vm, String userId) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_eligibilityConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm your eligibility before submitting.')),
      );
      return;
    }

    List<Map<String, String>> modules = [
      {'level': _module1Level!, 'name': _module1Name!, 'order': '1'},
    ];
    if (_hasSecondModule && _module2Level != null && _module2Name != null) {
      modules.add({'level': _module2Level!, 'name': _module2Name!, 'order': '2'});
    }

    final success = await vm.submit(
      userId: userId,
      yearOfStudy: _selectedYear!,
      eligibilityConfirmed: _eligibilityConfirmed,
      modules: modules,
      documentUrl: _documentURL,
      
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Submission failed.'), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _uploadDocument(String userId) async {
  try {
    // Pick file with allowed extensions
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      type: FileType.custom,
    );

    if (result == null) {
      print('📁 User cancelled file selection');
      return;
    }

    final file = result.files.first;
    print('📁 Selected file: ${file.name}, Size: ${file.size} bytes');

    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large. Max size is 5MB.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Check if bytes are available
    if (file.bytes == null) {
      throw Exception('Could not read file bytes');
    }

    setState(() {
      _isUploading = true;
      _selectedFileName = file.name;
    });

    // Upload to Supabase
    final vm = context.read<ApplicationsViewModel>();
    final url = await vm.uploadFile(
      userId: userId,
      fileName: file.name,
      bytes: file.bytes!,
    );

    print('✅ Upload successful: $url');

    setState(() {
      _documentURL = url;
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green),
    );
  } catch (e) {
    print('❌ Upload error: $e');
    setState(() {
      _isUploading = false;
      _selectedFileName = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error uploading document: ${e.toString().split('\n').first}'), backgroundColor: Colors.red),
    );
  }
}

}