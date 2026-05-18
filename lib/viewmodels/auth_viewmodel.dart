import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant_app/services/auth_service.dart';
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

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    _currentUser = _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> logIn(String email, String password) async {
    print('A. AuthViewModel.logIn called with email: $email');


    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print('B. Calling AuthService.signIn with email: $email');


    try {
      final response = await _authService.signIn(email, password);
        print('C. AuthService.signIn completed - User: ${response.user?.email}');


       if(response.user != null) {
        _isLoading = false;
        notifyListeners();

        print('D. Login successful - return true');
        return true;
       }

       print('E. Response.user is null - Login failed');
        

       _isLoading = false;
       notifyListeners();
       return false;
    } catch (e) {
      print('F. Login error: $e');
      _errorMessage = _getFriendlyErrorMessage( e.toString());
      _isLoading = false;
      notifyListeners();
      return false; 
    }
  }
  //logout method
  Future<void> logOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  //get user role
  Future<String?> getUserRole(String userId) async {
    return await _authService.getUserRole(userId);
  }
  // get current user
  User? getCurrentUser() {
    return _authService.getCurrentUser();
  }

  //helper method to convert error messages to user-friendly format
  String _getFriendlyErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if(error.contains('Email not confirmed')) {
      return 'Email not confirmed. Please check your inbox and click the confirmation link.';
    }
    return 'Login failed. Please try again.';
  }
}