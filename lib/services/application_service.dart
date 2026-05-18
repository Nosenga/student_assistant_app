import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class ApplicationService {
  final SupabaseClient _client = Supabase.instance.client;

  //submit application
  Future<Map<String, dynamic>> submitApplication({
    required String userId,
    required String yearOfStudy,
    required List<Map<String, dynamic>> modules, 
    required bool eligibilityConfirmed,
    String? documentUrl,
  }) async {

    // Insert application data into 'applications' table
    final applicationResponse = await _client.from('applications').insert({
      'user_id': userId,
      'year_of_study': yearOfStudy,
      'eligibility_confirmed': eligibilityConfirmed,
      'supporting_doc_url': documentUrl,
      'status': 'pending',

    }).select().single();

    final applicationID = applicationResponse['id'];

    // Insert modules data into 'module_applications' table
    for (var module in modules){
      await _client.from('module_applications').insert({
        'application_id': applicationID,
        'module_name': module['name'],
        'academic_level': module['level'],
        'module_order': module['order']
      });
    }

    return applicationResponse;
  }


  //Fetch student's applications
  Future<List<Map<String, dynamic>>> getMyApplications(String userID) async{
    final response = await _client
    .from('applications')
    .select(
      '''*,
      module_applications(*)
      '''
    )
    .eq('user_id', userID)
    .order('created_at', ascending: false);
    return response;
  }

  //Fetch all applications for admin
  Future<List<Map<String, dynamic>>> getAllApplications() async{
    final response = await _client
    .from(
      'applications'
    )
    .select(
      '''*,
      profiles (email),
      module_applications(*)
      '''
    )
    .order(
      'created_at', ascending: false

    );
    return response;
  }

  //Update application status
  Future<void> updateApplicationStatus(String applicationId, String newStatus) async {
    await _client
    .from('applications')
    .update({'status': newStatus})
    .eq('id', applicationId);
  }

  //Delete application(cascade delete modules)
  Future<void> deleteApplication(String applicationId) async {
    await _client
    .from('applications')
    .delete()
    .eq('id', applicationId);
  }

  //Update applications (while pending)
  // Future<void> updateApplication(String applicationID, String newStatus) async{
  //   await _client
  //   .from('applications')
  //   .update({'status':newStatus})
  //   .eq('id', applicationID);
  // }

  Future<Map<String, dynamic>> getApplicationById(String applicationId) async{
    final response = await _client
    .from('applications')
    .select('*, module_applications(*)')
    .eq('id', applicationId)
    .single();
    return response;
  }

  //Upload file to storage
  Future<String> uploadFile(String userId, String fileName, List<int> bytes) async {
  final filePath = '$userId/$fileName';
  try {
    print('📤 Uploading to bucket: supporting_docs');
    print('📤 File path: $filePath');
    
    await _client.storage.from('supporting_docs').uploadBinary(
      filePath, 
      Uint8List.fromList(bytes),
    );
    
    final publicUrl = _client.storage.from('supporting_docs').getPublicUrl(filePath);
    print('✅ Upload successful: $publicUrl');
    return publicUrl;
  } catch (e) {
    print('❌ Storage upload error: $e');
    rethrow;
  }
}

  //Update application and its modules (used for editing)
  Future<void> updateApplicationWithModules({
    required String applicationId,
    required String yearOfStudy,
    required List<Map<String, dynamic>> modules,
    required bool eligibilityConfirmed,
  }) async{
    // Update application data
    try{
      await _client
    .from('applications')
    .update({
      'year_of_study': yearOfStudy,
      'eligibility_confirmed': eligibilityConfirmed,
      
    })
    .eq('id', applicationId);
    print('✅ Application updated successfully');
    }catch(e){
      print('❌ Error updating application: $e');
      rethrow;
    }
    
    // Delete existing modules
    await _client
    .from('module_applications')
    .delete()
    .eq('application_id', applicationId);

    // Insert new modules
    for (var module in modules){
      await _client.from('module_applications').insert({
        'application_id':applicationId,
        'academic_level': module['level'],
        'module_name': module['name'],
        'module_order': module['order'],
      });
    }

  
  }

}