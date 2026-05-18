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

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // login method
  Future<AuthResponse> signIn(String email, String password) async {

    print('X. AuthService.signIn called with email: $email');


    try {
      print('Y. Attempting signInWithPassowrd');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

     
      print('Z. SignIn Successful - User: ${response.user?.email}, Session: ${response.session != null}');
      return response;
    } catch (e) {
      print('Z-error. Sign-in failed: $e');
       rethrow;
      
    }
  }

  //logout method
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // get current session
  Future<Session?> getCurrentSession() async{
    return _client.auth.currentSession;
  }

  //get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
          

      return response['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e'); 
      return 'student';
    }
  }

  
}