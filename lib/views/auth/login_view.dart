import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant_app/viewmodels/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all( 24.0),
            child: Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                return Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          size: 64,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Student Assistant',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                        ),
                        ),
                        Text(
                          'Application System',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (authViewModel.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authViewModel.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              
                            ],
                          ),
                          
                        ),
                        if (authViewModel.errorMessage != null)
                        const SizedBox(height: 16),
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 24),
                        _buildLoginButton(context, authViewModel),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Handle forgot password action
                          },
                          child: const Text('Forgot Password?'),
                        )
                      ],
                    ),
                  ),
                )
                );
              },
            ),
          ),
        )),
      )
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      controller: _emailController,
      
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        
      ),
      validator: (value){
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: true,
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value){
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
//Handles user authentication and login validation
  Widget _buildLoginButton(BuildContext context, AuthViewModel authViewModel)  {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: authViewModel.isLoading
          ? null
          : () async {
              print('1. Login button pressed');
              if (_formKey.currentState == null)  {
                print('2. Form state is null - waiting');
                await Future.delayed(const Duration(milliseconds: 100));
              }

              if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                print('3. Form validation passed');
                print('4. Email: ${_emailController.text}, Password: ${_passwordController.text}');

                final success = await authViewModel.logIn(
                  _emailController.text.trim(),
                  _passwordController.text,
                );

                print('5. Login result: $success');

                if (success && context.mounted) {
                  print('6. Checking user role for navigation');
                  
                  // Get the current user ID
                  final userId = authViewModel.getCurrentUser()?.id;
                  
                  if (userId != null) {
                    // Get the user's role
                    final role = await authViewModel.getUserRole(userId);
                    print('7. User role: $role');
                    
                    _emailController.clear();
                    _passwordController.clear();
                    
                    if (role == 'admin') {
                      print('8. Navigating to Admin Dashboard');
                      Navigator.pushReplacementNamed(context, '/admin/dashboard');
                    } else {
                      print('8. Navigating to Student Home');
                      Navigator.pushReplacementNamed(context, '/student/home');
                    }
                  } else {
                    print('7. No user ID found - fallback to Student Home');
                    _emailController.clear();
                    _passwordController.clear();
                    Navigator.pushReplacementNamed(context, '/student/home');
                  }
                } else {
                  print('5b. Login failed');
                }
              } else {
                print('3b. Form validation failed or form state is null');
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: authViewModel.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}
}
