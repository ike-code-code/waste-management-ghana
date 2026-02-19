// =============================================
// API SERVICE
// Handles all network requests
// =============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/models.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();
  
  // Get authorization header
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Request failed');
    }
  }
  
  // =============================================
  // AUTHENTICATION
  // =============================================
  
  Future<Map<String, dynamic>> register({
    required String ghanaCardNumber,
    required String fullName,
    required String phoneNumber,
    required String password,
    String? email,
    required String premisesType,
    required double gpsLatitude,
    required double gpsLongitude,
    String? preferredCollectionDays,
    int numberOfBins = 1,
    int binSizeLiters = 240,
    String? residentialArea,
    String defaultWasteType = 'domestic',
    String defaultBinType = 'regular_240l',
    int defaultBinQuantity = 1,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'ghana_card_number': ghanaCardNumber,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'password': password,
        'email': email,
        'premises_type': premisesType,
        'gps_latitude': gpsLatitude,
        'gps_longitude': gpsLongitude,
        'preferred_collection_days': preferredCollectionDays,
        'number_of_bins': numberOfBins,
        'bin_size_liters': binSizeLiters,
        'residential_area': residentialArea,
        'default_waste_type': defaultWasteType,
        'default_bin_type': defaultBinType,
        'default_bin_quantity': defaultBinQuantity,
      }),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phone_number': phoneNumber,
        'password': password,
      }),
    ).timeout(ApiConfig.timeout);
    
    final data = _handleResponse(response);
    
    // Save token and user data
    if (data['token'] != null) {
      await _storage.saveToken(data['token']);
      await _storage.saveUserData(data['user']);
    }
    
    return data;
  }
  
  Future<void> logout() async {
    await _storage.clearAll();
  }
  
  // =============================================
  // CLIENT ENDPOINTS
  // =============================================
  
  Future<Map<String, dynamic>> getClientProfile() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/clients/profile');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> updateClientProfile({
    double? gpsLatitude,
    double? gpsLongitude,
    int? numberOfBins,
    String? preferredCollectionDays,
    String? residentialArea,
    String? defaultWasteType,
    String? defaultBinType,
    int? defaultBinQuantity,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/clients/profile');
    final body = <String, dynamic>{};
    
    if (gpsLatitude != null) body['gps_latitude'] = gpsLatitude;
    if (gpsLongitude != null) body['gps_longitude'] = gpsLongitude;
    if (numberOfBins != null) body['number_of_bins'] = numberOfBins;
    if (preferredCollectionDays != null) body['preferred_collection_days'] = preferredCollectionDays;
    if (residentialArea != null) body['residential_area'] = residentialArea;
    if (defaultWasteType != null) body['default_waste_type'] = defaultWasteType;
    if (defaultBinType != null) body['default_bin_type'] = defaultBinType;
    if (defaultBinQuantity != null) body['default_bin_quantity'] = defaultBinQuantity;
    
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: json.encode(body),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<List<CollectionSchedule>> getCollectionSchedule({bool upcoming = true}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/clients/schedule?upcoming=$upcoming');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(ApiConfig.timeout);
    
    final data = _handleResponse(response);
    final schedules = (data['schedules'] as List)
        .map((json) => CollectionSchedule.fromJson(json))
        .toList();
    
    return schedules;
  }
  
  Future<Map<String, dynamic>> requestPickup(PickupRequest request) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/clients/request-pickup');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode(request.toJson()),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<List<PickupRequest>> getPickupRequests() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/clients/pickup-requests');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(ApiConfig.timeout);
    
    final data = _handleResponse(response);
    final requests = (data['requests'] as List)
        .map((json) => PickupRequest.fromJson(json))
        .toList();
    
    return requests;
  }
  
  Future<Map<String, dynamic>> confirmCollection({
    required String scheduleId,
    required bool confirmed,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/clients/confirm-collection');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'schedule_id': scheduleId,
        'confirmed': confirmed,
      }),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<List<Bill>> getBills({String? status}) async {
    var url = '${ApiConfig.baseUrl}/clients/bills';
    if (status != null) url += '?status=$status';
    
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    ).timeout(ApiConfig.timeout);
    
    final data = _handleResponse(response);
    final bills = (data['bills'] as List)
        .map((json) => Bill.fromJson(json))
        .toList();
    
    return bills;
  }
  
  // =============================================
  // COLLECTOR ENDPOINTS
  // =============================================
  
  Future<List<CollectionTask>> getCollectorTasks({required String date}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/collectors/tasks?date=$date');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(ApiConfig.timeout);
    
    final data = _handleResponse(response);
    final tasks = (data['tasks'] as List)
        .map((json) => CollectionTask.fromJson(json))
        .toList();
    
    return tasks;
  }
  
  Future<Map<String, dynamic>> submitCollectionReport(CollectionReport report) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/collectors/submit-report');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode(report.toJson()),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> syncOfflineReports(List<CollectionReport> reports) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/collectors/sync-offline-reports');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'reports': reports.map((r) => r.toJson()).toList(),
      }),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  // =============================================
  // PAYMENT ENDPOINTS
  // =============================================
  
  Future<Map<String, dynamic>> initiatePayment({
    required String billId,
    required String phoneNumber,
    required String provider, // 'mtn', 'vodafone', 'airteltigo'
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/payments/initiate');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'bill_id': billId,
        'phone_number': phoneNumber,
        'provider': provider,
      }),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/payments/status/$paymentId');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    ).timeout(ApiConfig.timeout);
    
    return _handleResponse(response);
  }
}
