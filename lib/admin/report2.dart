import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReport2 extends StatefulWidget {
  const AdminReport2({Key? key}) : super(key: key);

  @override
  State<AdminReport2> createState() => _AdminReport2State();
}

class _AdminReport2State extends State<AdminReport2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports for Recievers"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('receiverreports')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs;
          print("Number of reports: ${reports?.length}");
          return ListView.builder(
            itemCount: reports?.length ?? 0,
            itemBuilder: (context, index) {
              final report = reports![index].data() as Map<String, dynamic>;
              print("Report data: $report");
              return Center(
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  width: 750,
                  child: Card(
                    margin: const EdgeInsets.all(8),
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
                                Text(
                                  report['donorName'] +
                                      ' has reported on ' +
                                      report['receiverName'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(report['reportText']),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Are you sure?"),
                                    content: Text(
                                        "You want to warn ${report['receiverName']}?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          String userId = report['receiverId'];
                                          String userName =
                                              report['receiverName'];
                                          String message =
                                              "based on a report, your activity is against the SpareBasket Community guidelines. Such activity may result in an account ban.";

                                          await FirebaseFirestore.instance
                                              .collection('nofifromadmin')
                                              .add({
                                            'userId': userId,
                                            'userName': userName,
                                            'message': message,
                                          });

                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({
                                            'warning': FieldValue.increment(1),
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "A warning message has been sent to the user"),
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
                              backgroundColor: Colors.yellow[200],
                              minimumSize: Size(100, 50),
                            ),
                            child: Text(
                              "Warn " + report['receiverName'],
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Are you sure?"),
                                    content: Text(
                                        "You want to Ban ${report['donorName']}?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          String userId = report['receiverId'];
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({
                                            'ban': true,
                                          });
                                          await FirebaseFirestore.instance
                                              .collection('receiverreports')
                                              .where('receiverId',
                                                  isEqualTo: userId)
                                              .get()
                                              .then((QuerySnapshot
                                                  querySnapshot) {
                                            querySnapshot.docs.forEach((doc) {
                                              doc.reference.delete();
                                            });
                                          });

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text("User has been banned"),
                                            ),
                                          );
                                          Navigator.pop(context);
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
                                  const Color.fromARGB(255, 255, 17, 0),
                              minimumSize: Size(100, 50),
                            ),
                            child: Text("Ban " + report['receiverName']),
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
