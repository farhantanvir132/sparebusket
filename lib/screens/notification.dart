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
import 'package:sparebusket/screens/receiverprofile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(NotificationApp());
}

Future<void> updateNotificationCount() async {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('donorId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({
          'ncount': "0",
        });
      }
    });

    FirebaseFirestore.instance
        .collection('notiforreceiver')
        .where('receiverId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        FirebaseFirestore.instance
            .collection('notiforreceiver')
            .doc(doc.id)
            .update({
          'ncount': "0",
        });
      }
    });
  }
}

class NotificationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationPage(),
    );
  }
}

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isDonor = false;
  bool isReceiver = false;
  @override
  void initState() {
    super.initState();
    updateNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final currentTime1 = DateTime.now();
    final formattedTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime1);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 130, 80, 218),
        elevation: 0,
        title: Text('Notifications'),
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

          if (user != null) {
            return StreamBuilder(
              stream: _firestore
                  .collection('notifications')
                  .where('donorId', isEqualTo: user.uid)
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, donorSnapshot) {
                if (!donorSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    donorDocuments =
                    (donorSnapshot.data as QuerySnapshot<Map<String, dynamic>>)
                        .docs;

                return StreamBuilder(
                  stream: _firestore
                      .collection('notiforreceiver')
                      .where('receiverId', isEqualTo: user.uid)
                      .orderBy('time', descending: true)
                      .snapshots(),
                  builder: (context, receiverSnapshot) {
                    if (!receiverSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        receiverDocuments = (receiverSnapshot.data
                                as QuerySnapshot<Map<String, dynamic>>)
                            .docs;

                    return StreamBuilder(
                      stream: _firestore.collection('foodposts').snapshots(),
                      builder: (context, foodRequestSnapshot) {
                        if (!foodRequestSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                            foodRequestDocuments = (foodRequestSnapshot.data
                                    as QuerySnapshot<Map<String, dynamic>>)
                                .docs;

                        bool isDonor = false;
                        bool isReceiver = false;

                        for (var notificationDocument in donorDocuments) {
                          final notificationData = notificationDocument.data()
                              as Map<String, dynamic>;
                          for (var foodRequestDocument
                              in foodRequestDocuments) {
                            final foodRequestData = foodRequestDocument.data()
                                as Map<String, dynamic>;
                            final foodRequestId = foodRequestDocument.id;
                            if (notificationData['donorId'] == user.uid &&
                                notificationData['donorId'] ==
                                    foodRequestData['donorId'] &&
                                notificationData['foodId'] == foodRequestId) {
                              isDonor = true;
                            }
                          }
                          if (isDonor) {
                            break;
                          }
                        }
                        for (var document in receiverDocuments) {
                          final datare = document.data();

                          for (var foodRequestDocument
                              in foodRequestDocuments) {
                            final foodRequestData = foodRequestDocument.data();
                            final foodRequestId = foodRequestDocument.id;

                            if (datare['receiverId'] == user.uid &&
                                datare['donorId'] ==
                                    foodRequestData['donorId'] &&
                                datare['foodId'] == foodRequestId) {
                              isReceiver = true;
                              print("rec true");
                              break;
                            }
                          }

                          if (isReceiver == true) {
                            break;
                          }
                        }

                        if (isDonor && isReceiver) {
                          List<QueryDocumentSnapshot<Map<String, dynamic>>>
                              combinedNotifications = [];
                          combinedNotifications.addAll(donorDocuments);
                          combinedNotifications.addAll(receiverDocuments);

                          combinedNotifications.sort((a, b) {
                            final aTime = DateTime.parse(a['time'] as String);
                            final bTime = DateTime.parse(b['time'] as String);
                            return bTime.compareTo(aTime);
                          });

                          return ListView.builder(
                            itemCount: combinedNotifications.length,
                            itemBuilder: (context, index) {
                              final notification = combinedNotifications[index]
                                  .data() as Map<String, dynamic>;

                              final storedTimeString =
                                  notification['time'] as String;
                              final storedTime =
                                  DateTime.parse(storedTimeString);
                              final currentTime = DateTime.now();
                              final timeDifference =
                                  currentTime.difference(storedTime);

                              String timeAgoText = '';

                              if (timeDifference.inDays > 0) {
                                timeAgoText =
                                    DateFormat.yMMMd().format(storedTime);
                              } else if (timeDifference.inHours > 0) {
                                timeAgoText =
                                    '${timeDifference.inHours} hr ago';
                              } else if (timeDifference.inMinutes > 0) {
                                timeAgoText =
                                    '${timeDifference.inMinutes} min ago';
                              } else {
                                timeAgoText = 'Just now';
                              }
                              final isUserReceiver =
                                  notification['receiverId'] == user.uid;

                              final username = isUserReceiver
                                  ? notification['donorname'] ??
                                      "Donor Name Unavailable"
                                  : notification['receivername'] ??
                                      "Receiver Name Unavailable";

                              final Id = notification['receiverId'] == user.uid
                                  ? notification['donorId']
                                  : notification['receiverId'];
                              final profilePic =
                                  _firestore.collection('users').doc(Id).get();

                              return FutureBuilder(
                                future: profilePic,
                                builder: (BuildContext context,
                                    AsyncSnapshot<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>
                                        snapshot) {
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
                                  final profileData = snapshot.data!.data();
                                  final profilePic = profileData?['profilepic'];
                                  return NotificationCard(
                                    username: username,
                                    message: notification['message'],
                                    userimage: profilePic,
                                    isDonor: true,
                                    isReceiver: true,
                                    ncount: notification['ncount'] ?? "0",
                                    time: timeAgoText,
                                    foodIds: notification['foodId'],
                                    receiverId: notification['receiverId'],
                                    donorId: notification['donorId'],
                                    ondelete1: () async {
                                      final String foodId =
                                          notification['foodId'] as String;
                                      if (notification['receiverId'] ==
                                          user.uid) {
                                        _firestore
                                            .collection('notiforreceiver')
                                            .where('foodId', isEqualTo: foodId)
                                            .get()
                                            .then((querySnapshot) {
                                          if (querySnapshot.docs.isNotEmpty) {
                                            final documentReference =
                                                querySnapshot
                                                    .docs.first.reference;
                                            documentReference
                                                .delete()
                                                .then((_) {
                                              print(
                                                  'Notifireceiver document deleted.');
                                            }).catchError((error) {
                                              print(
                                                  'Error deleting notiforreceiver document: $error');
                                            });
                                          } else {
                                            print(
                                                'Notifireceiver document with foodId not found.');
                                          }
                                        }).catchError((error) {
                                          print(
                                              'Error querying notifireceiver documents: $error');
                                        });
                                      } else {
                                        _firestore
                                            .collection('notifications')
                                            .where('foodId', isEqualTo: foodId)
                                            .get()
                                            .then((querySnapshot) {
                                          if (querySnapshot.docs.isNotEmpty) {
                                            final documentReference =
                                                querySnapshot
                                                    .docs.first.reference;
                                            documentReference
                                                .delete()
                                                .then((_) {
                                              print(
                                                  'Notification document deleted.');
                                            }).catchError((error) {
                                              print(
                                                  'Error deleting notification document: $error');
                                            });
                                          } else {
                                            print(
                                                'Notification document with foodId not found.');
                                          }
                                        }).catchError((error) {
                                          print(
                                              'Error querying notification documents: $error');
                                        });
                                      }

                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (ctx) => HomePage(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        } else if (isDonor) {
                          return ListView.builder(
                            itemCount: donorDocuments.length,
                            itemBuilder: (context, index) {
                              final data = donorDocuments[index].data()
                                  as Map<String, dynamic>;
                              final storedTimeString = data['time'] as String;

                              final storedTime =
                                  DateTime.parse(storedTimeString);

                              final currentTime = DateTime.now();
                              final timeDifference =
                                  currentTime.difference(storedTime);

                              String timeAgoText = '';

                              if (timeDifference.inDays > 0) {
                                timeAgoText =
                                    DateFormat.yMMMd().format(storedTime);
                              } else if (timeDifference.inHours > 0) {
                                timeAgoText =
                                    '${timeDifference.inHours} hr ago';
                              } else if (timeDifference.inMinutes > 0) {
                                timeAgoText =
                                    '${timeDifference.inMinutes} min ago';
                              } else {
                                timeAgoText = 'Just now';
                              }
                              return FutureBuilder(
                                future: _firestore
                                    .collection('users')
                                    .doc(data['receiverId'])
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>
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
                                    username: data['receivername'],
                                    message: data['message'],
                                    userimage: profilePic,
                                    isDonor: isDonor,
                                    isReceiver: false,
                                    ncount: data['ncount'] ?? "0",
                                    time: timeAgoText,
                                    foodIds: data['foodId'],
                                    receiverId: data['receiverId'],
                                    donorId: data['donorId'],
                                    ondelete: () async {
                                      final String foodId =
                                          data['foodId'] as String;
                                      _firestore
                                          .collection('notifications')
                                          .where('foodId', isEqualTo: foodId)
                                          .get()
                                          .then((querySnapshot) {
                                        if (querySnapshot.docs.isNotEmpty) {
                                          final documentReference =
                                              querySnapshot
                                                  .docs.first.reference;

                                          documentReference.delete().then((_) {
                                            print(
                                                'Notification document deleted successfully.');
                                          }).catchError((error) {
                                            print(
                                                'Error deleting notification document: $error');
                                          });
                                        } else {
                                          print(
                                              'Notification document with foodId not found.');
                                        }
                                      }).catchError((error) {
                                        print(
                                            'Error querying notification documents: $error');
                                      });
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (ctx) => HomePage(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        } else if (isReceiver) {
                          return ListView.builder(
                            itemCount: receiverDocuments.length,
                            itemBuilder: (context, index) {
                              final receiverData = receiverDocuments[index]
                                  .data() as Map<String, dynamic>;
                              final storedTimeString1 =
                                  receiverData['time'] as String;

                              final storedTime1 =
                                  DateTime.parse(storedTimeString1);
                              final currentTime1 = DateTime.now();
                              final timeDifference1 =
                                  currentTime1.difference(storedTime1);

                              String timeAgoText1 = '';

                              if (timeDifference1.inDays > 0) {
                                timeAgoText1 =
                                    DateFormat.yMMMd().format(storedTime1);
                              } else if (timeDifference1.inHours > 0) {
                                timeAgoText1 =
                                    '${timeDifference1.inHours} hr ago';
                              } else if (timeDifference1.inMinutes > 0) {
                                timeAgoText1 =
                                    '${timeDifference1.inMinutes} min ago';
                              } else {
                                timeAgoText1 = 'Just now';
                              }
                              final profilePic = _firestore
                                  .collection('users')
                                  .doc(receiverData['donorId'])
                                  .get();

                              return FutureBuilder(
                                future: profilePic,
                                builder: (BuildContext context,
                                    AsyncSnapshot<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>
                                        snapshot) {
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
                                  final profileData = snapshot.data!.data();
                                  final profilePic = profileData?['profilepic'];
                                  return NotificationCard(
                                    username: receiverData['donorname'],
                                    message: receiverData['message'],
                                    userimage: profilePic,
                                    isDonor: false,
                                    isReceiver: isReceiver,
                                    ncount: receiverData['ncount'] ?? '0',
                                    time: timeAgoText1,
                                    foodIds: receiverData['foodId'],
                                    receiverId: receiverData['receiverId'],
                                    donorId: receiverData['donorId'],
                                    onOk: () {
                                      final String foodId =
                                          receiverData['foodId'] as String;
                                      _firestore
                                          .collection('notiforreceiver')
                                          .where('foodId', isEqualTo: foodId)
                                          .get()
                                          .then((querySnapshot) {
                                        if (querySnapshot.docs.isNotEmpty) {
                                          final documentReference =
                                              querySnapshot
                                                  .docs.first.reference;

                                          documentReference.delete().then((_) {
                                            print(
                                                'Notification document deleted successfully.');
                                          }).catchError((error) {
                                            print(
                                                'Error deleting notification document: $error');
                                          });
                                        } else {
                                          print(
                                              'Notification document with foodId not found.');
                                        }
                                      }).catchError((error) {
                                        print(
                                            'Error querying notification documents: $error');
                                      });
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (ctx) => HomePage(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          return Center(
                            child: Text("No Notifications"),
                          );
                        }
                      },
                    );
                  },
                );
              },
            );
          } else {
            return Center(
              child: Text('Please log in to view notifications.'),
            );
          }
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String username;
  final String message;
  final String userimage;
  final bool isDonor;
  final bool isReceiver;
  final String ncount;
  final String time;
  final String foodIds;
  final String donorId;
  final String receiverId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onOk;
  final VoidCallback? ondelete;
  final VoidCallback? ondelete1;

  NotificationCard({
    required this.username,
    required this.message,
    required this.userimage,
    required this.isDonor,
    required this.isReceiver,
    required this.ncount,
    required this.time,
    required this.foodIds,
    required this.donorId,
    required this.receiverId,
    this.onAccept,
    this.onReject,
    this.onOk,
    this.ondelete,
    this.ondelete1,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetails2(
              donor: isDonor,
              receiver: isReceiver,
              foodId: foodIds,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 202, 202, 202).withOpacity(0.2),
              spreadRadius: 0.1,
              blurRadius: 0.5,
              offset: Offset(0, 0.5),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipOval(
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
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (donorId == user?.uid) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Profilereceiver(
                                        donorId: donorId,
                                        receiverId: receiverId,
                                        foodid: foodIds,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                username,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                              ),
                            ),
                            Text(
                              message,
                              style: TextStyle(fontSize: 14),
                              softWrap: true,
                            ),
                            SizedBox(height: 4),
                            Text(
                              time,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        alignment: Alignment.topRight,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                topRight: Radius.circular(20.0),
                              ),
                            ),
                            builder: (BuildContext sheetContext) {
                              return Container(
                                height: 110,
                                color: Color.fromARGB(255, 255, 255, 255),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 5,
                                        color: Colors.grey[400],
                                        margin: EdgeInsets.only(
                                            bottom: 18.0, top: 8.0),
                                      ),
                                      if (isDonor && isReceiver)
                                        GestureDetector(
                                          onTap: () {
                                            if (ondelete1 != null) {
                                              ondelete1!();
                                            }
                                            
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20.0,
                                                  ),
                                                  Text(
                                                    'Remove Notification',
                                                    style: TextStyle(
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 0, 0, 0),
                                                      fontSize: 20.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (isDonor)
                                        GestureDetector(
                                          onTap: () {
                                            if (ondelete != null) {
                                              ondelete!();
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20.0,
                                                  ),
                                                  Text(
                                                    'Remove Notification',
                                                    style: TextStyle(
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 0, 0, 0),
                                                      fontSize: 20.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (isReceiver)
                                        GestureDetector(
                                          onTap: () {
                                            if (onOk != null) {
                                              onOk!();
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20.0,
                                                  ),
                                                  Text(
                                                    'Remove Notification',
                                                    style: TextStyle(
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 0, 0, 0),
                                                      fontSize: 20.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
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
