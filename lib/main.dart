import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:minetech_project/pages/threeD_page.dart';
// import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      // home: LoginPage(),
      home: , // Jo page test karna hai woh page idhar call karo
    );
  }
}
