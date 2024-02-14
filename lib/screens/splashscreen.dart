import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/screens/login.dart';
import 'package:sparebusket/screens/signup.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 140, 105, 219),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Image.asset(
                'lib/images/foodDelivery.png',
                width: 250,
              ),
              SizedBox(height: 10),
              Text(
                'SpareBusket',
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0)),
              ),
              SizedBox(height: 10),
              Text(
                'A food sharing app',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
              Text(
                'with others',
                style:
                    TextStyle(fontSize: 16, color: Colors.grey[300], height: 2),
              ),
              SizedBox(height: 10),
              Text(
                'We Believe Sharing is Caring',
                style: TextStyle(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    height: 2),
              ),
              SizedBox(height: 30),
              Container(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: Color.fromARGB(255, 179, 138, 250),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
