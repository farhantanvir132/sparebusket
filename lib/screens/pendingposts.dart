import "package:cloud_firestore/cloud_firestore.dart";
import "package:curved_navigation_bar/curved_navigation_bar.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart";
import "package:shimmer/shimmer.dart";
import "package:sparebusket/models/food.dart";
import "package:sparebusket/models/foodtile.dart";
import "package:sparebusket/screens/fooddetails.dart";
import "package:sparebusket/screens/foodpost.dart";
import "package:sparebusket/screens/homepage.dart";
import "package:sparebusket/screens/login.dart";
import "package:sparebusket/screens/message.dart";
import "package:sparebusket/screens/pending_donor.dart";
import "package:sparebusket/screens/pending_recieve.dart";
import "package:sparebusket/screens/profile.dart";
import "package:sparebusket/screens/splashscreen.dart";

class PendingPage extends StatefulWidget {
  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Color.fromARGB(255, 130, 80, 218),
            elevation: 0,
            title: Text("Pending Posts"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => HomePage(),
                  ),
                );
              },
            ),
          ),
          body: const Column(
            children: [
              TabBar(
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.takeout_dining,
                      color: Colors.black,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.receipt,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    PendingDonor(),
                    PendingReciever(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
