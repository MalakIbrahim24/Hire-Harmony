import 'package:flutter/material.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    var messageController;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: AppColors().white,
          ),
        ),
        backgroundColor: AppColors().orange,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors().white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: AppColors().orange,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What Went Wrong ?',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: AppColors().white,
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 200.0, // ارتفاع ثابت للصندوق (5-6 أسطر تقريبًا)
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors().orangelight,
                // لون خلفية الحاوية
                borderRadius: BorderRadius.circular(15.0), // زاوية منحنية
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black, // لون الظل مع شفافية
                    blurRadius: 6.0, // مدى انتشار الظل
                    offset: Offset(0, 3), // موقع الظل
                  ),
                ],
              ),
              child: TextField(
                controller: messageController,
                maxLines: 7, // عدد الأسطر المطلوب عرضه
                minLines: 1, // أقل عدد من الأسطر عند التقلص
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 10.0),
                  border: InputBorder.none, // إزالة الإطار الافتراضي
                  hintText: 'You Can Write Your Problem Here',
                  hintStyle: TextStyle(
                    color: AppColors().grey3,
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(color: Colors.black), // لون النص
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().navy,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () {
                // Handle submit action
              },
              child: Text(
                'Submit',
                style: TextStyle(
                  color: AppColors().white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
