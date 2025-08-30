import 'package:flutter/material.dart';

import '../modle/modnotification.dart';

class notification extends StatefulWidget {
  const notification({super.key});

  @override
  State<notification> createState() => _notificationState();
}

class _notificationState extends State<notification> {
  List<modnotification>mod=[
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img2', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img1', title: 'title', suptitle: 'suptitle'),
    modnotification(img: 'img4', title: 'title', suptitle: 'suptitle'),

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
              Text('Notificatin',style: TextStyle( color: Colors.black,fontWeight: FontWeight.bold,fontSize: 20),),
            ],
          ),
        ),

      ),
      body: Column(
        children: [
          Container(
            height: 700,
            child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Image(image: AssetImage(mod[index].img),height: 50,width: 50,),)
                    ,title: Text(mod[index].title,style: TextStyle(fontSize: 15),),
                    subtitle: Text(mod[index].suptitle,style: TextStyle(fontSize: 15),),
                  );

                }, separatorBuilder:(context, index) {
              return SizedBox(height: 30,);
            } , itemCount: mod.length),
          )

        ],
      ),

    );
  }
}
