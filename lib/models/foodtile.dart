import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/models/food.dart';

class FoodTile extends StatefulWidget {
  final Food food;

  final void Function()? onTap;
  const FoodTile({super.key, required this.food, required this.onTap});

  @override
  State<FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends State<FoodTile> {
  String avgRating = "";
  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();

    fetchAverageRating();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchAverageRating() async {
    CollectionReference donorRatingsCollection =
        FirebaseFirestore.instance.collection('ratings');

    QuerySnapshot donorRatingsSnapshot = await donorRatingsCollection
        .where('userId', isEqualTo: widget.food.donorId)
        .get();

    if (donorRatingsSnapshot.docs.isNotEmpty) {
      List<int> ratings =
          donorRatingsSnapshot.docs.map((doc) => doc['rating'] as int).toList();

      double totalRating =
          ratings.fold(0, (previous, current) => previous + current);
      averageRating = totalRating / ratings.length;
      if (mounted) {
        setState(() {
          averageRating = double.parse(averageRating.toStringAsFixed(1));
          avgRating = averageRating.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 136, 136, 136).withOpacity(0.5),
              spreadRadius: 0.7,
              blurRadius: 1.5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.food.imagepath,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Text(
              widget.food.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              child: Row(
                children: [
                  ClipOval(
                      child: widget.food.donatorimagepath != ""
                          ? Image.network(
                              widget.food.donatorimagepath,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'lib/images/profile.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            )),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    widget.food.donatorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.yellow[800],
                  ),
                  Text(avgRating),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        widget.food.time,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
