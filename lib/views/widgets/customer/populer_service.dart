import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/employees_under_category_page.dart';

class PopulerService extends StatefulWidget {
  const PopulerService({super.key});

  @override
  State<PopulerService> createState() => _PopulerServiceState();
}

class _PopulerServiceState extends State<PopulerService> {
  Future<List<Map<String, dynamic>>> fetchTopCategoriesWithMostEmployees() async {
    final categoriesCollection = FirebaseFirestore.instance.collection('categories');

    final categoriesSnapshot = await categoriesCollection
        .orderBy('empNum', descending: true)
        .limit(5)
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
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTopCategoriesWithMostEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No popular categories found',
              style: TextStyle(color: Colors.grey),
            ));
          }

          final popularCategories = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
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
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_center, size: 50, color: AppColors().orange),
                        const SizedBox(height: 10),
                        Text(
                          categoryName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserratAlternates(
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors().navy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors().lightblue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$empNum Employees',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors().orange,
                            ),
                          ),
                        ),
                      ],
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
