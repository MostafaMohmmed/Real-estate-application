import 'package:flutter/material.dart';
import '../../modle/modservice.dart';

class Company_Privacy_Policy extends StatefulWidget {
  const Company_Privacy_Policy({super.key});

  @override
  State<Company_Privacy_Policy> createState() => _CompanyPrivacyPolicyState();
}

class _CompanyPrivacyPolicyState extends State<Company_Privacy_Policy> {
  List<modservice> mod1 = [
    modservice(
      Title: 'Terms 1',
      desc:
      'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the',
    ),
    modservice(
      Title: 'Terms 2',
      desc:
      'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the',
    ),
    modservice(
      Title: 'Terms 3',
      desc:
      'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the',
    ),
    modservice(
      Title: 'Terms 4',
      desc:
      'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the',
    ),
    modservice(
      Title: 'Terms 5',
      desc:
      'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.02,
        ),
        child: ListView.separated(
          itemCount: mod1.length,
          separatorBuilder: (context, index) => SizedBox(height: size.height * 0.02),
          itemBuilder: (context, index) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mod1[index].Title,
                      style: TextStyle(
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      mod1[index].desc,
                      style: TextStyle(
                        fontSize: size.width * 0.038,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
