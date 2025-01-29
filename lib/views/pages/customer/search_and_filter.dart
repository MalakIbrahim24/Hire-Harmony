import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';

class SearchAndFilter extends StatefulWidget {
  const SearchAndFilter({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchAndFilterState createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<SearchAndFilter> {
  String searchQuery = ''; // Holds the current search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors().grey3, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors().grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value.trim().toLowerCase();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Search for employees",
                                hintStyle: GoogleFonts.montserratAlternates(
                                  textStyle: TextStyle(
                                    fontSize: 13,
                                    color: AppColors().grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                            child: SizedBox(
                              width: 20,
                              height: 25,
                              child: Center(
                                child: Text(
                                  "x",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.instance.collectionStream(
          path: 'users',
          builder: (data, documentId) => {
            'id': documentId,
            'name': data['name'] ?? 'Unnamed',
            'email': data['email'] ?? 'No email',
            'img': data['img'] ?? '',
            'role': data['role'] ?? '',
            'availability': data['availability'] ?? 'Unavailable',
            'location': data['location'].toString() ?? 'Unknown',
            'rating': data['rating'] ?? 0,
            'reviewsNum': data['reviewsNum'] ?? 0,
          },
          queryBuilder: (query) => query.where('role', isEqualTo: 'employee'),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.montserratAlternates(
                  color: AppColors().navy,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No employees found',
                style: GoogleFonts.montserratAlternates(
                  color: AppColors().navy,
                ),
              ),
            );
          }

          // Filter employees based on the search query
          final employees = snapshot.data!
              .where((employee) => employee['name']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery))
              .toList();

          if (employees.isEmpty) {
            return Center(
              child: Text(
                'No employees found with this name',
                style: GoogleFonts.montserratAlternates(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors().navy,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];

              return Card(
                color: Theme.of(context).colorScheme.surface,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: employee['img'] != null
                                    ? NetworkImage(employee['img'])
                                    : const NetworkImage(
                                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                                backgroundColor: AppColors().grey,
                                child: employee['img'] == null
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                employee['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                             Text(
  '${employee['rating']?.toString() ?? '0.0'} (${employee['reviewsNum']?.toString() ?? '0'}) reviews',
  style: TextStyle(
    fontSize: 13,
    color: Theme.of(context).colorScheme.primary,
  ),
),

                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 8),
                          Text(employee['location'] ?? 'Unknown location',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status: ${employee['availability'] == true ? 'Available' : 'Not Available'}',
                            style: TextStyle(
                              color: employee['availability'] == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors().orange,
                            ),
                            onPressed: () {
                              if (employee['id'] != null &&
                                  employee['id'] is String) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewEmpProfilePage(
                                      employeeId: employee[
                                          'id'], // Pass the employee ID
                                    ),
                                  ),
                                );
                              } else {
                                // Show a dialog or message indicating that the ID is missing
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Employee ID is missing or invalid')),
                                );
                              }
                            },
                            child: const Text(
                              'View Profile',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
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
