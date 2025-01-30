import 'package:flutter/material.dart';
import 'package:hire_harmony/utils/dark_mode.dart';
import 'package:hire_harmony/utils/light_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier{
  ThemeData _themeData = lightMode;
  ThemeData get themeData => _themeData;
  bool get isDarkMode =>_themeData==darkMode;
  set themeData(ThemeData themeData){
    _themeData =themeData;
    notifyListeners();
  }
  void toggleTheme(){
    if(_themeData == lightMode){
      themeData=darkMode;

    }else{
      themeData=lightMode;
    }
  }
  
  void setLightMode() {
  themeData = lightMode;
}
/// استعادة الثيم المخزن بعد تسجيل الخروج
  Future<void> resetTheme() async {
    await _loadTheme();
  }
  // تحميل الثيم من SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeData = isDarkMode ? darkMode : lightMode;
    notifyListeners();
  }
   // حفظ الثيم في SharedPreferences
  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }
}