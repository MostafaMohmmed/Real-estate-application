import 'package:final_iug_2025/screen/searchPage.dart';
import 'package:final_iug_2025/screen/settings.dart';
import 'package:flutter/material.dart';

import '../modle/modprofile.dart';
import '../modle/modproperty.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<String> label = ['House', 'Apartment', 'Office', 'Land'];
  int currentIndex = 0;

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
    ),
    modproperty(
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

  List<modprofile> House1 = [
    modprofile(
      img: 'images/apartment_1.png',
      title: 'House11',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'House22',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'House33',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'House44',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
  ];
  List<modprofile> Apartment1 = [
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Apartment11',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Apartment22',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Apartment33',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Apartment44',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
  ];
  List<modprofile> Office1 = [
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Office11',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Office22',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Office33',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Office44',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
  ];
  List<modprofile> Land1 = [
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Land11',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Land22',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Land33',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
    modprofile(
      img: 'images/apartment_1.png',
      title: 'Land44',
      price: '123312',
      Suptitle: 'House1',
      pad: '1',
      food: '1',
      shower: '1',
      iconimg: '1',
    ),
  ];
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
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
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const homePage()),
                );
              },
            ),
            SizedBox(width: size.width * 0.1),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              },
            ),
          ],
        ),
      ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello!',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.045,
                ),
              ),
              Text(
                'Mostafa',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: size.width * 0.04,
                ),
              ),
            ],
          ),
          actions: [
            const Icon(Icons.bookmark_sharp, color: Colors.blue),
            SizedBox(width: size.width * 0.04),
            const CircleAvatar(backgroundImage: AssetImage('images/personal.png')),
            SizedBox(width: size.width * 0.02),
          ],
        ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white60,
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.blue),
                        hintText: 'Search...',
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.02),
                  InkWell(
                    onTap: () {
                      String query = searchController.text.trim();
                      if (query.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => searchPage(searchQuery: query),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
                      child: Row(
                        children: [
                          Image.asset('images/filter.png', width: size.width * 0.05),
                          SizedBox(width: size.width * 0.01),
                          Text('Filters', style: TextStyle(color: Colors.white, fontSize: size.width * 0.035)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: size.height * 0.05,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                separatorBuilder: (context, index) => SizedBox(width: size.width * 0.05),
                itemBuilder: (context, index) {
                  bool isSelected = currentIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepOrange : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          label[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: size.width * 0.04,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                itemCount: label.length,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Property',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.04),
                  ),
                  Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(color: Colors.green, fontSize: size.width * 0.03),
                      ),
                      SizedBox(width: size.width * 0.01),
                      Icon(
                        Icons.arrow_circle_right_rounded,
                        color: Colors.green,
                        size: size.width * 0.04,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: size.height * 0.4,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                itemBuilder: (context, index) {
                  modproperty property;
                  if (currentIndex == 0) {
                    property = House[index];
                  } else if (currentIndex == 1) {
                    property = Apartment[index];
                  } else if (currentIndex == 2) {
                    property = Office[index];
                  } else {
                    property = Land[index];
                  }
                  return InkWell(
                    onTap: () {},
                    child: Container(
                      width: size.width * 0.45,
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              property.img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: size.height * 0.2,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(size.width * 0.02),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  property.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: size.width * 0.035,
                                  ),
                                ),
                                Text(
                                  property.price,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: size.width * 0.035,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ac_unit,
                                      color: Colors.deepOrange,
                                      size: size.width * 0.04,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      property.Suptitle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.025,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ac_unit,
                                      color: Colors.deepOrange,
                                      size: size.width * 0.04,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      property.pad,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.025,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ac_unit,
                                      color: Colors.deepOrange,
                                      size: size.width * 0.04,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      property.food,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.025,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(width: size.width * 0.03),
                itemCount: House.length,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Featured Property',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: size.width * 0.04),
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                modprofile profile;
                if (currentIndex == 0) {
                  profile = House1[index];
                } else if (currentIndex == 1) {
                  profile = Apartment1[index];
                } else if (currentIndex == 2) {
                  profile = Office1[index];
                } else {
                  profile = Land1[index];
                }
                return Container(
                  color: Colors.white60,
                  padding: EdgeInsets.all(size.width * 0.04),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          profile.img,
                          width: size.width * 0.2,
                          height: size.width * 0.2,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: size.width * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  profile.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: size.width * 0.03,
                                  ),
                                ),
                                Text(
                                  profile.price,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: size.width * 0.03,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: size.width * 0.03),
                                SizedBox(width: size.width * 0.01),
                                Text(
                                  profile.Suptitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: size.width * 0.03,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: size.height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ac_unit,
                                      color: Colors.deepOrange,
                                      size: size.width * 0.04,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      profile.pad,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.025,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ac_unit,
                                      color: Colors.deepOrange,
                                      size: size.width * 0.04,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      profile.food,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.025,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.ac_unit,
                                      color: Colors.deepOrange,
                                      size: size.width * 0.04,
                                    ),
                                    SizedBox(width: size.width * 0.01),
                                    Text(
                                      profile.shower,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.025,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: size.height * 0.02),
              itemCount: House1.length,
            ),
          ],
        ),
      ),
    );
  }
}