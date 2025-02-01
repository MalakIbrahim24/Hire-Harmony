import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';

class EmployeesUnderCategoryPage extends StatelessWidget {
  final String categoryName; // اسم الفئة وليس الـ ID

  const EmployeesUnderCategoryPage({required this.categoryName, super.key});

  Future<List<Map<String, dynamic>>> fetchEmployeesByCategory(String categoryName) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // 🔹 1. البحث عن مستند `category` باستخدام `name`
      QuerySnapshot categorySnapshot = await firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (categorySnapshot.docs.isEmpty) {
        print("⚠ No category found with name: $categoryName");
        return [];
      }

      DocumentSnapshot categoryDoc = categorySnapshot.docs.first;
      List<dynamic> workerIds = categoryDoc['workers'] ?? []; // 🔹 جلب الـ `workers`

      if (workerIds.isEmpty) {
        print("⚠ No workers found for category: $categoryName");
        return [];
      }

      // 🔹 2. جلب بيانات المستخدمين بناءً على قائمة `workers`
      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: workerIds) // 🔹 جلب المستخدمين من القائمة
          .get();

      List<Map<String, dynamic>> employees = usersSnapshot.docs
          .map((userDoc) => {
                'uid': userDoc.id,
                ...userDoc.data() as Map<String, dynamic>,
              })
          .toList();

      print("✅ Found ${employees.length} employees for category: $categoryName");

      return employees;
    } catch (e) {
      print("❌ Error fetching employees: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Employees for $categoryName',
          style: GoogleFonts.montserratAlternates(
            color: AppColors().white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors().white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors().orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchEmployeesByCategory(categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final employees = snapshot.data;
          if (employees == null || employees.isEmpty) {
            return const Center(
              child: Text('No employees found for this category'),
            );
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final employeeName = employee['name'] ?? 'Unknown Employee';
              final employeeEmail = employee['email'] ?? 'No Email';
              final employeeImg = employee['img'] ?? '';
              final employeeId = employee['uid'];

              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 12.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: employeeImg.isNotEmpty
                            ? NetworkImage(employeeImg)
                            : null,
                        backgroundColor: AppColors().navy,
                        child: employeeImg.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: GoogleFonts.montserratAlternates(
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppColors().navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: $employeeEmail',
                              style: GoogleFonts.montserratAlternates(
                                textStyle: TextStyle(
                                  fontSize: 10,
                                  color: AppColors().grey2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          if (employeeId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewEmpProfilePage(
                                  employeeId: employeeId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.montserratAlternates(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: AppColors().white,
                            ),
                          ),
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
