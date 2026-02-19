// =============================================
// APP CONSTANTS AND CONFIGURATION
// =============================================

import 'package:flutter/material.dart';

// API Configuration
class ApiConfig {
  // IMPORTANT: Change this to your backend URL
  // For Android emulator: http://10.0.2.2:3000/api
  // For iOS simulator: http://localhost:3000/api
  // For real device: http://YOUR_COMPUTER_IP:3000/api
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  static const Duration timeout = Duration(seconds: 30);
}

// Ghana Flag Colors
class AppColors {
  static const Color red = Color(0xFFCE1126);      // Ghana Red
  static const Color gold = Color(0xFFFCD116);     // Ghana Gold
  static const Color green = Color(0xFF006C42);    // Ghana Green
  static const Color black = Color(0xFF000000);    // Black
  static const Color white = Color(0xFFFFFFFF);    // White
  static const Color gray = Color(0xFF757575);     // Gray
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color background = Color(0xFFF5F5F5);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.black,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.gray,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

// App Dimensions
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double buttonHeight = 48.0;
  static const double borderRadius = 8.0;
  
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
}

// Waste Types
class WasteType {
  static const String domestic = 'domestic';
  static const String plastics = 'plastics';
  static const String papers = 'papers';
  
  static const Map<String, String> labels = {
    domestic: 'Domestic Waste',
    plastics: 'Plastics',
    papers: 'Papers',
  };
  
  static const Map<String, IconData> icons = {
    domestic: Icons.delete,
    plastics: Icons.recycling,
    papers: Icons.description,
  };
  
  static const Map<String, Color> colors = {
    domestic: AppColors.gray,
    plastics: Colors.blue,
    papers: Colors.brown,
  };
}

// Bin Types
class BinType {
  static const String regular240L = 'regular_240l';
  static const String dumpster1100L = 'dumpster_1100l';
  static const String wasteBag = 'waste_bag';
  
  static const Map<String, String> labels = {
    regular240L: 'Regular Bin (240L)',
    dumpster1100L: 'Dumpster (1100L)',
    wasteBag: 'Waste Bag',
  };
  
  static const Map<String, IconData> icons = {
    regular240L: Icons.delete_outline,
    dumpster1100L: Icons.inventory_2,
    wasteBag: Icons.shopping_bag,
  };
}

// Collection Status
class CollectionStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String missed = 'missed';
  static const String rescheduled = 'rescheduled';
  
  static const Map<String, Color> colors = {
    pending: AppColors.gold,
    completed: AppColors.green,
    missed: AppColors.red,
    rescheduled: Colors.orange,
  };
}

// Bill Status
class BillStatus {
  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String overdue = 'overdue';
  
  static const Map<String, Color> colors = {
    pending: AppColors.gold,
    paid: AppColors.green,
    overdue: AppColors.red,
  };
}

// Validation
class Validators {
  static String? validateGhanaCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ghana Card number is required';
    }
    
    final regex = RegExp(r'^GHA-[0-9]{9}-[0-9]$');
    if (!regex.hasMatch(value)) {
      return 'Invalid Ghana Card format (GHA-XXXXXXXXX-X)';
    }
    
    return null;
  }
  
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final regex = RegExp(r'^(\+233|0)[0-9]{9}$');
    if (!regex.hasMatch(value)) {
      return 'Invalid phone number format';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'Invalid email format';
    }
    
    return null;
  }
}

// Date Formatting
class DateFormatter {
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }
  
  static String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  static String formatCurrency(double amount) {
    return 'GHS ${amount.toStringAsFixed(2)}';
  }
}

// Storage Keys
class StorageKeys {
  static const String token = 'auth_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userData = 'user_data';
  static const String offlineReports = 'offline_reports';
}

// User Roles
class UserRole {
  static const String client = 'client';
  static const String collector = 'collector';
  static const String admin = 'admin';
  static const String supervisor = 'supervisor';
}
