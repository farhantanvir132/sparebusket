import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:sparebusket/screens/fooddetails2.dart';
import 'package:sparebusket/screens/homepage.dart';
import 'package:http/http.dart' as http;
import 'package:sparebusket/screens/message.dart';

class msgPage extends StatefulWidget {
  @override
  _msgPageState createState() => _msgPageState();
}

class _msgPageState extends State<msgPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isDonor = false;
  bool isReceiver = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 130, 80, 218),
          elevation: 0,
          title: Text('Messages'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (ctx) => HomePage(),
                ),
              );
            },
          ),
        ),
        body: StreamBuilder(
            stream: _auth.authStateChanges(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              final User? user = userSnapshot.data as User?;
              return StreamBuilder(
                stream: _firestore
                    .collection('displaymessages')
                    .where('idTo', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      documents =
                      (snapshot.data as QuerySnapshot<Map<String, dynamic>>)
                          .docs;

                  return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final data =
                            documents[index].data() as Map<String, dynamic>;

                        return FutureBuilder(
                          future: _firestore
                              .collection('users')
                              .doc(data['idfrom'])
                              .get(),
                          builder: (BuildContext context,
                              AsyncSnapshot<
                                      DocumentSnapshot<Map<String, dynamic>>>
                                  snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: SizedBox(
                                  width: 0,
                                  height: 0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final userData = snapshot.data!.data();
                            final profilePic = userData?['profilepic'];

                            return NotificationCard(
                              username: data['from'],
                              message: "Check out your latest messages!",
                              userimage: profilePic,
                              idTo: data['idfrom'],
                            );
                          },
                        );
                      });
                },
              );
            }));
  }
}

class NotificationCard extends StatelessWidget {
  final String username;
  final String message;
  final String userimage;
  final String idTo;
  NotificationCard({
    required this.username,
    required this.message,
    required this.userimage,
    required this.idTo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              userId: idTo,
              username: username,
            ),
          ),
        );
        null;
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 136, 136, 136).withOpacity(0.1),
              spreadRadius: 0.01,
              blurRadius: 0.3,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: ClipOval(
                      child: userimage != ""
                          ? Image.network(
                              userimage,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'lib/images/profile.png',
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            )),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                                Text(
                                  message,
                                  style: TextStyle(fontSize: 14),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
