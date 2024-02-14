import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:popover/popover.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sparebusket/models/rating_view.dart';
import 'package:sparebusket/screens/homepage.dart';
import 'package:sparebusket/screens/message.dart';
import 'package:url_launcher/url_launcher.dart';

class Profilereceiver extends StatefulWidget {
  const Profilereceiver({
    Key? key,
    required this.donorId,
    required this.receiverId,
    required this.foodid,
  }) : super(key: key);
  final String donorId;
  final String receiverId;
  final String foodid;

  @override
  _ProfilereceiverState createState() => _ProfilereceiverState();
}

class _ProfilereceiverState extends State<Profilereceiver> {
  double averageRating = 0.0;
  String avgRating = "";
  String Proimage = "";
  String name = "";
  String phone = "";
  String Email = "";
  String donorname = "";
  late int numOfdonation;
  late int numOfReceived;
  bool alreadyrated = false;
  Future<void> fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        name =
            (userData['firstname'] ?? '') + ' ' + (userData['lastname'] ?? '');
        phone = userData['phone'] ?? '';
        Email = userData['email'] ?? '';
        Proimage = userData['profilepic'];
        numOfdonation = userData['donated'];
        numOfReceived = userData['received'];
      });
    }
  }

  Future<void> fetchAverageRating() async {
    CollectionReference receiverRatingsCollection =
        FirebaseFirestore.instance.collection('ratings');

    QuerySnapshot receiverRatingsSnapshot = await receiverRatingsCollection
        .where('userId', isEqualTo: widget.receiverId)
        .get();

    if (receiverRatingsSnapshot.docs.isNotEmpty) {
      List<int> ratings = receiverRatingsSnapshot.docs
          .map((doc) => doc['rating'] as int)
          .toList();

      double totalRating =
          ratings.fold(0, (previous, current) => previous + current);
      averageRating = totalRating / ratings.length;

      setState(() {
        averageRating = double.parse(averageRating.toStringAsFixed(1));
        avgRating = averageRating.toString();
      });
    }
  }

  void _launchPhoneDialer(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    await launchUrl(url);
  }

  @override
  void initState() {
    super.initState();
    startShimmerTimer();
    fetchUserData();
    checkUser();
    fetchAverageRating();
    checkUserstatus();
  }

  bool shimmer = false;
  Future<void> _refresh() {
    setState(() {
      shimmer = true;
    });
    return Future.delayed(Duration(seconds: 1)).then((value) {
      setState(() {
        fetchUserData();
        shimmer = false;
      });
    });
  }

  void startShimmerTimer() {
    setState(() {
      shimmer = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        fetchUserData();
        shimmer = false;
      });
    });
  }

  bool showReportSection = false;
  bool showMessageButton = true;
  void checkUser() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user?.uid == widget.receiverId) {
      setState(() {
        showMessageButton = false;
      });
    } else {
      showMessageButton = true;
    }
  }

  TextEditingController reportController = TextEditingController();

  void toggleReportSection() {
    setState(() {
      showReportSection = !showReportSection;
    });
  }

  Future<void> submitReport() async {
    if (reportController.text.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          donorname = (userData['firstname'] ?? '') +
              ' ' +
              (userData['lastname'] ?? '');
        });
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      Map<String, dynamic> reportData = {
        'donorId': user?.uid,
        'donorName': donorname,
        'receiverId': widget.receiverId,
        'receiverName': name,
        'foodId': widget.foodid,
        'reportText': reportController.text,
      };

      CollectionReference reportsCollection =
          firestore.collection('receiverreports');

      await reportsCollection.add(reportData).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            toggleReportSection();
            reportController.clear();
          });
        });
      }).catchError((error) {
        print('Error submitting report: $error');
      });
    }
  }

  Future<void> checkUserstatus() async {
    CollectionReference donorRatingsCollection =
        FirebaseFirestore.instance.collection('ratings');
    QuerySnapshot donorRatingsSnapshot = await donorRatingsCollection
        .where('raterId', isEqualTo: user?.uid)
        .where('foodId', isEqualTo: widget.foodid)
        .get();
    if (donorRatingsSnapshot.docs.isNotEmpty) {
      setState(() {
        alreadyrated = true;
      });
    } else {
      alreadyrated = false;
    }
  }

  Future<bool> checkPermissionToFlag() async {
    User? user = FirebaseAuth.instance.currentUser;

    CollectionReference foodRequestsCollection =
        FirebaseFirestore.instance.collection('foodrequests');

    QuerySnapshot foodRequestsSnapshot = await foodRequestsCollection
        .where('foodId', isEqualTo: widget.foodid)
        .where('donorId', isEqualTo: user?.uid)
        .get();

    return foodRequestsSnapshot.docs.isNotEmpty;
  }

  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 130, 80, 218),
        elevation: 0,
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          FutureBuilder<bool>(
            future: checkPermissionToFlag(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == true) {
                  return IconButton(
                    icon: const Icon(Icons.flag),
                    onPressed: () {
                      toggleReportSection();
                      reportController.clear();
                    },
                  );
                }
              }
              return const SizedBox();
            },
          ),
          if (user!.uid != widget.receiverId && alreadyrated == false)
            GestureDetector(
              onTap: () {
                openRatingDialog(context);
              },
              child: Image.asset(
                'lib/images/rate.png',
                width: 35,
                height: 15,
              ),
            ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
          child: shimmer
              ? Shimmer.fromColors(
                  baseColor: const Color.fromARGB(255, 219, 219, 219),
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 160,
                              height: 160,
                              child: Proimage != ""
                                  ? Image.network(
                                      Proimage,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'lib/images/profile.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    " ",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    Email,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    " ",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    " ",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  InkWell(
                                    onTap: () => _launchPhoneDialer(phone),
                                    child: const Text(
                                      "",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 160,
                            height: 160,
                            child: Proimage != ""
                                ? Image.network(
                                    Proimage,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'lib/images/profile.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Icons.star,
                          size: 25,
                          color: Colors.yellow[800],
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          avgRating,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Email : ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Email,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Name : ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Number of Item Donated: ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  numOfdonation.toString(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Number of Item Received: ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  numOfReceived.toString(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => _launchPhoneDialer(phone),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 24,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 30),
                                      showMessageButton
                                          ? GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          MessageScreen(
                                                            userId: widget
                                                                .receiverId,
                                                            username: name,
                                                          )),
                                                );
                                              },
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.message,
                                                    size: 24,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    ' Message',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : SizedBox(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    showReportSection
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: TextField(
                                  controller: reportController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your report...',
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 35.0),
                                    prefixIcon: Icon(Icons.text_fields),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 40,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    child: ElevatedButton(
                                      onPressed: submitReport,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Color.fromARGB(255, 130, 80, 218),
                                        ),
                                      ),
                                      child: Text(
                                        'Submit',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Container(
                                    width: 120,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        toggleReportSection();
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Colors.red,
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          )
                        : const SizedBox(),
                  ],
                ),
        ),
      ),
    );
  }

  openRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final User? user = FirebaseAuth.instance.currentUser;
        return Dialog(
          child: RatingView(
            userId: widget.receiverId,
            foodId: widget.foodid,
            userName: name,
            raterId: user!.uid,
          ),
        );
      },
    );
  }
}
