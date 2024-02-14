import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sparebusket/models/food.dart';
import 'package:sparebusket/models/foodtile.dart';
import 'package:sparebusket/screens/fooddetails.dart';

class PendingReciever extends StatefulWidget {
  const PendingReciever({super.key});

  @override
  State<PendingReciever> createState() => _PendingRecieverState();
}

class _PendingRecieverState extends State<PendingReciever> {
  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('foodposts');
  final CollectionReference foodCollection1 =
      FirebaseFirestore.instance.collection('foodrequests');
  final user = FirebaseAuth.instance.currentUser;
  late List<Food> foodMenu = [];

  @override
  void initState() {
    super.initState();
    startShimmerTimer();

    if (user != null) {
      fetchFoodData();
    } else {
      print('User is not logged in');
    }
  }

  Future<void> fetchFoodData() async {
    try {
      final querySnapshot1 =
          await foodCollection1.where('receiverId', isEqualTo: user?.uid).get();

      final foodIds = querySnapshot1.docs.map((doc) => doc['foodId']).toList();

      final querySnapshot = await foodCollection
          .where(FieldPath.documentId, whereIn: foodIds)
          .where('deliverycompleted', isEqualTo: 0)
          .get();
      setState(() {
        foodMenu = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final storedTimeString = data['time'] as String;

          final storedTime = DateTime.parse(storedTimeString);

          final currentTime = DateTime.now();
          final timeDifference = currentTime.difference(storedTime);

          String timeAgoText = '';

          if (timeDifference.inDays > 0) {
            timeAgoText = DateFormat.yMMMd().format(storedTime);
          } else if (timeDifference.inHours > 0) {
            timeAgoText = '${timeDifference.inHours} hr ago';
          } else if (timeDifference.inMinutes > 0) {
            timeAgoText = '${timeDifference.inMinutes} min ago';
          } else {
            timeAgoText = 'Just now';
          }
          return Food(
            name: data['title'] ?? '',
            imagepath: data['foodImageURL'] ?? '',
            donatorName: data['donorname'] ?? '',
            donorId: data['donorId'],
            donatorimagepath: data['donatorimagepath'],
            description: data['description'] ?? '',
            pickuptime: data['pickuptime'] ?? '',
            pickuplocation: data['pickuplocation'] ?? '',
            foodpostid: doc.id,
            type: data['item'] ?? '',
            time: timeAgoText,
          );
        }).toList();
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void navigateToFoodaDetails(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetails(
          food: foodMenu[index],
        ),
      ),
    );
  }

  bool shimmer = false;
  Future<void> _refresh() {
    setState(() {
      shimmer = true;
    });
    return Future.delayed(Duration(seconds: 1)).then((value) {
      setState(() {
        shimmer = false;
        fetchFoodData();
      });
    });
  }

  void startShimmerTimer() {
    setState(() {
      shimmer = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        shimmer = false;
        fetchFoodData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        body: LiquidPullToRefresh(
          onRefresh: _refresh,
          color: Colors.deepPurple,
          height: 200,
          backgroundColor: Colors.deepPurple[200],
          animSpeedFactor: 3,
          showChildOpacityTransition: false,
          child: shimmer
              ? Shimmer.fromColors(
                  baseColor: const Color.fromARGB(255, 219, 219, 219),
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 25,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Center(
                          child: Text(
                            "Requested Food list",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: foodMenu.length,
                          itemBuilder: (context, index) => FoodTile(
                            food: foodMenu[index],
                            onTap: () => navigateToFoodaDetails(index),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 25,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Center(
                        child: Text(
                          "Requested Food list",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: foodMenu.length,
                        itemBuilder: (context, index) => FoodTile(
                          food: foodMenu[index],
                          onTap: () => navigateToFoodaDetails(index),
                        ),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
