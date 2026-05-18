import 'package:flutter/material.dart';
import 'package:student_assistant_app/viewmodels/applications_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/student/student_home.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/student/application_form.dart';
import 'views/student/application_detail.dart';
import 'views/student/edit_application.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fesevypeonmbuvgtrdxp.supabase.co',
    anonKey: 'sb_publishable_au93zY2pe6rJbWt5DowUVQ_B5YveVJo',

    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ApplicationsViewModel()),
      ],  
      child: MaterialApp(
        title: 'Student Assistant App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginView(),
          '/student/home': (context) => const StudentHome(),
          '/admin/dashboard': (context) => const AdminDashboard(),
          '/application/new': (context) => const ApplicationForm(),
          '/application/detail': (context) => const ApplicationDetail(),
          '/application/edit': (context) => const EditApplication(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
    
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
    
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
      final session = Supabase.instance.client.auth.currentSession;
      print('Session: $session'); // Add this
  
      if (session != null) {
        print('User is logged in: ${session.user.email}'); // Add this
        // ... rest of code
        return FutureBuilder(
          future: context.read<AuthViewModel>().getUserRole(session.user.id),
          builder: (context, roleSnapshot) {
            if(roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final role = roleSnapshot.data?? 'student';
            if(role == 'admin') {
              return const AdminDashboard();
            } else {
              return const StudentHome();
            }
          },
        );
      }
  
      print('No session found'); // Add this
      return const LoginView();
      },
    );

  }
}
