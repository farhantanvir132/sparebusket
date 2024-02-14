import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sparebusket/screens/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  TextEditingController phoneController = TextEditingController();

  String Email = "";
  String Proimage = "";
  String profilePicUrl = " ";
  String Name = "";
  late int numOfdonation;
  late int numOfReceived;
  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          Name = (userData['firstname'] ?? '') +
              ' ' +
              (userData['lastname'] ?? '');
          phoneController.text = userData['phone'] ?? '';
          Email = user.email ?? '';
          Proimage = userData['profilepic'];
          numOfdonation = userData['donated'];
          numOfReceived = userData['received'];
        });
      }
    }
  }

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    startShimmerTimer();
    fetchUserData();
  }

  Future<void> updateInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
      'phone': phoneController.text,
    });
  }

  String imagePath = "";

  bool shimmer = false;
  Future<void> _refresh() {
    setState(() {
      shimmer = true;
    });
    return Future.delayed(const Duration(seconds: 1)).then((value) {
      setState(() {
        shimmer = false;
        fetchUserData();
      });
    });
  }

  void startShimmerTimer() {
    setState(() {
      shimmer = true;
      // fetchFoodData();
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        shimmer = false;
        fetchUserData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 130, 80, 218),
        elevation: 0,
        title: const Center(
          child: Text('User Profile'),
        ),
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
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                updateInfo();
                isEditing = !isEditing;
              });
            },
          ),
        ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: _refresh,
        color: Colors.deepPurple,
        height: 200,
        backgroundColor: Colors.deepPurple[200],
        animSpeedFactor: 3,
        showChildOpacityTransition: false,
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
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
                              child: Container(
                                width: 160,
                                height: 160,
                                child: Proimage != ""
                                    ? Image.network(Proimage, fit: BoxFit.cover)
                                    : Image.asset('lib/images/profile.png'),
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
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: () => openBottomShett(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              " ",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
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
                            child: Container(
                              width: 160,
                              height: 160,
                              child: Proimage != ""
                                  ? Image.network(Proimage, fit: BoxFit.cover)
                                  : Image.asset('lib/images/profile.png'),
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
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: () => openBottomShett(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            Email,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        title: Text(
                          "Name: " + Name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      buildProfileDetail('Phone', phoneController),
                      SizedBox(height: 10),
                      ListTile(
                        title: Text(
                          "Number of item Donated: " + numOfdonation.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          "Number of item Received: " +
                              numOfReceived.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
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

  Widget buildProfileDetail(String label, TextEditingController controller) {
    return isEditing
        ? TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: label),
            style: const TextStyle(
              fontSize: 16,
            ),
          )
        : ListTile(
            title: Text(
              label + ': ' + controller.text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          );
  }

  void _openGallery() async {
    XFile? _pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (_pickedImage == null) return;
    String uniquefilename = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDir = referenceRoot.child('images');
    Reference referenceToUpload = referenceDir.child(uniquefilename);
    try {
      await referenceToUpload.putFile(File(_pickedImage.path));
      imagePath = await referenceToUpload.getDownloadURL();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilepic': imagePath});

        CollectionReference foodpostsCollection =
            FirebaseFirestore.instance.collection('foodposts');
        QuerySnapshot querySnapshot = await foodpostsCollection
            .where('donorId', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          for (QueryDocumentSnapshot doc in querySnapshot.docs) {
            await foodpostsCollection
                .doc(doc.id)
                .update({'donatorimagepath': imagePath});
          }
        } else {
          print('No documents found');
        }
      }

      setState(() {});
    } catch (error) {}
  }

  void _openCamera() async {
    final _pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (_pickedImage == null) return;
    String uniquefilename = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDir = referenceRoot.child('images');
    Reference referenceToUpload = referenceDir.child(uniquefilename);
    try {
      await referenceToUpload.putFile(File(_pickedImage.path));
      imagePath = await referenceToUpload.getDownloadURL();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilepic': imagePath});
      }

      setState(() {});
    } catch (error) {}
  }

  void openBottomShett() {
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
          height: 190,
          color: Color.fromARGB(255, 255, 255, 255),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  color: Colors.grey[400],
                  margin: EdgeInsets.only(bottom: 23.0, top: 8.0),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _openCamera(),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.camera,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 40.0,
                            ),
                          ),
                          SizedBox(
                            height: 8.0,
                          ),
                          Text(
                            'Take Photo from Camera',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    GestureDetector(
                      onTap: () => _openGallery(),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.photo_library,
                              color: Color.fromARGB(255, 0, 0, 0),
                              size: 40.0,
                            ),
                          ),
                          SizedBox(
                            height: 8.0,
                          ),
                          Text(
                            'Choose from Gallery',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
