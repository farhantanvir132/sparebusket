import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/admin/adminlogin.dart';
import 'package:sparebusket/admin/dashboard.dart';
import 'package:sparebusket/admin/reports.dart';
import 'package:sparebusket/constants.dart';
import 'package:sparebusket/firebase_options.dart';
import 'package:sparebusket/screens/foodpost.dart';
import 'package:sparebusket/screens/homepage.dart';
import 'package:sparebusket/screens/login.dart';
import 'package:sparebusket/screens/notification.dart';
import 'package:sparebusket/screens/pendingposts.dart';
import 'package:sparebusket/screens/profilepage.dart';
import 'package:sparebusket/screens/signup.dart';
import 'package:sparebusket/screens/splashscreen.dart';
import 'package:sparebusket/screens/userBanned.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
      apiKey: "AIzaSyA-Gx0pvNTHZpOaJdLraQES3dt3EAS_smI",
      projectId: "sparebusketapp",
      messagingSenderId: "310985158108",
      appId: "1:310985158108:web:cd5b596335b80a802ef319",
    ));
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await FirebaseMessaging.instance.getInitialMessage();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // ignore: prefer_const_constructors
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        primarySwatch: Colors.deepPurple,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: const Color(0xFFF2994A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide.none,
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFFFBFBFB),
          filled: true,
          border: defaultOutlineInputBorder,
          enabledBorder: defaultOutlineInputBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF2994A)),
          ),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (kIsWeb && snapshot.hasData) {
            return const Dashboard();
          } else if (kIsWeb) {
            return const AdminLogin();
          } else if (snapshot.hasData) {
            return HomePage();
          } else {
            return SplashScreen();
          }
        },
      ),
      // home: BannedPage(),
    );
  }
}
