// =============================================
// DATA MODELS
// =============================================

class User {
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String ghanaCardNumber;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.ghanaCardNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      ghanaCardNumber: json['ghana_card_number'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'ghana_card_number': ghanaCardNumber,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ClientProfile {
  final String clientId;
  final String userId;
  final String premisesType;
  final double gpsLatitude;
  final double gpsLongitude;
  final String? preferredCollectionDays;
  final int numberOfBins;
  final int binSizeLiters;
  final String? residentialArea;
  final String? defaultWasteType;
  final String? defaultBinType;
  final int defaultBinQuantity;

  ClientProfile({
    required this.clientId,
    required this.userId,
    required this.premisesType,
    required this.gpsLatitude,
    required this.gpsLongitude,
    this.preferredCollectionDays,
    required this.numberOfBins,
    required this.binSizeLiters,
    this.residentialArea,
    this.defaultWasteType,
    this.defaultBinType,
    required this.defaultBinQuantity,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      clientId: json['client_id'],
      userId: json['user_id'],
      premisesType: json['premises_type'],
      gpsLatitude: double.parse(json['gps_latitude'].toString()),
      gpsLongitude: double.parse(json['gps_longitude'].toString()),
      preferredCollectionDays: json['preferred_collection_days'],
      numberOfBins: json['number_of_bins'],
      binSizeLiters: json['bin_size_liters'],
      residentialArea: json['residential_area'],
      defaultWasteType: json['default_waste_type'],
      defaultBinType: json['default_bin_type'],
      defaultBinQuantity: json['default_bin_quantity'] ?? 1,
    );
  }
}

class CollectionSchedule {
  final String scheduleId;
  final String clientId;
  final String? collectorId;
  final String wasteType;
  final String binType;
  final int binQuantity;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String status;
  final String? collectorName;
  final String? collectorPhone;
  final String? vehicleNumber;

  CollectionSchedule({
    required this.scheduleId,
    required this.clientId,
    this.collectorId,
    required this.wasteType,
    required this.binType,
    required this.binQuantity,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.collectorName,
    this.collectorPhone,
    this.vehicleNumber,
  });

  factory CollectionSchedule.fromJson(Map<String, dynamic> json) {
    return CollectionSchedule(
      scheduleId: json['schedule_id'],
      clientId: json['client_id'],
      collectorId: json['collector_id'],
      wasteType: json['waste_type'],
      binType: json['bin_type'],
      binQuantity: json['bin_quantity'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      status: json['status'],
      collectorName: json['collector_name'],
      collectorPhone: json['collector_phone'],
      vehicleNumber: json['assigned_vehicle_number'],
    );
  }
}

class PickupRequest {
  final String? requestId;
  final String wasteType;
  final String binType;
  final int quantity;
  final String pickupType;
  final DateTime? requestedDate;
  final String? recurringFrequency;
  final String? recurringDays;
  final String? specialInstructions;
  final double? estimatedWeightKg;
  final String status;

  PickupRequest({
    this.requestId,
    required this.wasteType,
    required this.binType,
    required this.quantity,
    required this.pickupType,
    this.requestedDate,
    this.recurringFrequency,
    this.recurringDays,
    this.specialInstructions,
    this.estimatedWeightKg,
    this.status = 'pending',
  });

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    return PickupRequest(
      requestId: json['request_id'],
      wasteType: json['waste_type'],
      binType: json['bin_type'],
      quantity: json['quantity'],
      pickupType: json['pickup_type'],
      requestedDate: json['requested_date'] != null 
          ? DateTime.parse(json['requested_date']) 
          : null,
      recurringFrequency: json['recurring_frequency'],
      recurringDays: json['recurring_days'],
      specialInstructions: json['special_instructions'],
      estimatedWeightKg: json['estimated_weight_kg']?.toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waste_type': wasteType,
      'bin_type': binType,
      'quantity': quantity,
      'pickup_type': pickupType,
      'requested_date': requestedDate?.toIso8601String(),
      'recurring_frequency': recurringFrequency,
      'recurring_days': recurringDays,
      'special_instructions': specialInstructions,
      'estimated_weight_kg': estimatedWeightKg,
    };
  }
}

class Bill {
  final String billId;
  final String clientId;
  final String? reportId;
  final DateTime? billingPeriodStart;
  final DateTime? billingPeriodEnd;
  final double baseCharge;
  final double weightCharge;
  final double distanceCharge;
  final double totalAmount;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;
  
  // Additional info from collection report
  final DateTime? collectionDate;
  final double? wasteWeightKg;
  final String? wasteType;
  final String? binType;

  Bill({
    required this.billId,
    required this.clientId,
    this.reportId,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    required this.baseCharge,
    required this.weightCharge,
    required this.distanceCharge,
    required this.totalAmount,
    required this.status,
    this.dueDate,
    required this.createdAt,
    this.collectionDate,
    this.wasteWeightKg,
    this.wasteType,
    this.binType,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      billId: json['bill_id'],
      clientId: json['client_id'],
      reportId: json['report_id'],
      billingPeriodStart: json['billing_period_start'] != null
          ? DateTime.parse(json['billing_period_start'])
          : null,
      billingPeriodEnd: json['billing_period_end'] != null
          ? DateTime.parse(json['billing_period_end'])
          : null,
      baseCharge: double.parse(json['base_charge'].toString()),
      weightCharge: double.parse(json['weight_charge'].toString()),
      distanceCharge: double.parse(json['distance_charge'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      collectionDate: json['collection_date'] != null
          ? DateTime.parse(json['collection_date'])
          : null,
      wasteWeightKg: json['waste_weight_kg']?.toDouble(),
      wasteType: json['waste_type'],
      binType: json['bin_type'],
    );
  }
}

class CollectionTask {
  final String scheduleId;
  final String clientName;
  final String? clientPhone;
  final double gpsLatitude;
  final double gpsLongitude;
  final String? residentialArea;
  final String wasteType;
  final String binType;
  final int binQuantity;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String status;

  CollectionTask({
    required this.scheduleId,
    required this.clientName,
    this.clientPhone,
    required this.gpsLatitude,
    required this.gpsLongitude,
    this.residentialArea,
    required this.wasteType,
    required this.binType,
    required this.binQuantity,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
  });

  factory CollectionTask.fromJson(Map<String, dynamic> json) {
    return CollectionTask(
      scheduleId: json['schedule_id'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      gpsLatitude: double.parse(json['gps_latitude'].toString()),
      gpsLongitude: double.parse(json['gps_longitude'].toString()),
      residentialArea: json['residential_area'],
      wasteType: json['waste_type'],
      binType: json['bin_type'],
      binQuantity: json['bin_quantity'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      status: json['status'],
    );
  }
}

class CollectionReport {
  final String? reportId;
  final String scheduleId;
  final String collectorId;
  final String clientId;
  final String wasteType;
  final String binType;
  final int binQuantity;
  final DateTime collectionDate;
  final DateTime collectionTime;
  final double gpsLatitude;
  final double gpsLongitude;
  final double wasteWeightKg;
  final String? notes;
  final List<String>? photoUrls;
  final bool isOfflineSubmission;

  CollectionReport({
    this.reportId,
    required this.scheduleId,
    required this.collectorId,
    required this.clientId,
    required this.wasteType,
    required this.binType,
    required this.binQuantity,
    required this.collectionDate,
    required this.collectionTime,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.wasteWeightKg,
    this.notes,
    this.photoUrls,
    this.isOfflineSubmission = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'collector_id': collectorId,
      'client_id': clientId,
      'waste_type': wasteType,
      'bin_type': binType,
      'bin_quantity': binQuantity,
      'collection_date': collectionDate.toIso8601String().split('T')[0],
      'collection_time': collectionTime.toIso8601String(),
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'waste_weight_kg': wasteWeightKg,
      'notes': notes,
      'photo_urls': photoUrls,
      'timestamp': collectionTime.toIso8601String(),
    };
  }

  factory CollectionReport.fromJson(Map<String, dynamic> json) {
    return CollectionReport(
      reportId: json['report_id'],
      scheduleId: json['schedule_id'],
      collectorId: json['collector_id'],
      clientId: json['client_id'],
      wasteType: json['waste_type'],
      binType: json['bin_type'],
      binQuantity: json['bin_quantity'],
      collectionDate: DateTime.parse(json['collection_date']),
      collectionTime: DateTime.parse(json['collection_time']),
      gpsLatitude: double.parse(json['gps_latitude'].toString()),
      gpsLongitude: double.parse(json['gps_longitude'].toString()),
      wasteWeightKg: double.parse(json['waste_weight_kg'].toString()),
      notes: json['notes'],
      photoUrls: json['photo_urls'] != null 
          ? List<String>.from(json['photo_urls']) 
          : null,
      isOfflineSubmission: json['is_offline_submission'] ?? false,
    );
  }
}
