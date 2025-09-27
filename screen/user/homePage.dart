// homePage.dart
import 'package:final_iug_2025/screen/user/searchPage.dart';
import 'package:final_iug_2025/screen/user/see_all_properties_page.dart';
import 'package:flutter/material.dart';

import 'AllPropertyHomePage.dart';
import 'FeaturedPropertyhomepage.dart';
import 'settings/settings.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});
  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  final List<String> labels = ['House', 'Apartment', 'Office', 'Land'];
  int currentIndex = 0;
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            SizedBox(width: size.width * 0.1),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
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
            Text('Hello!',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.045)),
            Text('Mostafa',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: size.width * 0.04)),
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
            // شريط البحث + زر Filters
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.02, vertical: size.height * 0.01),
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
                  GestureDetector(
                    onTap: () {
                      final q = searchController.text.trim();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SearchEstimatedCostPage(initialQuery: searchController.text)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.02,
                        vertical: size.height * 0.01,
                      ),
                      child: Row(
                        children: [
                          Image.asset('images/filter.png', width: size.width * 0.05),
                          SizedBox(width: size.width * 0.01),
                          Text('Filters',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.035)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // تبويب النوع
            SizedBox(
              height: size.height * 0.05,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                separatorBuilder: (_, __) => SizedBox(width: size.width * 0.05),
                itemCount: labels.length,
                itemBuilder: (_, i) {
                  final selected = currentIndex == i;
                  return InkWell(
                    onTap: () => setState(() => currentIndex = i),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
                      decoration: BoxDecoration(
                        color: selected ? Colors.deepOrange : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontSize: size.width * 0.04,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // All Property
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Property',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.04)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SeeAllPage()),
                      );
                    },
                    icon: const Icon(Icons.arrow_circle_right_rounded,
                        color: Colors.green),
                    label: const Text('See All',
                        style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            ),
            const AllPropertyHomePage(),

            // Featured Property
            Padding(
              padding: EdgeInsets.all(size.width * 0.02),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Featured Property',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.04)),
              ),
            ),
            FeaturedPropertyhomepage(propertyType: labels[currentIndex]),
          ],
        ),
      ),
    );
  }
}
