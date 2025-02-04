
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade900,
    primary: AppColors().white,
    inversePrimary: Colors.grey.shade300,
    secondary: Colors.grey.shade700,
    tertiary: Colors.grey.shade800,
        error: AppColors().red, // لون الأخطاء
            onPrimary: AppColors().grey3, // لون النص على العناصر الأساسية

    onSecondary: AppColors().greylight, 
   // لون النص على العناصر الثانوية
  ),
  /*textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white), // النص الأساسي
    bodyMedium: TextStyle(color: Colors.white70), // النص الثانوي
    displayLarge: TextStyle(color: Colors.white), // العناوين الكبيرة
    displayMedium: TextStyle(color: Colors.white70), // العناوين المتوسطة
    displaySmall: TextStyle(color: Colors.white70), // العناوين الصغيرة
    bodySmall: TextStyle(color: Colors.white60), // النصوص التوضيحية
    labelLarge: TextStyle(color: Colors.white), // نص الأزرار
  ),*/
    textTheme: GoogleFonts.montserratAlternatesTextTheme(), // ✅ ضبط الخط

);
