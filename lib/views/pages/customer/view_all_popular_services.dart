import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hire_harmony/views/pages/customer/employees_under_category_page.dart';

class ViewAllPopularServicesPage extends StatelessWidget {
  const ViewAllPopularServicesPage({super.key});

  Future<List<Map<String, dynamic>>> fetchTopCategoriesWithMostEmployees() async {
    final categoriesCollection = FirebaseFirestore.instance.collection('categories');

    final categoriesSnapshot = await categoriesCollection
        .orderBy('empNum', descending: true) // ترتيب تنازلي حسب عدد الموظفين
        .limit(5) // جلب فقط أعلى 5 كاتيجوري
        .get();

    final topCategories = <Map<String, dynamic>>[];

    for (final categoryDoc in categoriesSnapshot.docs) {
      final categoryData = categoryDoc.data();
      final categoryId = categoryDoc.id;

      topCategories.add({
        'id': categoryId,
        'name': categoryData['name'] ?? 'Unknown Category',
        'empNum': categoryData['empNum'] ?? 0,
      });
    }

    return topCategories;
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      'Popular Categories',
                      style: GoogleFonts.montserratAlternates(
                        color: AppColors().white,
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTopCategoriesWithMostEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No popular categories found'),
            );
          }

          final popularCategories = snapshot.data!;
          return ListView.builder(
            itemCount: popularCategories.length,
            itemBuilder: (context, index) {
              final category = popularCategories[index];
              final categoryName = category['name'] ?? 'Unknown Category';
              final empNum = category['empNum'] ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeesUnderCategoryPage(
                        categoryName: categoryName, // تمرير اسم الفئة
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: AppColors().white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors().orange),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.category, size: 40, color: AppColors().orange),
                    title: Text(
                      categoryName,
                      style: GoogleFonts.montserratAlternates(
                        textStyle: TextStyle(
                          fontSize: 18,
                          color: AppColors().navy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      '$empNum Employees',
                      style: GoogleFonts.montserratAlternates(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors().grey2,
                        ),
                      ),
                    ),
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
