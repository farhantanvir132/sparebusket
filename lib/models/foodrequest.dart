class Foodrequest {
  String donorname;
  String receivername;
  String donorId;
  String receiverId;
  String imagepath;
  String foodtitle;
  String foodId;
  int status;

  Foodrequest({
    required this.donorname,
    required this.imagepath,
    required this.receivername,
    required this.donorId,
    required this.receiverId,
    required this.foodtitle,
    required this.foodId,
    required this.status,
  });
  Map<String, dynamic> toMap() {
    return {
      'donorname': donorname,
      'donorId': donorId,
      'receivername': receivername,
      'receiverId': receiverId,
      'foodtitle': foodtitle,
      'imagepath': imagepath,
      'foodId': foodId,
      'status': status,
    };
  }
}
