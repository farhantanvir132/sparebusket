class Notifi {
  String donorname;
  String receivername;
  String donorId;
  String receiverId;
  String message;
  String ncount;
  String foodtitle;
  String foodId;
  String time;

  Notifi({
    required this.donorname,
    required this.receivername,
    required this.donorId,
    required this.receiverId,
    required this.foodtitle,
    required this.foodId,
    required this.message,
    required this.ncount,
    required this.time,
  });
  Map<String, dynamic> toMap() {
    return {
      'donorname': donorname,
      'donorId': donorId,
      'receivername': receivername,
      'receiverId': receiverId,
      'foodtitle': foodtitle,
      'foodId': foodId,
      'message': message,
      'ncount': ncount,
      'time': time,
    };
  }
}
