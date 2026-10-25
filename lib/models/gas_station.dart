import 'package:cloud_firestore/cloud_firestore.dart';

enum GasBrand {
  litro,
  laugfs;

  String get displayName => this == GasBrand.litro ? 'Litro Gas' : 'Laugfs Gas';
  String get shortName => this == GasBrand.litro ? 'Litro' : 'Laugfs';

  static GasBrand fromString(String? value) {
    if (value?.toLowerCase() == 'laugfs') return GasBrand.laugfs;
    return GasBrand.litro;
  }
}

enum StockStatus {
  available,
  outOfStock,
  unverified;

  String get displayName {
    switch (this) {
      case StockStatus.available:
        return 'In Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.unverified:
        return 'Unverified';
    }
  }

  static StockStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'available':
      case 'in_stock':
        return StockStatus.available;
      case 'outofstock':
      case 'out_of_stock':
        return StockStatus.outOfStock;
      default:
        return StockStatus.unverified;
    }
  }

  String toFirestoreValue() {
    switch (this) {
      case StockStatus.available:
        return 'available';
      case StockStatus.outOfStock:
        return 'outOfStock';
      case StockStatus.unverified:
        return 'unverified';
    }
  }
}

enum QueueCondition {
  short,
  moderate,
  long;

  String get displayName {
    switch (this) {
      case QueueCondition.short:
        return 'Short (< 15 mins)';
      case QueueCondition.moderate:
        return 'Moderate (15-45 mins)';
      case QueueCondition.long:
        return 'Long (> 45 mins)';
    }
  }

  static QueueCondition fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'short':
        return QueueCondition.short;
      case 'moderate':
      case 'medium':
        return QueueCondition.moderate;
      case 'long':
        return QueueCondition.long;
      default:
        return QueueCondition.moderate;
    }
  }

  String toFirestoreValue() {
    switch (this) {
      case QueueCondition.short:
        return 'short';
      case QueueCondition.moderate:
        return 'moderate';
      case QueueCondition.long:
        return 'long';
    }
  }
}

class GasStation {
  final String id;
  final String name;
  final GasBrand brand;
  final String address;
  final String town;
  final double latitude;
  final double longitude;
  final StockStatus status;
  final QueueCondition queueCondition;
  final Map<String, bool> cylinders;
  final DateTime lastUpdated;
  final String? lastUpdatedBy;
  final int reportCount;
  final String? notes;
  final String? contactNumber;

  GasStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.town,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.queueCondition,
    required this.cylinders,
    required this.lastUpdated,
    this.lastUpdatedBy,
    this.reportCount = 0,
    this.notes,
    this.contactNumber,
  });

  bool get isLitro => brand == GasBrand.litro;
  bool get isLaugfs => brand == GasBrand.laugfs;
  bool get isAvailable => status == StockStatus.available;
  bool get isOutOfStock => status == StockStatus.outOfStock;
  bool get isUnverified => status == StockStatus.unverified;

  factory GasStation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime updatedDate = DateTime.now();
    final rawTimestamp = data['lastUpdated'];
    if (rawTimestamp is Timestamp) {
      updatedDate = rawTimestamp.toDate();
    } else if (rawTimestamp is int) {
      updatedDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      updatedDate = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    Map<String, bool> cylindersMap = {
      '12.5kg': true,
      '5kg': true,
      '2.3kg': false,
      '37.5kg': false,
    };
    if (data['cylinders'] is Map) {
      final rawCylinders = data['cylinders'] as Map;
      cylindersMap = rawCylinders.map((k, v) => MapEntry(k.toString(), v == true));
    }

    return GasStation(
      id: doc.id,
      name: data['name'] ?? 'Gas Station',
      brand: GasBrand.fromString(data['brand']),
      address: data['address'] ?? '',
      town: data['town'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 79.8612,
      status: StockStatus.fromString(data['status']),
      queueCondition: QueueCondition.fromString(data['queueCondition']),
      cylinders: cylindersMap,
      lastUpdated: updatedDate,
      lastUpdatedBy: data['lastUpdatedBy'] as String?,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      notes: data['notes'] as String?,
      contactNumber: data['contactNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand.shortName.toLowerCase(),
      'address': address,
      'town': town,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toFirestoreValue(),
      'queueCondition': queueCondition.toFirestoreValue(),
      'cylinders': cylinders,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastUpdatedBy': lastUpdatedBy,
      'reportCount': reportCount,
      'notes': notes,
      'contactNumber': contactNumber,
    };
  }

  GasStation copyWith({
    String? id,
    String? name,
    GasBrand? brand,
    String? address,
    String? town,
    double? latitude,
    double? longitude,
    StockStatus? status,
    QueueCondition? queueCondition,
    Map<String, bool>? cylinders,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
    int? reportCount,
    String? notes,
    String? contactNumber,
  }) {
    return GasStation(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      address: address ?? this.address,
      town: town ?? this.town,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      queueCondition: queueCondition ?? this.queueCondition,
      cylinders: cylinders ?? this.cylinders,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      reportCount: reportCount ?? this.reportCount,
      notes: notes ?? this.notes,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }
}
