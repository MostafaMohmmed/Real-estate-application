


import 'package:flutter/material.dart';

import '../modle/modservice.dart';
class service extends StatefulWidget {
  const service({super.key});

  @override
  State<service> createState() => _serviceState();
}

class _serviceState extends State<service> {
  List<modservice>mod1=[
    modservice(Title: 'Terms1', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')
    ,    modservice(Title: 'Terms2', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')
    ,    modservice(Title: 'Terms3', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')
    ,    modservice(Title: 'Terms4', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')
    ,    modservice(Title: 'Terms4', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')
    ,    modservice(Title: 'Terms4', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')
    ,    modservice(Title: 'Terms4', desc: 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the')


  ];






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding:  EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios,size: 17,),
              Text('Terms of Service',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 15),),
            ],
          ),
        ),

      ),
      body: Column(
        children: [
          Container(
            height: 800,
            child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 80),
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(mod1[index].Title,style: TextStyle(fontSize: 20,color: Colors.black))),
                      ),
                      Container(
                        width: 250,
                        child: Text(mod1[index].desc
                          , textAlign: TextAlign.start,style: TextStyle(color: Colors.black),),
                      )
                    ],
                  );

                }, separatorBuilder: (context, index) {
              return SizedBox(height: 70,);
            }, itemCount: mod1.length),
          )
        ],
      ),

    );
  }
}
