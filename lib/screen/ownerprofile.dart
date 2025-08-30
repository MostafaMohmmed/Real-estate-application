import 'package:flutter/material.dart';

import '../modle/modprofile.dart';


class ownerprofile extends StatefulWidget {
  const ownerprofile({super.key});

  @override
  State<ownerprofile> createState() => _ownerprofileState();
}

class _ownerprofileState extends State<ownerprofile> {
  List<modprofile>mod=[
    modprofile(img: '', title: 'asd', price: '20000', Suptitle: 'Suptitle', pad: '1', food: '2', shower: '1',iconimg: ''),
    modprofile(img: '', title: 'titadle', price: '20000', Suptitle: 'Suptitle', pad: '1', food: '2', shower: '1',iconimg: ''),
    modprofile(img: '', title: 'dsad', price: '20000', Suptitle: 'Suptitle', pad: '2', food: '1', shower: '2',iconimg: ''),
    modprofile(img: '', title: 'asdd', price: '20000', Suptitle: 'Suptitle', pad: '3', food: '2', shower: '1',iconimg: ''),

  ];







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: (){}
        , backgroundColor: Color(0xff22577A)
        ,     child: Icon(Icons.grid_view,color: Colors.white,), // زر الشبكة في النص
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(color: Colors.white,
        shape: CircularNotchedRectangle(), // يخلي مكان للزر الدائري
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.home), onPressed: () {}),
            SizedBox(width: 40), // مساحة للزر العائم
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
              Text('Owner Profile',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 15),),
            ],
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 5),
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5)
            ),
            child: Icon(Icons.bookmark,color: Colors.deepPurpleAccent,),
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 40,),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Mostafa kullab',style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),),
                Text('example@gmail.com',style: TextStyle(color: Colors.grey,fontSize: 14),)
              ],
            ),
          )
          ,
          Padding(
            padding:  EdgeInsets.all(8.0),
            child: Align(
                alignment: Alignment.topLeft,
                child: Text('Property',style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),)),
          ),

          Container(
            height: 500,
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(height: 20,);
              },
              itemCount:mod.length,
              shrinkWrap: true,
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
                                SizedBox(width: 2),
                                Text(mod[index].food, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)),
                                SizedBox(width: 15),
                                Icon(Icons.ac_unit, color: Colors.deepOrange, size: 15),
                                SizedBox(width: 2),
                                Text(mod[index].food, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)),
                                SizedBox(width: 15),
                                Icon(Icons.ac_unit, color: Colors.deepOrange, size: 15),
                                Text(mod[index].food, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)),
                                SizedBox(width: 5),

                                Icon(Icons.ac_unit, color: Colors.deepOrange, size: 15),

                                SizedBox(width: 2),
                                Text(mod[index].food, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 7)),

                              ],
                            ),
                          ],
                        ),
                      )

                    ],
                  ),
                );

              }, ),
          )



        ],
      ),
    );
  }
}
