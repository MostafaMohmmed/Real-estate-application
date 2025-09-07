import 'dart:io';
import 'package:flutter/material.dart';
import '../../modle/modproperty.dart';
import 'add_property_page.dart';
import 'companysettings.dart';
import 'edit_property_page.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage>
    with SingleTickerProviderStateMixin {
  List<PropertyModel> properties = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addProperty(PropertyModel property) {
    setState(() {
      properties.add(property);
    });
  }

  void _editProperty(int index, PropertyModel property) {
    setState(() {
      properties[index] = property;
    });
  }

  void _deleteProperty(int index) {
    setState(() {
      properties.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff22577A),
        onPressed: () async {
          final result = await Navigator.push<PropertyModel>(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyPage()),
          );
          if (result != null) _addProperty(result);
        },
        child: const Icon(Icons.add, color: Colors.white),
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
              onPressed: () {},
            ),
            SizedBox(width: size.width * 0.1),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CompanySettings()));
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
              'AlReyada',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: size.width * 0.04,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.bookmark_sharp, color: Colors.blue),
          SizedBox(width: 12),
          CircleAvatar(backgroundImage: AssetImage('images/personal.png')),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "House"),
            Tab(text: "Apartment"),
            Tab(text: "Office"),
            Tab(text: "Land"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: ["House", "Apartment", "Office", "Land"].map((type) {
          final filtered = properties.where((p) => p.type == type).toList();
          if (filtered.isEmpty) {
            return const Center(child: Text("No properties yet"));
          }
          return ListView.builder(
            padding: EdgeInsets.all(size.width * 0.03),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final property = filtered[index];
              final globalIndex = properties.indexOf(property);
              // --> استبدل به الـ `return Card(...)` داخل itemBuilder
              return Card(
                margin: EdgeInsets.only(bottom: size.height * 0.012),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: size.height * 0.11,
                  child: Row(
                    children: [
                      // THUMBNAIL (flexible)
                      Flexible(
                        flex: 26,
                        child: Container(
                          height: double.infinity,
                          color: Colors.grey[100],
                          child: property.imagePath.isNotEmpty
                              ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                            child: Image.file(File(property.imagePath), fit: BoxFit.cover),
                          )
                              : ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                            child: Container(
                              color: Colors.grey[200],
                              child: const Center(child: Icon(Icons.image, size: 34, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),

                      // MAIN TEXT BLOCK (flexible, responsive)
                      Flexible(
                        flex: 52,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: size.height * 0.012),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // title + type chip
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      property.title,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: size.width * 0.038),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      property.type,
                                      style: TextStyle(color: Colors.deepOrange.shade700, fontSize: size.width * 0.028, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // location single line
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: size.width * 0.032, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      property.location,
                                      style: TextStyle(color: Colors.grey[700], fontSize: size.width * 0.032),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // short description single line
                              Text(
                                property.description,
                                style: TextStyle(color: Colors.grey[800], fontSize: size.width * 0.032),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // PRICE + ACTIONS (flexible, but keep contents compact)
                      Flexible(
                        flex: 22,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // PRICE wrapped by FittedBox to prevent overflow
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "\$${property.price}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: size.width * 0.042,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // compact action buttons (mainAxisSize.min to avoid expanding)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit (constrained)
                                  SizedBox(
                                    width: size.width * 0.07,
                                    height: size.width * 0.07,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints.tightFor(width: size.width * 0.07, height: size.width * 0.07),
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: Colors.green,
                                      tooltip: 'Edit',
                                      onPressed: () async {
                                        final result = await Navigator.push<PropertyModel>(
                                          context,
                                          MaterialPageRoute(builder: (context) => EditPropertyPage(property: property)),
                                        );
                                        if (result != null) {
                                          _editProperty(globalIndex, result);
                                        }
                                      },
                                    ),
                                  ),

                                  SizedBox(width: size.width * 0.01),

                                  // Delete (constrained)
                                  SizedBox(
                                    width: size.width * 0.07,
                                    height: size.width * 0.07,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints.tightFor(width: size.width * 0.07, height: size.width * 0.07),
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: Colors.red,
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteProperty(globalIndex),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );


            },
          );
        }).toList(),
      ),
    );
  }
}
