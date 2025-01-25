import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_emp_profile_page.dart'; // Import the ViewEmpProfilePage

class Community extends StatefulWidget {
  const Community({super.key});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch items for all employees
  Stream<List<Map<String, dynamic>>> _fetchAllEmployeeItems() async* {
    final employeesSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();

    final List<Map<String, dynamic>> allItems = [];

    for (var employeeDoc in employeesSnapshot.docs) {
      final employeeData = employeeDoc.data();
      final employeeId = employeeDoc.id;

      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(employeeId)
          .collection('items')
          .get();

      for (var itemDoc in itemsSnapshot.docs) {
        final itemData = itemDoc.data();
        allItems.add({
          'employeeId': employeeId,
          'employeeName': employeeData['name'] ?? 'Unknown Employee',
          'employeeImg':
              employeeData['img'] ?? 'https://via.placeholder.com/150',
          'itemId': itemDoc.id,
          'itemName': itemData['name'] ?? 'Unnamed Item',
          'itemImg': itemData['image'] ?? 'https://via.placeholder.com/150',
          'itemAbout': itemData['description'] ?? 'No description provided',
          'itemRating': itemData['rating'] ?? '0',
        });
      }
    }

    yield allItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Community'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchAllEmployeeItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading items: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items found in the community!'),
            );
          }

          final items = snapshot.data!;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: () {
                  // Navigate to the ViewEmpProfilePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewEmpProfilePage(
                        employeeId: item['employeeId'], // Pass the employeeId
                      ),
                    ),
                  );
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Image (Full Width)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          item['itemImg'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item Name
                            Text(
                              item['itemName'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Item About
                            Text(
                              item['itemAbout'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Owner Information
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(item['employeeImg']),
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Owner: ${item['employeeName']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
