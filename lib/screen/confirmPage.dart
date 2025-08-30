import 'package:flutter/material.dart';
import 'homePage.dart';
import 'propertdetalis.dart';

class confirmPage extends StatefulWidget {
  final String imgpath;
  final String title;
  final String price;

  const confirmPage({
    super.key,
    required this.imgpath,
    required this.title,
    required this.price,
  });

  @override
  State<confirmPage> createState() => _confirmPageState();
}

class _confirmPageState extends State<confirmPage> {
  @override
  Widget build(BuildContext context) {
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
                    MaterialPageRoute(builder: (context) => homePage()),
                  );
                }),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                'Purchase the property',
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
      body: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset(widget.imgpath), // ✅ الصورة المرسلة
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.title, // ✅ العنوان
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.price, // ✅ السعر
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(
                    width: 250,
                    child: Text(
                      'Enjoy high-quality sound with these wireless headphones. Designed for comfort and long battery life',
                      style: TextStyle(),
                      maxLines: 3,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // ✅ لما يضغط على Confirm => يفتح Propertdetalis و يرسل البيانات
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Propertdetalis(
                      imgpath: widget.imgpath,
                      title: widget.title,
                      price: widget.price,
                    ),
                  ),
                );
              },
              child: const Text(
                'Confirm Purchase',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
