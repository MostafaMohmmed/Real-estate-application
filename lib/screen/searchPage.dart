import 'package:flutter/material.dart';
import '../modle/duplexSearch.dart';
import '../modle/modprofile.dart';
import '../modle/modproperty.dart'; // تأكد من وجود هذا الملف
import 'confirmPage.dart';
import 'homePage.dart'; // تأكد من وجود هذا الملف

class searchPage extends StatefulWidget {
  // ✅ الآن الكلاس يستقبل كلمة البحث
  final String? searchQuery;

  const searchPage({super.key, this.searchQuery});

  @override
  State<searchPage> createState() => _searchPageState();
}

class _searchPageState extends State<searchPage> {

  // قوائم الكود الأول
  int currentIndexduplex = 0;
  List<duplexSearch> duplex = [
    duplexSearch(Img: 'images/Image_beg.png', price: '5454', title: 'asddd'),
    duplexSearch(Img: 'images/Image_beg.png', price: '5454', title: 'asddd'),
    duplexSearch(Img: 'images/Image_beg.png', price: '5454', title: 'asddd'),
    duplexSearch(Img: 'images/Image_beg.png', price: '5454', title: 'asddd'),
    duplexSearch(Img: 'images/Image_beg.png', price: '5454', title: 'asddd'),
    duplexSearch(Img: 'images/Image_beg.png', price: '5454', title: 'asddd'),
  ];
  List<String> label = ['Building', 'Outside Wall', 'Others'];
  int currentIndex = 0;

  // قوائم الكود الثاني (للبحث)
  List<dynamic> allItems = [];
  List<dynamic> filteredItems = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _filterItems(widget.searchQuery!);
    }
  }

  void _initializeData() {
    // ✅ اجمع كل القوائم من الكود الثاني
    List<modproperty> House = [
      modproperty(
        img: 'images/apartment_1.png',
        title: 'House1',
        price: '8999',
        Suptitle: 'Enjoy.',
        pad: '222',
        food: '111111',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'House2',
        price: '34',
        Suptitle: '43',
        pad: '44',
        food: '33',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'House3',
        price: '55',
        Suptitle: '56',
        pad: '65',
        food: '66',
      ),  modproperty(
        img: 'images/apartment_1.png',
        title: 'House4',
        price: '77',
        Suptitle: '78',
        pad: '87',
        food: '88',
      ),

    ];
    List<modproperty> Apartment = [
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Apartment1',
        price: '12',
        Suptitle: '21',
        pad: '22',
        food: '11',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Apartment2',
        price: '34',
        Suptitle: '43',
        pad: '33',
        food: '44',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Apartment3',
        price: '56',
        Suptitle: '65',
        pad: '55',
        food: '66',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Apartment4',
        price: '78',
        Suptitle: '87',
        pad: '77',
        food: '88',
      ),
    ];
    List<modproperty> Office = [
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Office1',
        price: '12',
        Suptitle: '21',
        pad: '22',
        food: '11',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Office2',
        price: '34',
        Suptitle: '43',
        pad: '33',
        food: '44',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Office3',
        price: '56',
        Suptitle: '65',
        pad: '55',
        food: '66',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Office4',
        price: '78',
        Suptitle: '87',
        pad: '88',
        food: '77',
      ),
    ];
    List<modproperty> Land = [
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Land',
        price: '12',
        Suptitle: '21',
        pad: '22',
        food: '11',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Land2',
        price: '34',
        Suptitle: '443',
        pad: '44',
        food: '55',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Lan3',
        price: '56',
        Suptitle: '65',
        pad: '55',
        food: '66',
      ),
      modproperty(
        img: 'images/apartment_1.png',
        title: 'Land4',
        price: '78',
        Suptitle: '87',
        pad: '77',
        food: '88',
      ),
    ];

    List<modprofile>House1=[
      modprofile(      img: 'images/apartment_1.png',
          title: 'House11', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'House22', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'House33', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'House44', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),

    ];
    List<modprofile>Apartment1=[
      modprofile(      img: 'images/apartment_1.png',
          title: 'Apartment11', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Apartment22', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Apartment33', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Apartment44', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),

    ];
    List<modprofile>Office1=[
      modprofile(      img: 'images/apartment_1.png',
          title: 'Office11', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Office22', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Office33', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Office44', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),

    ];
    List<modprofile>Land1=[
      modprofile(      img: 'images/apartment_1.png',
          title: 'Land11', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Land22', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Land33', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),
      modprofile(      img: 'images/apartment_1.png',
          title: 'Land44', price: '123312', Suptitle: 'House1', pad: '1', food: '1', shower: '1', iconimg: '1'),

    ];
    // تأكد من إضافة جميع قوائم modproperty و modprofile هنا
    allItems = [...House , ...Apartment, ...Office, ...Land, ...House1, ...Apartment1, ...Office1, ...Land1];
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = allItems.where((item) {
        return item.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [

              SizedBox(width: 8),
              Text(
                'Search Estimated Cost',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xff22577A),
        child: const Icon(Icons.grid_view, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => homePage(),
                ),
              );
            }),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),

      body: Column(
        children: [
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onSubmitted: (value) {
                _filterItems(value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200], // لتغيير لون الخلفية
                prefixIcon: Icon(Icons.search_rounded, color: Colors.blue),
                hintText: 'duplex house......',
              ),
            ),
          ),
          SizedBox(height: 20),
          // جزء "Duplex houses" الثابت
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duplex houses',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                    Icon(Icons.arrow_circle_right, size: 10, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // قائمة Duplex houses الأفقية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 80,
              width: double.infinity,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentIndexduplex = index;
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child:
                      Image.asset(duplex[index].Img),
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(width: 15),
                itemCount: 5,
              ),
            ),
          ),
          SizedBox(height: 15),
          // قائمة الأزرار 'Building', 'Outside Wall', 'Others'
          Container(
            width: double.infinity,
            height: 30,
            child: Center(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => SizedBox(width: 25),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  bool isSelected = currentIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(7, 0, 7, 0),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepOrange : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          label[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: label.length,
              ),
            ),
          ),
          // ✅ هنا يتم عرض نتائج البحث أو القائمة الثابتة حسب الحالة
          Expanded(
            child: widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                ? (filteredItems.isEmpty
                ? Center(
              child: Text(
                "ما في نتائج تطابق بحثك",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: Image.asset(
                      item.img,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text("price: ${item.price}"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                    onTap: () {
                      // يفتح صفحة التفاصيل
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => confirmPage(
                            imgpath: item.img,
                            price: item.price,
                            title: item.title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ))
                : Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return confirmPage(
                                imgpath: duplex[currentIndexduplex].Img,
                                price: duplex[currentIndexduplex].price,
                                title: duplex[currentIndexduplex].title,
                              );
                            },
                          ),
                        );
                      },
                      child: Image(image: AssetImage(duplex[currentIndexduplex].Img)),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Center(
                  //   child: Text(
                  //     'Duplex house (2000 sqft)',
                  //     style: TextStyle(
                  //       color: Colors.black,
                  //       fontSize: 15,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}