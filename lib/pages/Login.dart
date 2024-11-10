import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bismillah_habitbuddy/controllers/user_controller.dart';
import 'package:iconly/iconly.dart';
import 'package:bismillah_habitbuddy/pages/HomePage.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override 
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  @override
  Widget build(BuildContext context){
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
            const Spacer(),
            Text("Habit Buddies",
            style: TextStyle(
              fontSize: 52,
              fontFamily: 'Pacifico',
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            )),
            SizedBox(height: 30),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300),
                            child: Image.asset('assets/habits.jpeg')),
            const SizedBox(height: 20),

            FilledButton.tonalIcon(
              onPressed: () async {
                try{
                  final user = await UserController.loginWithGoogle();
                  if(user != null && mounted != null && mounted){
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomePage())
                    );
                  }
                } on FirebaseAuthException catch(error){
                  print(error.message);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
                    error.message?? "Something went wrong! Please retry."
                  )));
                } catch (error) {
                  print(error);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text (error.toString())));
                }
              },
              icon: const Icon(IconlyLight.login),
              label: const Text("Login with Google"),
            ),
            const Spacer(),

          ],)
        )
        
      )

    );
  }
}
