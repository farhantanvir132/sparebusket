import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/screens/homepage.dart';
import 'package:sparebusket/screens/profile.dart';
import 'package:sparebusket/screens/profilepage.dart';

class RatingView extends StatefulWidget {
  const RatingView({
    Key? key,
    required this.userId,
    required this.foodId,
    required this.userName,
    required this.raterId,
  }) : super(key: key);

  final String userId;
  final String foodId;
  final String userName;
  final String raterId;

  @override
  State<RatingView> createState() => _RatingViewState();
}

class _RatingViewState extends State<RatingView> {
  final _ratingPageController = PageController();
  var starPosition = 200.0;
  var rating = 0;
  var selectedChipindex = -1;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            height: max(260, MediaQuery.of(context).size.height * 0.3),
            child: PageView(
              controller: _ratingPageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildthanksNote(),
                _causeofRating(),
              ],
            ),
          ),
          Positioned(
            right: 0,
            child: MaterialButton(
              onPressed: hideDialog,
              child: const Text("Skip"),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          AnimatedPositioned(
            top: starPosition,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () {
                    _ratingPageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                    WidgetsBinding.instance?.addPostFrameCallback((_) {
                      setState(() {
                        starPosition = 30;
                        rating = index + 1;
                      });
                    });
                  },
                  icon: index < rating
                      ? Icon(
                          Icons.star,
                          size: 32,
                        )
                      : Icon(
                          Icons.star_border,
                          size: 32,
                        ),
                  color: Color.fromARGB(255, 60, 17, 255),
                ),
              ),
            ),
            duration: Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  _buildthanksNote() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Thanks for using Our Application",
            style: TextStyle(
                fontSize: 24,
                color: Color.fromARGB(255, 60, 17, 255),
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            "We\'d love to get your feedbaack",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            "How was your Experience with " + widget.userName + "?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  _causeofRating() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 45,
                ),
                Text(
                  "You have Rated $rating Stars",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  "Thanks for your Feedback. It helps us to improve our service",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 16,
                ),
                MaterialButton(
                  minWidth: 240,
                  height: 45,
                  onPressed: hideDialog1,
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  textColor: Colors.white,
                  color: Color.fromARGB(255, 116, 65, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  hideDialog1() async {
    if (Navigator.canPop(context)) {
      // Navigator.pop(context);
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      Map<String, dynamic> ratingData = {
        'userId': widget.userId,
        'foodId': widget.foodId,
        'userName': widget.userName,
        'raterId': widget.raterId,
        'rating': rating,
      };

      try {
        await firestore.collection('ratings').add(ratingData);
        print('Rating added successfully to Firestore!');
      } catch (e) {
        print('Error adding rating to Firestore: $e');
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
  }

  hideDialog() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
