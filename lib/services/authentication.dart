import 'package:appdev_project/main.dart';
import 'package:appdev_project/services/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import '../main.dart';
import './ui_builder.dart';

//Instantiate after calling await FireBase.initializeApp()
class Authentication {
  final FirebaseAuth _auth;
  Authentication({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException{
      rethrow;
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}



class LogApp extends StatelessWidget {
  new({super.key, required this.userSettings});

  final UserSettings userSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cue and A Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      // StreamBuilder listens to login/logout events in real time
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const Dashboard();
          }
          return DummyLogin(userSettings: userSettings);
        },
      ),
    );
  }
}
class DummyLogin extends StatefulWidget {
  new({super.key, required this.userSettings});

  final UserSettings userSettings;

  @override
  State<DummyLogin> createState() => _DummyLoginState();
}

class _DummyLoginState extends State<DummyLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Authentication auth=Authentication();
  bool _isLogin = true;
  String errorMessage="";
  
  Future<void> _submit() async{
    try {
      final email=_emailController.text.trim();
      final password=_passwordController.text.trim();
      if (_isLogin){
        await auth.signIn(email: email, password: password);
      }
      else{
        await auth.signUp(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message??"Authenthication failed.";
      }); 
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiBuilder.appBarBuilder(this,"Login"),
      drawer: UiBuilder.drawerBuilder(this),
      body: Column(
        children: [
           SizedBox(
              width: 400,
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            SizedBox(
              width: 400,
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ),
            if (errorMessage.isNotEmpty)
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Login' : 'Create Account'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin
                  ? 'Need an account? Sign Up'
                  : 'Already have an account? Login'),
            ),
        ],
      )
    );
  }
}


