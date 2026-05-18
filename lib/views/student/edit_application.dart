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

class EditApplication extends StatefulWidget{
  const EditApplication({super.key});

  @override
  State<EditApplication> createState() => _EditApplicationState();
}

class _EditApplicationState extends State<EditApplication> {
  
  final _formKey = GlobalKey<FormState>();

  //-----------------------------------------------------

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

  String? _applicationID;
  bool _isLoading = true;

  //-----------------------------------------------------
  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _loadApplicationDetail();
    
    });
  }

  Future<void> _loadApplicationDetail() async{
    final args = ModalRoute.of(context)?.settings.arguments;
    final String? appId = args as String?;

    if(appId == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application ID provided.'))
      
      );
      Navigator.pop(context);
      return;
    }

    _applicationID = appId;

    try{
      final response = await Supabase.instance.client
      .from('applications')
      .select('*, module_applications(*)')
      .eq('id', appId)
      .single();

      final modules = response['module_applications'] as List<dynamic>?;
      final year = response['year_of_study']?.toString()?? '';

      setState(() {
        _selectedYear = year;
        _eligibilityConfirmed = response['eligibility_confirmed']?? false;
        if(modules!=null && modules.isNotEmpty){
          final module1 = modules[0] as Map<String, dynamic>;
          _module1Level = module1['academic_level'];
          _module1Name = module1['module_name'];

        }     
        if(modules!=null && modules.length>1){
          _hasSecondModule = true;
          final module2 = modules[1] as Map<String, dynamic>;
          _module2Level = module2['academic_level'];
          _module2Name = module2['module_name'];
          
        }
        _isLoading = false;
      });
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading application: $e'))
      );
      Navigator.pop(context);
    
    }
  }

  Future<void> _submitEdit(ApplicationsViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_eligibilityConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm your eligibility before saving.')),
      );
      return;
    }

    List<Map<String, dynamic>> modules = [
      {'level': _module1Level!, 'name': _module1Name!, 'order': 1},
    ];
    if (_hasSecondModule && _module2Level != null && _module2Name != null) {
      modules.add({'level': _module2Level!, 'name': _module2Name!, 'order': 2});
    }

    final success = await vm.updateApplication(
      applicationId: _applicationID!,
      yearOfStudy: _selectedYear!,
      modules: modules,
      eligibilityConfirmed: _eligibilityConfirmed,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Update failed.'), backgroundColor: Colors.red),
      );
    }
  }


  //-----------------------------------------------------
  @override
  Widget build(BuildContext context){
    if(_isLoading){
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Application')),
        body: const Center(child: CircularProgressIndicator()),

      );

    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Application'),
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
              if(_hasSecondModule)...[
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

              Consumer<ApplicationsViewModel>(
                builder:(context, vm, child){
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: vm.isLoading ? null : () => _submitEdit(vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: vm.isLoading ?
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                      : const Text('Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                      
                } ,
                )
            ],
          ),
          )
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

  Widget _buildYearDropdown(){
    return DropdownButtonFormField<String>(
      value: _selectedYear,
      decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
      items: _academicYears.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
      onChanged: (value) => setState(() => _selectedYear = value),
      validator: (value) => value == null ? 'Please select your academic year' : null,
    );
  }

  Widget _buildModule1LevelDropdown(){
    return DropdownButtonFormField<String>(
      value: _module1Level,
      decoration: const InputDecoration(labelText: 'Module 1 Academic Level', border: OutlineInputBorder()),
      items: _academicLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
      onChanged: (value) => setState(() => _module1Level = value),
      validator: (value) => value == null ? 'Please select the academic level for Module 1' : null,
    );
  }

  Widget _buildModule1NameDropdown(){
    return DropdownButtonFormField<String>(
      value: _module1Name,
      decoration: const InputDecoration(labelText: 'Module 1 Name', border: OutlineInputBorder()),
      items: _moduleNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
      onChanged: (value) => setState(() => _module1Name = value),
      validator: (value) => value == null ? 'Please select the module name for Module 1' : null,
    );
  }

  Widget _buildModule2LevelDropdown() {
    return DropdownButtonFormField<String>(
      value: _module2Level,
      decoration: const InputDecoration(labelText: 'Module 2 Academic Level', border: OutlineInputBorder()),
      items: _academicLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
      onChanged: (value) => setState(() => _module2Level = value),
    );
  }

  Widget _buildModule2NameDropdown() {
    return DropdownButtonFormField<String>(
      value: _module2Name,
      decoration: const InputDecoration(labelText: 'Module 2 Name', border: OutlineInputBorder()),
      items: _moduleNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
      onChanged: (value) => setState(() => _module2Name = value),
    );
  }

}



