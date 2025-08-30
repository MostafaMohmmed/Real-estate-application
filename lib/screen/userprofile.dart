import 'package:flutter/material.dart';
import '../modle/modprofile.dart';


class userprofile extends StatefulWidget {
  const userprofile({super.key});

  @override
  State<userprofile> createState() => _userprofileState();
}

class _userprofileState extends State<userprofile> {

  List<modprofile>mod=[
    modprofile(img: 'images/apartment_1.png', title: 'asd', price: '20000', Suptitle: 'Suptitle', pad: 'pad', food: 'food', shower: 'shower',iconimg: ''),
    modprofile(img: 'images/apartment_1.png', title: 'titadle', price: '20000', Suptitle: 'Suptitle', pad: 'pad', food: 'food', shower: 'shower',iconimg: ''),
    modprofile(img: 'images/apartment_1.png', title: 'dsad', price: '20000', Suptitle: 'Suptitle', pad: 'pad', food: 'food', shower: 'shower',iconimg: ''),
    modprofile(img: 'images/apartment_1.png', title: 'asdd', price: '20000', Suptitle: 'Suptitle', pad: '3', food: '2', shower: '1',iconimg: ''),
    modprofile(img: 'images/apartment_1.png', title: 'asdd', price: '20000', Suptitle: 'Suptitle', pad: '3', food: '2', shower: '1',iconimg: ''),
    modprofile(img: 'images/apartment_1.png', title: 'asdd', price: '20000', Suptitle: 'Suptitle', pad: '3', food: '2', shower: '1',iconimg: ''),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: (){}
        , backgroundColor: Color(0xff22577A)
        ,     child: Icon(Icons.grid_view,color: Colors.white,),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(color: Colors.white,
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.home), onPressed: () {}),
            SizedBox(width: 40),
            IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
      appBar: AppBar(
        title: Padding(
          padding:  EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios,size: 17,),
              Text('User Profile',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 15),),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView( // ✅ الحل: وضع Column بأكملها داخل SingleChildScrollView
        child: Column(
            children: [
        ListTile(
        leading:Container(
        width: 80,
            height: 80,
            child: Image(image: AssetImage('images/personal.png'))),
        title: Text('Mostafa sas', style: TextStyle(fontSize: 20,color: Colors.black,fontWeight: FontWeight.bold),),
        subtitle: Text('Mostafa sas', style: TextStyle(fontSize: 15,color: Colors.blueGrey,),),
      ),
      SizedBox(height: 20,),
      Padding(
        padding:  EdgeInsets.only(left: 12),
        child: Align(
            alignment: Alignment.topLeft,
            child: Text('Saved', style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.bold),)),
      ),
      ListView.builder(
        itemCount:mod.length,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(), // ✅ يمنع ListView من التمرير الخاص به
        itemBuilder:(context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white60,
            ),
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  child: Image.asset(mod[index].img),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: 80,
                  height: 80,
                ),
                SizedBox(height: 10),
                Padding(
                  padding:  EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mod[index].title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 100),
                          Text(
                            mod[index].price,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 10),
                          SizedBox(width: 5),
                          Text(
                            mod[index].Suptitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.ac_unit, color: Colors.deepOrange, size: 15),
                          SizedBox(width: 5),
                          Text(mod[index].pad, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)), // ✅ تم تصحيح mod2[index] إلى mod[index]
                          SizedBox(width: 15),
                          Icon(Icons.ac_unit, color: Colors.deepOrange, size: 15),
                          SizedBox(width: 5),
                          Text(mod[index].food, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)), // ✅ تم تصحيح mod2[index] إلى mod[index]
                          SizedBox(width: 15),
                          Icon(Icons.ac_unit, color: Colors.deepOrange, size: 15),
                          SizedBox(width: 5),
                          Text(mod[index].food, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)), // ✅ تم تصحيح mod2[index] إلى mod[index]
                        ],
                      ),
                    ],
                  ),
                )

              ],
            ),
          );

        }, ),


    ],
    ),
    ));
  }
}

class modprofile {
  String img, title, price, Suptitle, pad, food, shower, iconimg;

  modprofile({
    required this.img,
    required this.title,
    required this.price,
    required this.Suptitle,
    required this.pad,
    required this.food,
    required this.shower,
    required this.iconimg,
  });
}