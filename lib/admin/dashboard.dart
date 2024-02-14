import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/admin/adminlogin.dart';
import 'package:sparebusket/admin/manageusers.dart';
import 'package:sparebusket/admin/report2.dart';
import 'package:sparebusket/admin/reports.dart';
import 'package:sparebusket/admin/settings.dart';
import 'package:sparebusket/admin/userSupport.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isExpanded = false;
  int _selectedIndex = 0;

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
      isExpanded = false;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AdminLogin()),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExpanded,
            backgroundColor: Color.fromARGB(255, 0, 0, 0),
            unselectedIconTheme: const IconThemeData(
                color: Color.fromARGB(255, 216, 216, 216), opacity: 1),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.white,
            ),
            selectedIconTheme:
                const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text(
                  "Home",
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 215, 211),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report),
                label: Text(
                  "Reports",
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 215, 211),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.support_agent),
                label: Text(
                  "User Support",
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 215, 211),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text(
                  "Settings",
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 215, 211),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout_rounded),
                label: Text(
                  "LogOut",
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 215, 211),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
                isExpanded = false;
              });

              switch (index) {
                case 0:
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const Dashboard()));
                  break;
                case 1:
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => AdminReport()));
                  break;
                case 2:
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const UserSupport()));
                  break;
                case 3:
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AdminSetting()));
                  break;
                case 4:
                  _signOut(context);
                  break;
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      icon: const Icon(Icons.menu),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const AdminUsers()));
                            },
                            style: ButtonStyle(
                              minimumSize:
                                  MaterialStateProperty.all(Size(440, 80)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromARGB(255, 224, 224, 224)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(10),
                            ),
                            child: Text(
                              'Manage Users',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const AdminReport()));
                            },
                            style: ButtonStyle(
                              minimumSize:
                                  MaterialStateProperty.all(Size(440, 80)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromARGB(255, 224, 224, 224)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(10),
                            ),
                            child: Text(
                              'Reports for Donors',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const AdminReport2()));
                            },
                            style: ButtonStyle(
                              minimumSize:
                                  MaterialStateProperty.all(Size(440, 80)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromARGB(255, 224, 224, 224)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(10),
                            ),
                            child: Text(
                              'Reports for Recievers',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UserSupport(),
                                ),
                              );
                            },
                            style: ButtonStyle(
                              minimumSize:
                                  MaterialStateProperty.all(Size(440, 80)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color.fromARGB(255, 224, 224, 224)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(10),
                            ),
                            child: Text(
                              'User Support',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
