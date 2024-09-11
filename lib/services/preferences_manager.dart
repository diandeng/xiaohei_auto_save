import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  // 获取备份路径
  static Future<String?> getBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backupPath');
  }

  // 获取考生文件件路径
  static Future<String?> getOriginPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('originPath');
  }

  // 保存备份路径
  static Future<void> setBackupPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('backupPath', path);
  }

  // 保存考生文件夹路径
  static Future<void> setOriginPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('originPath', path);
  }

  // 重置路径
  static Future<void> resetPaths() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('backupPath');
    prefs.remove('originPath');
  }

  // 获取主题颜色
  static Future<Color?> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorInt = prefs.getInt('themeColor');
    return colorInt != null ? Color(colorInt) : null;
  }

  // 保存主题颜色
  static Future<void> setThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeColor', color.value);
  }
}