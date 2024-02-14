import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sparebusket/main.dart';
import 'package:sparebusket/screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class FoodPostingPage extends StatefulWidget {
  @override
  _FoodPostingPageState createState() => _FoodPostingPageState();
}

class _FoodPostingPageState extends State<FoodPostingPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController foodDetailsController = TextEditingController();
  TextEditingController foodNameController = TextEditingController();
  TextEditingController pickupLocationController = TextEditingController();
  TextEditingController pickupTimeController = TextEditingController();

  List<String> foodTypes = [
    "Raw Food",
    "Drink",
    "Rice",
    "Home Cooked",
    "Mixed",
  ];
  List<String> postTimes = [
    "6",
    "12",
    "24",
    "48",
  ];
  String selectedFoodType = "";
  String selectedPostTime = "";
  String imagePath = "";

  Widget buildFoodTypeButton(String foodType) {
    final isTapped = selectedFoodType == foodType;

    return Container(
      width: 150,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedFoodType = foodType;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            isTapped
                ? Color.fromARGB(137, 98, 216, 231)
                : Color.fromARGB(255, 158, 110, 241),
          ),
          overlayColor: MaterialStateProperty.all(
            isTapped ? Colors.black : Colors.transparent,
          ),
          side: MaterialStateProperty.all(
            isTapped
                ? const BorderSide(color: Colors.black, width: 1.0)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              foodType,
              style: TextStyle(
                color: isTapped ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPostTimeButton(String postTime) {
    final isTapped = selectedPostTime == postTime;

    return Container(
      width: 150,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedPostTime = postTime;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            isTapped
                ? Color.fromARGB(137, 98, 216, 231)
                : Color.fromARGB(255, 158, 110, 241),
          ),
          overlayColor: MaterialStateProperty.all(
            isTapped ? Colors.black : Colors.transparent,
          ),
          side: MaterialStateProperty.all(
            isTapped
                ? const BorderSide(color: Colors.black, width: 1.0)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              postTime,
              style: TextStyle(
                color: isTapped ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  File? _selectedImage;

  bool isPosting = false;

  void _handlePostFood() {
    setState(() {
      isPosting = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isPosting = false;
      });
    });
  }

  String? _postValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please fill the fields';
    }
    return null;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey[800],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Container(
              width: 300,
              alignment: Alignment.center,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: () => openBottomShett(),
                    iconSize: 64.0,
                  ),
                  const Text("Select a picture of the Food"),
                  const SizedBox(height: 16.0),
                  const SizedBox(height: 16.0),
                  _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          "Please select an image",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ],
              ),
            ),
            SizedBox(height: 40.0),
            Container(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Choose The Food Type",
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: foodTypes.map((foodType) {
                    return buildFoodTypeButton(foodType);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Food Post will be Available for(In hours): ",
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: postTimes.map((postTime) {
                    return buildPostTimeButton(postTime);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: foodNameController,
                    decoration: InputDecoration(labelText: "Food Name"),
                    validator: _postValidator,
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: foodDetailsController,
                    decoration: InputDecoration(
                      labelText: "Food Details",
                      alignLabelWithHint: true,
                    ),
                    validator: _postValidator,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: pickupLocationController,
                    decoration: InputDecoration(labelText: "Pickup Location"),
                    validator: _postValidator,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: pickupTimeController,
                    decoration: InputDecoration(labelText: "Pickup Time"),
                    validator: _postValidator,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(height: 1.5),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Stack(
                        children: [
                          ElevatedButton(
                            onPressed: isPosting
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate() &&
                                        _selectedImage != null) {
                                      if (selectedPostTime != null &&
                                          selectedPostTime.isNotEmpty &&
                                          selectedFoodType != null &&
                                          selectedFoodType.isNotEmpty) {
                                        setState(() {
                                          _handlePostFood();
                                          addFoodData();
                                        });
                                      } else {
                                        _showSnackbar(
                                            'Please select the Food type and Food available time');
                                      }
                                    } else {
                                      _showSnackbar(
                                          'Please fill all the fields correctly');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 130, 80, 218),
                              minimumSize: Size(200, 60),
                            ),
                            child: Text(
                              'Post Food',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isPosting)
                            Positioned.fill(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(137, 98, 216, 231),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      'Posting...',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    } catch (error) {}
    setState(() {
      _selectedImage = File(_pickedImage.path);
    });
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
    } catch (error) {}

    setState(() {
      _selectedImage = File(_pickedImage.path);
    });
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

  Future<void> addFoodData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final currentTime = DateTime.now();
      final formattedTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(currentTime);
      if (user != null) {
        String userId = user.uid;

        CollectionReference usersCollection =
            FirebaseFirestore.instance.collection('users');
        CollectionReference foodpost =
            FirebaseFirestore.instance.collection('foodposts');

        DocumentSnapshot userSnapshot = await usersCollection.doc(userId).get();

        if (userSnapshot.exists) {
          String name = userSnapshot.get('firstname');
          String donorimg = userSnapshot.get('profilepic');

          await foodpost.add({
            'donorId': userId,
            'donorname': name,
            'donatorimagepath': donorimg,
            'foodImageURL': imagePath,
            'item': selectedFoodType,
            'title': foodNameController.text,
            'availableTime': selectedPostTime,
            'description': foodDetailsController.text,
            'pickuptime': pickupTimeController.text,
            'pickuplocation': pickupLocationController.text,
            'deliverystatus': 0,
            'deliverycompleted': 0,
            'time': formattedTime,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food posted for the donation.'),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => HomePage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User document not found.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not logged in.'),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }
}
