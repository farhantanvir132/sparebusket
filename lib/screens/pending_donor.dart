import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sparebusket/models/food.dart';
import 'package:sparebusket/models/foodtile.dart';
import 'package:sparebusket/screens/fooddetails.dart';

class PendingDonor extends StatefulWidget {
  const PendingDonor({super.key});

  @override
  State<PendingDonor> createState() => _PendingDonorState();
}

class _PendingDonorState extends State<PendingDonor> {
  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('foodposts');

  late List<Food> foodMenu = [];

  @override
  void initState() {
    super.initState();
    startShimmerTimer();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      fetchFoodData(userId);
    } else {
      print('User is not logged in');
    }
  }

  Future<void> fetchFoodData(String userId) async {
    try {
      final querySnapshot = await foodCollection
          .where('donorId', isEqualTo: userId)
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
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
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
                            "Foods To be Donated",
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
                          "Foods To be Donated",
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
