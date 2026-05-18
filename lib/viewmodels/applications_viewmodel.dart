import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/application_service.dart';

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

class ApplicationsViewModel extends ChangeNotifier {
  final ApplicationService _applicationService = ApplicationService();

  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> submit({
    required String userId,
    required String yearOfStudy,
    required List<Map<String, dynamic>> modules, 
    required bool eligibilityConfirmed,
    String? documentUrl,

  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _applicationService.submitApplication(
        userId: userId,
        yearOfStudy: yearOfStudy,
        eligibilityConfirmed: eligibilityConfirmed,
        modules: modules,
        documentUrl: documentUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic>? _currentApplication;
  Map<String, dynamic>? get currentApplication => _currentApplication;

   Future<void> loadApplicationDetail(String appId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _applicationService.getApplicationById(appId);
      _currentApplication = response;
    } catch (e) {
      _errorMessage = e.toString();
      _currentApplication = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch student's applications
  Future<void> loadMyApplications(String userID) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await _applicationService.getMyApplications(userID);
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      
      notifyListeners();
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all applications for admin
  Future<void> loadAllApplications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _applications = await _applicationService.getAllApplications();
      
    } catch (e) {
      _errorMessage = e.toString();
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Update status (Admin)
  Future<void> updateStatus(String applicationId, String newStatus) async {
    

    try {
      await _applicationService.updateApplicationStatus(applicationId, newStatus);
      // After updating status, refresh the applications list
      await loadAllApplications();
      
    } catch (e) {
      _errorMessage = e.toString();
      
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Delete application (Admin)
  Future<void> deleteApplication(String applicationID) async {
    try {
      await _applicationService.deleteApplication(applicationID);
      // After deleting, refresh the applications list
      await loadAllApplications();
      
    } catch (e) {
      _errorMessage = e.toString();
      
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateApplication({
    required String applicationId,
    required String yearOfStudy,
    required List<Map<String, dynamic>> modules,
    required bool eligibilityConfirmed,
  }) async{
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try{
      await _applicationService.updateApplicationWithModules(
        applicationId: applicationId,
        yearOfStudy: yearOfStudy,
        modules: modules,
        eligibilityConfirmed: eligibilityConfirmed,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e){
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> uploadFile({
    required String userId,
    required String fileName,
    required List<int> bytes,
  }) async{
    return await _applicationService.uploadFile(userId, fileName, bytes);
  }

}