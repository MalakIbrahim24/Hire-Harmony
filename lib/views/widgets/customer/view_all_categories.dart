import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/employees_under_category_page.dart';

class ViewAllCategoriesPage extends StatefulWidget {
  const ViewAllCategoriesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ViewAllCategoriesPageState createState() => _ViewAllCategoriesPageState();
}

class _ViewAllCategoriesPageState extends State<ViewAllCategoriesPage> {
  String searchQuery = ''; // Holds the search query
  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> filteredCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors().orange,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors().white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'All categories',
                      style: GoogleFonts.montserratAlternates(
                        color: AppColors().white,
                        //fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer for symmetry
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                  filteredCategories = allCategories
                      .where((category) => (category['data']['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: Icon(Icons.search, color: AppColors().grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors().white,
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.instance.getCategories(limit: 1000),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No categories found'));
                }

                // Store all categories and apply filter
                if (allCategories.isEmpty) {
                  allCategories = snapshot.data!;
                  filteredCategories = allCategories;
                }

                return ListView.builder(
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index]['data']
                        as Map<String, dynamic>;
                    final categoryId = filteredCategories[index]['id'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors().white,
                          border: Border.all(
                            // ignore: deprecated_member_use
                            color: AppColors().grey.withOpacity(0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            category['name'] ?? 'Unknown Name',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: AppColors().navy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            // Navigate to the employees page with the selected category ID
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmployeesUnderCategoryPage(
                                  categoryName: category[
                                      'name'], // تمرير اسم الفئة الصحيح
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
