import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sparebusket/models/food.dart';
import 'package:sparebusket/models/foodtile.dart';
import 'package:sparebusket/screens/fooddetails.dart';
import 'package:string_similarity/string_similarity.dart';

class SearchPageWithTabs extends StatefulWidget {
  final String searchText;
  final TextEditingController searchController;
  const SearchPageWithTabs(
      {super.key, required this.searchText, required this.searchController});
  @override
  State<SearchPageWithTabs> createState() => _SearchPageWithTabsState();
}

class _SearchPageWithTabsState extends State<SearchPageWithTabs> {
  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('foodposts');

  late List<Food> foodMenu = [];

  @override
  void initState() {
    super.initState();

    fetchFoodData();
  }

  Future<void> fetchFoodData() async {
    try {
      final querySnapshot =
          await foodCollection.where('deliverycompleted', isEqualTo: 0).get();

      final searchTextLowerCase = widget.searchText.toLowerCase();
      print(searchTextLowerCase);
      print(widget.searchText);
      final filteredDocs = querySnapshot.docs.where((doc) {
        final pickupLocation = doc['pickuplocation'] as String;
        final pickupLocationLower = pickupLocation.toLowerCase();

        final similarity =
            pickupLocationLower.similarityTo(searchTextLowerCase);
        final threshold = 0.5;

        print(
            'Doc ID: ${doc.id}, Pickup Location: $pickupLocation, Similarity: $similarity');

        return similarity >= threshold;
      }).toList();
      setState(() {
        foodMenu = filteredDocs.map((doc) {
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
            donatorimagepath: data['donatorimagepath'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
            widget.searchController.clear();
          },
        ),
        title: const Text('Search Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: const Text(
                "Search Results....",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: foodMenu.length,
                itemBuilder: (context, index) => FoodTile(
                  food: foodMenu[index],
                  onTap: () => navigateToFoodaDetails(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
