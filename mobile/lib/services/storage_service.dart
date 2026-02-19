// =============================================
// STORAGE SERVICE
// Local data persistence
// =============================================

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class StorageService {
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.token, token);
  }
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.token);
  }
  
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userData, json.encode(userData));
    await prefs.setString(StorageKeys.userId, userData['user_id']);
    await prefs.setString(StorageKeys.userRole, userData['role']);
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString(StorageKeys.userData);
    if (userDataStr != null) {
      return json.decode(userDataStr);
    }
    return null;
  }
  
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.userRole);
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
  
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  // Offline reports storage
  Future<void> saveOfflineReport(Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();
    final reportsStr = prefs.getString(StorageKeys.offlineReports) ?? '[]';
    final reports = json.decode(reportsStr) as List;
    reports.add(report);
    await prefs.setString(StorageKeys.offlineReports, json.encode(reports));
  }
  
  Future<List<Map<String, dynamic>>> getOfflineReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsStr = prefs.getString(StorageKeys.offlineReports) ?? '[]';
    final reports = json.decode(reportsStr) as List;
    return reports.cast<Map<String, dynamic>>();
  }
  
  Future<void> clearOfflineReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.offlineReports, '[]');
  }
}
