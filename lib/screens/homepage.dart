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
import "package:sparebusket/screens/changepass.dart";
import "package:sparebusket/screens/displaymsg.dart";
import "package:sparebusket/screens/donatedfood.dart";
import "package:sparebusket/screens/pendingposts.dart";
import "package:sparebusket/screens/profilepage.dart";
import "package:sparebusket/screens/receivedfood.dart";
import "package:sparebusket/screens/fooddetails.dart";
import "package:sparebusket/screens/foodpost.dart";
import "package:sparebusket/screens/login.dart";
import "package:sparebusket/screens/message.dart";
import "package:sparebusket/screens/notification.dart";

import "package:sparebusket/screens/profile.dart";
import "package:sparebusket/screens/report.dart";
import "package:sparebusket/screens/searchpage.dart";
import "package:sparebusket/screens/splashscreen.dart";
import "package:sparebusket/screens/userBanned.dart";

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchController = TextEditingController();
  late String name = "";
  late String email = "";
  late String urlImage = "";
  final List<String> types = [
    "Raw Food",
    "Drink",
    "Rice",
    "Home Cooked",
    "Mixed",
  ];
  List<String> selectedTypes = [];
  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('foodposts');

  late List<Food> foodMenu = [];

  @override
  void initState() {
    super.initState();
    UserStatus();
    startShimmerTimer();
    fetchFoodData();
    getUserData();
    deleteExpiredFoodPosts();
  }

  Future<void> UserStatus() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String userId = user.uid;

      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      try {
        DocumentSnapshot userSnapshot = await userDoc.get();

        if (userSnapshot.exists && userSnapshot['ban'] == true) {
          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BannedPage()),
            );
          });
        } else {}
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {}
  }

  Future<void> deleteExpiredFoodPosts() async {
    final currentTime = DateTime.now();
    final foodPosts =
        await foodCollection.where('deliverycompleted', isEqualTo: 0).get();
    for (final foodPost in foodPosts.docs) {
      final data = foodPost.data() as Map<String, dynamic>;
      final storedTimeString = data['time'] as String;
      final storedTime = DateTime.parse(storedTimeString);
      final availableTimeString = data['availableTime'] as String;
      final availableTime = int.tryParse(availableTimeString) ?? 0;
      final thresholdDuration = Duration(hours: availableTime);

      if (currentTime.difference(storedTime) >= thresholdDuration) {
        try {
          await foodCollection.doc(foodPost.id).delete();
          final foodPostId = foodPost.id;
          final foodRequestDocs = await FirebaseFirestore.instance
              .collection('foodrequests')
              .where('foodId', isEqualTo: foodPostId)
              .get();

          for (final foodRequestDoc in foodRequestDocs.docs) {
            final foodRequestId = foodRequestDoc.id;
            await FirebaseFirestore.instance
                .collection('foodrequests')
                .doc(foodRequestId)
                .delete();
          }
        } catch (e) {
          print('Error deleting food post: $e');
        }
      }
    }
  }

  Future<void> getUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String userId = user.uid;

      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      try {
        DocumentSnapshot userSnapshot = await userDoc.get();

        if (userSnapshot.exists) {
          setState(() {
            name = userSnapshot['firstname'];
            email = user.email!;
            urlImage = userSnapshot['profilepic'];
          });
        } else {}
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {}
  }

  Future<void> fetchFoodData() async {
    try {
      final querySnapshot = await foodCollection
          .where('deliverycompleted', isEqualTo: 0)
          .orderBy('time', descending: true)
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

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
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

  final padding = const EdgeInsets.symmetric(horizontal: 20);

  bool shimmer = false;
  Future<void> _refresh() {
    setState(() {
      shimmer = true;
    });
    return Future.delayed(Duration(seconds: 1)).then((value) {
      setState(() {
        fetchFoodData();
        shimmer = false;
      });
    });
  }

  void startShimmerTimer() {
    setState(() {
      shimmer = true;
      // fetchFoodData();
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        fetchFoodData();
        shimmer = false;
      });
    });
  }

  final User? user = FirebaseAuth.instance.currentUser;
  Future<String> fetchNotificationCount() async {
    if (user != null) {
      final userId = user!.uid;

      final donorQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('donorId', isEqualTo: userId)
          .get();

      final receiverQuery = await FirebaseFirestore.instance
          .collection('notiforreceiver')
          .where('receiverId', isEqualTo: userId)
          .get();

      String notificationCount = "0";

      for (final doc in donorQuery.docs) {
        notificationCount = doc['ncount'];
        if (notificationCount == "!") {
          break;
        }
      }

      for (final doc in receiverQuery.docs) {
        notificationCount = doc['ncount'];
        if (notificationCount == "!") {
          break;
        }
      }

      return notificationCount;
    } else {
      return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterTypes = selectedTypes.isNotEmpty
        ? foodMenu.where((food) => selectedTypes.contains(food.type)).toList()
        : List.from(foodMenu);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 130, 80, 218),
        elevation: 0,
        title: Text("SpareBusket"),
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PendingPage()),
              );
            },
          ),
          IconButton(
            icon: FutureBuilder<String>(
              future: fetchNotificationCount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Icon(Icons.notifications);
                } else if (snapshot.hasError) {
                  return Icon(Icons.notifications);
                } else {
                  final notificationCount = snapshot.data;

                  if (notificationCount != null && notificationCount != "0") {
                    return Stack(
                      children: [
                        Icon(Icons.notifications),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Icon(Icons.notifications);
                  }
                }
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationApp()),
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        child: Material(
          child: Container(
              color: Color.fromARGB(255, 156, 134, 255),
              child: ListView(
                children: <Widget>[
                  buildHeader(
                    urlImage: urlImage,
                    name: name,
                    email: email,
                    onClicked: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserProfilePage(),
                    )),
                  ),
                  Container(
                    padding: padding,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        buildSearchField(),
                        const SizedBox(height: 24),
                        buildMenuItem(
                          text: 'Home',
                          icon: Icons.home,
                          onClicked: () => selectedItem(context, 0),
                        ),
                        const SizedBox(height: 16),
                        buildMenuItem(
                          text: 'Donated Food',
                          icon: Icons.takeout_dining,
                          onClicked: () => selectedItem(context, 1),
                        ),
                        const SizedBox(height: 16),
                        buildMenuItem(
                          text: 'Recieved Food',
                          icon: Icons.receipt,
                          onClicked: () => selectedItem(context, 2),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white70),
                        buildMenuItem(
                          text: 'Settings',
                          icon: Icons.receipt,
                          onClicked: () => selectedItem(context, 3),
                        ),
                        const SizedBox(height: 24),
                        buildMenuItem(
                          text: 'Log Out',
                          icon: Icons.logout,
                          onClicked: () => selectedItem(context, 4),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              )),
        ),
      ),
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
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        child: buildSearchField(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 164, 125, 255),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(""),
                              SizedBox(
                                height: 10,
                              ),
                              Text(""),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Text(
                        "",
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        margin: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: types
                              .map((type) => Container(
                                    margin:
                                        EdgeInsets.only(right: 8.0, left: 8.0),
                                    child: FilterChip(
                                      selected: selectedTypes.contains(type),
                                      label: Text(type,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: selectedTypes.contains(type)
                                                ? Colors.white
                                                : Colors.black,
                                          )),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedTypes.add(type);
                                          } else {
                                            selectedTypes.remove(type);
                                          }
                                        });
                                      },
                                      selectedColor:
                                          Color.fromARGB(255, 94, 2, 136),
                                      backgroundColor:
                                          Color.fromARGB(255, 193, 155, 255),
                                      showCheckmark: false,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Text(
                        "",
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filterTypes.length,
                        itemBuilder: (context, index) {
                          final type = filterTypes[index];
                          return FoodTile(
                            food: type,
                            onTap: () =>
                                navigateToFoodaDetails(foodMenu.indexOf(type)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        child: buildSearchField(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 175, 140, 255),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.only(
                          left: 15.0, right: 25, top: 15, bottom: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome to SpareBusket",
                                style: TextStyle(
                                  fontSize: 19,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Donate your food to the needy",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Image.asset(
                            'lib/images/foodDelivery.png',
                            height: 55,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Text(
                        "See By Catagories",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        margin: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: types
                              .map((type) => Container(
                                    margin:
                                        EdgeInsets.only(right: 8.0, left: 8.0),
                                    child: FilterChip(
                                      selected: selectedTypes.contains(type),
                                      label: Text(type,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: selectedTypes.contains(type)
                                                ? Colors.white
                                                : Colors.black,
                                          )),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedTypes.add(type);
                                          } else {
                                            selectedTypes.remove(type);
                                          }
                                        });
                                      },
                                      selectedColor:
                                          Color.fromARGB(255, 94, 2, 136),
                                      backgroundColor:
                                          Color.fromARGB(255, 193, 155, 255),
                                      showCheckmark: false,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Text(
                        "Available Foods",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filterTypes.length,
                      itemBuilder: (context, index) {
                        final type = filterTypes[index];
                        return FoodTile(
                          food: type,
                          onTap: () =>
                              navigateToFoodaDetails(foodMenu.indexOf(type)),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Color.fromARGB(255, 130, 80, 218),
        animationDuration: Duration(milliseconds: 300),
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => HomePage()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FoodPostingPage()));
              break;
            case 2:
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => msgPage()));
              break;
            case 3:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserProfilePage()));
              break;
          }
        },
        items: [
          Icon(Icons.home),
          Icon(
            Icons.add_circle_outline_rounded,
            size: 32,
          ),
          Icon(Icons.message),
          Icon(Icons.person),
        ],
      ),
    );
  }

  Widget buildMenuItem({
    required String text,
    required IconData icon,
    VoidCallback? onClicked,
  }) {
    final color = const Color.fromARGB(255, 0, 0, 0);
    final hoverColor = Colors.white70;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      hoverColor: hoverColor,
      onTap: onClicked,
    );
  }

  void selectedItem(BuildContext context, int index) {
    Navigator.of(context).pop();

    switch (index) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => HomePage(),
        ));
        break;
      case 1:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DonatePage(),
        ));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ReceivedPage(),
        ));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChangePass(),
        ));
        break;
      case 4:
        _signOut(context);

        break;
    }
  }

  Widget buildSearchField() {
    const color = Color.fromARGB(255, 0, 0, 0);

    return TextField(
      controller: searchController,
      style: const TextStyle(color: color),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        hintText: 'Search Here by Location',
        hintStyle: TextStyle(color: color),
        suffixIcon: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SearchPageWithTabs(
                  searchText: searchController.text,
                  searchController: searchController,
                ),
              ),
            );
          },
          child: Icon(Icons.search, color: color),
        ),
        filled: true,
        fillColor: Colors.white12,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget buildHeader({
    required String urlImage,
    required String name,
    required String email,
    required VoidCallback onClicked,
  }) =>
      InkWell(
        onTap: onClicked,
        child: Container(
          padding: padding.add(const EdgeInsets.symmetric(vertical: 40)),
          child: Row(
            children: [
              ClipOval(
                  child: urlImage != ""
                      ? Image.network(
                          urlImage,
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'lib/images/profile.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        )),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(width: 50),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReportPage(),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color.fromRGBO(0, 0, 0, 1),
                          child: Icon(Icons.report, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
