import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/employees_under_category_page.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({super.key});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  Stream<List<Map<String, dynamic>>> categoryStream =
      FirestoreService.instance.getCategories(limit: 10);

  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: categoryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          final categories = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category =
                  categories[index]['data'] as Map<String, dynamic>;
              final categoryTitle = category['name'] ?? 'Unknown Title';
              final categoryId = categories[index]['id']; // استخراج categoryId

              return InkWell(
                onTap: () {
                  // التنقل إلى صفحة العاملين مع تمرير categoryId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeesUnderCategoryPage(
                        categoryName:
                            category['name'], // تمرير اسم الفئة الصحيح
                      ),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  width: 160, // زيادة العرض قليلاً لتحسين تناسق النصوص
                  decoration: BoxDecoration(
                    color: AppColors().white,
                    borderRadius:
                        BorderRadius.circular(16), // جعل الحواف أكثر نعومة

                    boxShadow: [
                      BoxShadow(
                        color: AppColors().navy.withAlpha(150), // إضافة ظل خفيف
                        blurRadius: 6, // تقليل التمويه لإبقاء الظل ناعمًا
                        offset: const Offset(0, 4), // تحديد اتجاه الظل
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      categoryTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          fontSize: 13, // زيادة حجم النص قليلاً
                          color: AppColors().navy,
                          fontWeight: FontWeight.w600, // جعل النص أكثر سماكة
                          letterSpacing:
                              0.5, // إضافة مسافة بين الحروف لتحسين القراءة
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
