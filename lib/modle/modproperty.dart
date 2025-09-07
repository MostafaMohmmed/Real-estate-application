class modproperty{
  late String img ;
  late String title;
  late String price;
  late String Suptitle;
  late String pad;
  late String food;

  modproperty({
    required this.img,
    required this.title,
    required this.price,
    required this.Suptitle,
    required this.pad,
    required this.food,
  });

}
class PropertyModel {
  String title;
  String price;
  String location;
  String description;
  String type; // House / Apartment / Office / Land
  String imagePath;

  PropertyModel({
    required this.title,
    required this.price,
    required this.location,
    required this.description,
    required this.type,
    required this.imagePath,
  });
}
