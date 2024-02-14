import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sparebusket/admin/viewProfile.dart';

class UserSupport extends StatefulWidget {
  const UserSupport({Key? key}) : super(key: key);

  @override
  State<UserSupport> createState() => _UserSupportState();
}

class _UserSupportState extends State<UserSupport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users Support"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('unbanrequest').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final supports = snapshot.data?.docs;
          return ListView.builder(
            itemCount: supports?.length ?? 0,
            itemBuilder: (context, index) {
              final req = supports![index].data() as Map<String, dynamic>;

              return Center(
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  width: 600,
                  child: Card(
                    margin: const EdgeInsets.all(4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      req['name'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 4),
                                    Text(req['email']),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  req['message'],
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Are you sure?"),
                                    content: Text(
                                        "You want to unban ${req['name']}?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          String userId = req['userId'];
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({
                                            'ban': false,
                                          });
                                          await FirebaseFirestore.instance
                                              .collection('unbanrequest')
                                              .where('userId',
                                                  isEqualTo: userId)
                                              .get()
                                              .then((QuerySnapshot
                                                  querySnapshot) {
                                            querySnapshot.docs.forEach((doc) {
                                              doc.reference.delete();
                                            });
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "User account has been unbanned"),
                                            ),
                                          );
                                        },
                                        child: Text("Yes"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 113, 255, 132),
                              minimumSize: Size(100, 50),
                            ),
                            child: const Text(
                              "Unban",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
