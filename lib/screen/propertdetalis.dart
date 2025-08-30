import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Propertdetalis extends StatefulWidget {
  // ✅ إضافة استقبال البيانات
  final String imgpath;
  final String title;
  final String price;

  const Propertdetalis({
    super.key,
    required this.imgpath,
    required this.title,
    required this.price,
  });

  @override
  State<Propertdetalis> createState() => _PropertdetalisState();
}

class _PropertdetalisState extends State<Propertdetalis> {
  bool visibleAmenities = false;
  bool visibleInteriorDetails = false;
  bool visibleConstructionDetails = false;
  bool visibleLocationMapDerails = false;

  List<String> label = ['Location Map', 'Hospital', 'School'];
  int currentIndex = 0;
  String changeimg = 'images/location.png';
  String schoolimg = 'images/location.png';
  String locationimg = 'images/location.png';
  String hospital = 'images/location.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 411; // قاعدة الريسپونسف

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              SizedBox(width: 4 * scale),
              Text(
                'Property Details',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: (16 * scale).clamp(12, 20),
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8 * scale),
              padding: EdgeInsets.all(4 * scale),
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(6)),
              child: Icon(Icons.bookmark,
                  color: Colors.deepPurpleAccent, size: 18 * scale),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.all(12 * scale),
          children: [
            SizedBox(height: 12 * scale),
            Text(
              'Property Details',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: (16 * scale).clamp(12, 20),
              ),
            ),
            SizedBox(height: 8 * scale),

            // ✅ صورة العقار (من البيانات الممررة)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  widget.imgpath, // الصورة من confirmPage
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SizedBox(height: 16 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ العنوان من confirmPage
                Text(widget.title,
                    style: TextStyle(
                        fontSize: (15 * scale).clamp(12, 18),
                        color: Colors.black)),
                // ✅ السعر من confirmPage
                Text(widget.price,
                    style: TextStyle(
                        fontSize: (15 * scale).clamp(12, 18),
                        color: Colors.blue)),
              ],
            ),

            SizedBox(height: 8 * scale),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on_outlined, size: 16 * scale),
              title: Text(
                '2BW Street NY, New York',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: (12 * scale).clamp(10, 16),
                ),
              ),
              trailing: Text(
                '(2000sqft)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: (12 * scale).clamp(10, 16),
                ),
              ),
            ),
            SizedBox(height: 12 * scale),

            // باقي الكود كما هو 👇
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                return Row(
                  children: [
                    Icon(Icons.ac_unit,
                        color: Colors.deepOrange, size: 16 * scale),
                    SizedBox(width: 4 * scale),
                    Text('12',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (10 * scale).clamp(8, 14))),
                  ],
                );
              }),
            ),
            SizedBox(height: 16 * scale),
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset('images/profile.png', width: 40 * scale, height: 40 * scale),
              ),
              title: Text('Milan Jack',
                  style: TextStyle(fontSize: (15 * scale).clamp(12, 18))),
              subtitle: Text('Home Owner/Broker',
                  style: TextStyle(fontSize: (12 * scale).clamp(10, 16))),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Find houses, apartments, or land with an interactive map covering all regions and neighborhoods. Find houses, apartments, or land with an interactive map covering all regions.',
              style: TextStyle(fontSize: (13 * scale).clamp(10, 16)),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 12 * scale),

            RatingBar.builder(
              initialRating: 3,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemSize: (20 * scale).clamp(14, 24),
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4 * scale),
              itemBuilder: (context, index) =>
                  Icon(Icons.star, color: Colors.yellow),
              onRatingUpdate: (value) {},
            ),
            SizedBox(height: 20 * scale),

            // أقسام قابلة للطي
            _buildExpandableTile('Amenities', visibleAmenities, () {
              setState(() => visibleAmenities = !visibleAmenities);
            }, scale),
            if (visibleAmenities) _buildExpandableContent(['Gym', 'Pool'], scale),

            _buildExpandableTile('Interior Details', visibleInteriorDetails, () {
              setState(() => visibleInteriorDetails = !visibleInteriorDetails);
            }, scale),
            if (visibleInteriorDetails)
              _buildExpandableContent(['2 Bedrooms', '1 Kitchen'], scale),

            _buildExpandableTile(
                'Construction Details', visibleConstructionDetails, () {
              setState(
                      () => visibleConstructionDetails = !visibleConstructionDetails);
            }, scale),
            if (visibleConstructionDetails)
              _buildExpandableContent(['Built in 2020'], scale),

            _buildExpandableTile(
                'Location Map & Details', visibleLocationMapDerails, () {
              setState(() => visibleLocationMapDerails = !visibleLocationMapDerails);
            }, scale),
            if (visibleLocationMapDerails)
              _buildExpandableContent(['Near Metro Station'], scale),

            SizedBox(height: 20 * scale),

            // Tabs
            SizedBox(
              height: 40 * scale,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                separatorBuilder: (_, __) => SizedBox(width: 16 * scale),
                itemCount: label.length,
                itemBuilder: (context, index) {
                  final isSelected = currentIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentIndex = index;
                        if (index == 0) {
                          changeimg = locationimg;
                        } else if (index == 1) {
                          changeimg = hospital;
                        } else {
                          changeimg = schoolimg;
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale, vertical: 6 * scale),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepOrange : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          label[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: (14 * scale).clamp(10, 16),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20 * scale),

            // صورة الخريطة أو التاب المختار
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(changeimg, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20 * scale),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                minimumSize: Size(
                  double.infinity,
                  (50 * scale).clamp(40, 60),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (18 * scale).clamp(14, 20),
                ),
              ),
            ),
            SizedBox(height: 20 * scale),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTile(
      String title, bool isExpanded, VoidCallback onTap, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: (15 * scale).clamp(12, 18),
                  fontWeight: FontWeight.w500)),
          InkWell(
            onTap: onTap,
            child: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down_sharp,
              size: 28 * scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableContent(List<String> items, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((e) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4 * scale),
          child: Text(e,
              style: TextStyle(fontSize: (13 * scale).clamp(10, 16))),
        ))
            .toList(),
      ),
    );
  }
}
