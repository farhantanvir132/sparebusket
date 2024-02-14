import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/models/food.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparebusket/models/foodrequest.dart';
import 'package:sparebusket/models/notifi.dart';
import 'dart:core';
import 'package:intl/intl.dart';
import 'package:sparebusket/screens/homepage.dart';
import 'package:sparebusket/screens/profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class FoodDetails2 extends StatefulWidget {
  final String foodId;
  final bool receiver;
  final bool donor;
  const FoodDetails2({
    Key? key,
    required this.foodId,
    required this.receiver,
    required this.donor,
  }) : super(key: key);

  @override
  State<FoodDetails2> createState() => _FoodDetailsState2();
}

void requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}

Future<void> sendNotificationToReceiver(
    String receiverFCMToken, title, body) async {
  try {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAASGgo7dw:APA91bHkmOzxWdMFkjGTMPGy_0CwrWie4apJE08mg6XdWzE8nhSlkJbfBsWKHqr3WcDy3l1Ie8b8MQL_Uu6_ZBgv-SS0dXdlcXHVAenJORe2A6STfz1OFbQE8112IHOnN0WqIqvCJk_F',
      },
      body: jsonEncode(
        <String, dynamic>{
          'priority': 'high',
          'notification': {
            'title': title,
            'body': body,
            'android_channel_id': 'foodapp',
          },
          'to': receiverFCMToken,
        },
      ),
    );
    print('Notification sent successfully to receiver.');
  } catch (e) {
    print('Error sending notification to receiver: $e');
  }
}

void configureFirebaseMessaging() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        'Received a message in the foreground: ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
  });
}

class _FoodDetailsState2 extends State<FoodDetails2> {
  String donatorimagepath = "";
  String description = "";
  String donorId = "";
  String foodImageURL = "";
  String item = "";
  String pickuplocation = "";
  String pickuptime = "";
  String title = "";
  String donorname = "";
  String rating = "";
  bool isLoading = true;
  double averageRating = 0.0;
  String avgRating = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _user;
  Future<void> fetchFoodDetails() async {
    try {
      final DocumentSnapshot foodDocument =
          await _firestore.collection('foodposts').doc(widget.foodId).get();
      if (foodDocument.exists) {
        final Map<String, dynamic> data =
            foodDocument.data() as Map<String, dynamic>;
        print(data);
        setState(() {
          donatorimagepath = data['donatorimagepath'];
          description = data['description'];
          donorId = data['donorId'];
          foodImageURL = data['foodImageURL'];
          item = data['item'];
          pickuplocation = data['pickuplocation'];
          pickuptime = data['pickuptime'];
          title = data['title'];
          donorname = data['donorname'];
          isLoading = false;
        });
      } else {}
    } catch (e) {
      print('Error fetching food details: $e');
      print(widget.foodId);
    }
  }

  get http => null;
  Future<void> fetchAverageRating() async {
    String donorID = "";
    final DocumentSnapshot foodDocument =
        await _firestore.collection('foodposts').doc(widget.foodId).get();
    if (foodDocument.exists) {
      final Map<String, dynamic> data =
          foodDocument.data() as Map<String, dynamic>;
      donorID = data['donorId'];
    }
    CollectionReference donorRatingsCollection =
        FirebaseFirestore.instance.collection('ratings');

    QuerySnapshot donorRatingsSnapshot =
        await donorRatingsCollection.where('userId', isEqualTo: donorID).get();

    if (donorRatingsSnapshot.docs.isNotEmpty) {
      List<int> ratings =
          donorRatingsSnapshot.docs.map((doc) => doc['rating'] as int).toList();

      double totalRating =
          ratings.fold(0, (previous, current) => previous + current);
      averageRating = totalRating / ratings.length;

      setState(() {
        averageRating = double.parse(averageRating.toStringAsFixed(1));
        avgRating = averageRating.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getUser();
    fetchFoodDetails();
    requestPermission();
    configureFirebaseMessaging();
    fetchAverageRating();
  }

  Future<void> _getUser() async {
    _user = _auth.currentUser;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey[800],
        title: Text(
          "Food Details",
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: CircleAvatar(
                            maxRadius: 150,
                            backgroundImage: NetworkImage(foodImageURL),
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                        userId: donorId,
                                        foodId: widget.foodId,
                                        donorName: donorname)));
                              },
                              child: ClipOval(
                                child: donatorimagepath != ""
                                    ? Image.network(
                                        donatorimagepath,
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'lib/images/profile.png',
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons.star,
                              color: Colors.yellow[800],
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              avgRating,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Text(
                          "Description",
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 2,
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        Text(
                          "PickUp Time : ",
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        Text(
                          pickuptime,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            height: 2,
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        Text(
                          "PickUp Location : ",
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pickuplocation,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                height: 2,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                String location = pickuplocation;
                                final Uri url = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=$location');
                                launchUrl(url);
                              },
                              icon: const Icon(Icons.location_on),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 35,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('foodposts')
                          .doc(widget.foodId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text("Food post does not exist");
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final userId = data['donorId'];
                        final dstatus = data['deliverystatus'];
                        final dcom = data['deliverycompleted'];

                        final foodID = widget.foodId;
                        int status = 0;
                        String receiverNames = '';
                        String receiverID = "";

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('foodrequests')
                              .where('foodId', isEqualTo: widget.foodId)
                              .snapshots(),
                          builder: (context, requestSnapshot) {
                            if (requestSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            if (requestSnapshot.hasData &&
                                requestSnapshot.data!.docs.isNotEmpty) {
                              QueryDocumentSnapshot doc =
                                  requestSnapshot.data!.docs[0];
                              status = doc['status'];
                              receiverNames = doc['receivername'];
                              receiverID = doc['receiverId'];
                            }

                            bool isSameUser = _user?.uid == userId;
                            void handledonorpost(BuildContext context) async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('foodposts')
                                    .doc(foodID)
                                    .delete();
                              } catch (error) {
                                print("Error: $error");
                              }
                            }

                            return Column(
                              children: [
                                if (isSameUser &&
                                    status == 0 &&
                                    dstatus == 0 &&
                                    dcom == 0)
                                  ElevatedButton(
                                    onPressed: () {
                                      handledonorpost(context);
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (ctx) => HomePage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      minimumSize: Size(200, 50),
                                    ),
                                    child: Text(
                                      'Delete Food Post',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isSameUser &&
                                    status == 1 &&
                                    dstatus == 0 &&
                                    dcom == 0)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$receiverNames has requested for this food item',
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5.0),
                                      ElevatedButton(
                                        onPressed: () async {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Row(
                                                children: <Widget>[
                                                  CircularProgressIndicator(),
                                                  SizedBox(width: 20),
                                                  Text("Confirming..."),
                                                ],
                                              ),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                          QuerySnapshot foodRequestsQuery =
                                              await FirebaseFirestore.instance
                                                  .collection('foodrequests')
                                                  .where('foodId',
                                                      isEqualTo: widget.foodId)
                                                  .limit(1)
                                                  .get();

                                          if (foodRequestsQuery
                                              .docs.isNotEmpty) {
                                            DocumentSnapshot foodRequestDoc =
                                                foodRequestsQuery.docs.first;

                                            String receiverIDs =
                                                foodRequestDoc['receiverId'];
                                            String receivernam =
                                                foodRequestDoc['receivername'];
                                            String donorNames =
                                                foodRequestDoc['donorname'];
                                            DocumentSnapshot userSnapshot =
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(receiverIDs)
                                                    .get();

                                            if (userSnapshot.exists) {
                                              String receiverFCMToken =
                                                  userSnapshot['fcmToken'];
                                              String title = "SpareBusket";

                                              String body =
                                                  "$donorNames has just confirmed Delivery.Ensure you got the food!!";
                                              sendNotificationToReceiver(
                                                  receiverFCMToken,
                                                  title,
                                                  body);
                                            }
                                            final notifi = Notifi(
                                              donorname: data['donorname'],
                                              donorId: userId,
                                              receivername: receivernam,
                                              receiverId: receiverIDs,
                                              foodtitle: data['title'],
                                              message:
                                                  "has just confirmed Delivery.Ensure you got the food",
                                              foodId: widget.foodId,
                                              ncount: '!',
                                              time: formattedTime,
                                            );

                                            await FirebaseFirestore.instance
                                                .collection('notiforreceiver')
                                                .add(notifi.toMap());
                                          }
                                          _firestore
                                              .collection('foodposts')
                                              .doc(widget.foodId)
                                              .update({
                                            'deliverystatus': 1,
                                          }).then((_) {
                                            print(
                                                'Status updated successfully.');
                                          }).catchError((error) {
                                            print(
                                                'Error updating status: $error');
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Waiting for Receiver Confirmation"),
                                            ),
                                          );
                                          // ignore: use_build_context_synchronously
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //       builder: (context) => HomePage()),
                                          // );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Color.fromARGB(255, 5, 88, 211),
                                          minimumSize: Size(200, 50),
                                        ),
                                        child: Text(
                                          'Confirm Delivery',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (isSameUser &&
                                    status == 1 &&
                                    dstatus == 1 &&
                                    dcom == 0)
                                  Center(
                                    child: Text(
                                      'Waiting for Receiver Confirmation...',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isSameUser &&
                                    status == 1 &&
                                    dstatus == 1 &&
                                    dcom == 1)
                                  Center(
                                    child: Text(
                                      'Delivered to ' +
                                          receiverNames +
                                          ' Successfully',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('foodrequests')
                                      .where('foodId', isEqualTo: widget.foodId)
                                      .snapshots(),
                                  builder: (context, requestSnapshot) {
                                    if (requestSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }

                                    bool is_exist = false;

                                    if (requestSnapshot.hasData) {
                                      for (QueryDocumentSnapshot doc
                                          in requestSnapshot.data!.docs) {
                                        if (doc['foodId'] == widget.foodId) {
                                          is_exist = true;
                                          break;
                                        }
                                      }
                                    }

                                    bool isSameUserAsReceiver =
                                        requestSnapshot.data?.docs.any((doc) =>
                                                _user?.uid ==
                                                doc['receiverId']) ??
                                            false;

                                    return Column(
                                      children: [
                                        if (isSameUserAsReceiver &&
                                            dstatus == 1 &&
                                            status == 1 &&
                                            dcom == 0)
                                          ElevatedButton(
                                            onPressed: () async {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Row(
                                                    children: <Widget>[
                                                      CircularProgressIndicator(),
                                                      SizedBox(width: 20),
                                                      Text("Confirming..."),
                                                    ],
                                                  ),
                                                  duration:
                                                      Duration(seconds: 3),
                                                ),
                                              );
                                              QuerySnapshot foodRequestsQuery =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'foodrequests')
                                                      .where('foodId',
                                                          isEqualTo:
                                                              widget.foodId)
                                                      .get();

                                              if (foodRequestsQuery
                                                  .docs.isNotEmpty) {
                                                DocumentSnapshot
                                                    foodRequestDoc =
                                                    foodRequestsQuery
                                                        .docs.first;

                                                String receivernm =
                                                    foodRequestDoc[
                                                        'receivername'];
                                                DocumentSnapshot userSnapshot =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .doc(userId)
                                                        .get();

                                                if (userSnapshot.exists) {
                                                  String receiverFCMToken =
                                                      userSnapshot['fcmToken'];
                                                  String title = "SpareBusket";

                                                  String body =
                                                      "$receivernm has received your food successfully!";
                                                  sendNotificationToReceiver(
                                                      receiverFCMToken,
                                                      title,
                                                      body);
                                                }
                                                final notifi = Notifi(
                                                  donorname: data['donorname'],
                                                  donorId: userId,
                                                  receivername: receivernm,
                                                  receiverId: _user!.uid,
                                                  foodtitle: data['title'],
                                                  message:
                                                      "has received the food sucessfully",
                                                  foodId: widget.foodId,
                                                  ncount: '!',
                                                  time: formattedTime,
                                                );

                                                await FirebaseFirestore.instance
                                                    .collection('notifications')
                                                    .add(notifi.toMap());
                                              }

                                              _firestore
                                                  .collection('foodposts')
                                                  .doc(widget.foodId)
                                                  .update({
                                                'deliverycompleted': 1,
                                              }).then((_) {
                                                print(
                                                    'Status updated successfully.');
                                              }).catchError((error) {
                                                print(
                                                    'Error updating status: $error');
                                              });
                                              // ignore: use_build_context_synchronously

                                              ScaffoldMessenger.of(context)
                                                  .removeCurrentSnackBar();

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "Food Received Successfully."),
                                                ),
                                              );
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(userId)
                                                  .update({
                                                'donated':
                                                    FieldValue.increment(1),
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(_user!.uid)
                                                  .update({
                                                'received':
                                                    FieldValue.increment(1),
                                              });
                                              // Navigator.push(
                                              //   context,
                                              //   MaterialPageRoute(
                                              //       builder: (context) =>
                                              //           HomePage()),
                                              // );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              minimumSize: Size(200, 50),
                                            ),
                                            child: Text(
                                              'Confirm Receiving',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (isSameUserAsReceiver &&
                                            dstatus == 1 &&
                                            dcom == 1)
                                          ElevatedButton(
                                            onPressed: null,
                                            child: Text(
                                              "Received Succesfully",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
