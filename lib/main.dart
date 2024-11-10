import 'package:bismillah_habitbuddy/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bismillah_habitbuddy/controllers/user_controller.dart';
import 'package:bismillah_habitbuddy/pages/Login.dart';
import 'package:bismillah_habitbuddy/pages/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
    const MyApp({super.key});
    @override
  Widget build(BuildContext context) {
       return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Habit Buddy',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: UserController.user != null ? const HomePage() : const LoginPage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  
}

class MyHomePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(child: Column(
        children: <Widget>[
        
          Text('HabitBuddy'),
          SizedBox(height: 50),

          Text('One habit at a time for success!'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {

            },
            child: Text('Login')
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: (){

            }, 
            child: Text('Sign Up'))
        ],
        ),
    ),
    );
  }
}