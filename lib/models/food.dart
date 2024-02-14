class Food {
  String name;
  String imagepath;
  String donatorName;
  String donatorimagepath;
  String description;
  String pickuptime;
  String pickuplocation;
  String foodpostid;
  String type;
  String time;
  String donorId;

  Food({
    required this.name,
    required this.imagepath,
    required this.donatorName,
    required this.donatorimagepath,
    required this.description,
    required this.pickuptime,
    required this.pickuplocation,
    required this.foodpostid,
    required this.type,
    required this.time,
    required this.donorId,
  });
  String get _name => name;
  String get _imagepath => imagepath;
  String get _donatorName => donatorName;
  String get _donatorimagepath => donatorimagepath;
  String get _description => description;
  String get _pickuptime => pickuptime;
  String get _pickuplocation => pickuplocation;
  String get _foodpostid => foodpostid;
  String get _type => type;
  String get _time => time;
}
