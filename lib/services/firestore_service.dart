import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gas_station.dart';
import '../models/stock_update.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _stationsRef => _firestore.collection('stations');
  CollectionReference get _userUpdatesRef => _firestore.collection('user_updates');

  /// Real-time stream of all gas stations from Firestore
  Stream<List<GasStation>> streamGasStations() {
    return _stationsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => GasStation.fromFirestore(doc)).toList();
    }).handleError((error) {
      debugPrint('Firestore streaming error: $error');
      return <GasStation>[];
    });
  }

  /// Add a new real gas station to Firestore
  Future<String> addGasStation({
    required String name,
    required GasBrand brand,
    required String address,
    required String town,
    required double latitude,
    required double longitude,
    required StockStatus status,
    required QueueCondition queueCondition,
    required Map<String, bool> cylinders,
    required String userId,
    String? contactNumber,
    String? notes,
  }) async {
    final docRef = _stationsRef.doc();
    await docRef.set({
      'name': name,
      'brand': brand.shortName.toLowerCase(),
      'address': address,
      'town': town,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toFirestoreValue(),
      'queueCondition': queueCondition.toFirestoreValue(),
      'cylinders': cylinders,
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastUpdatedBy': userId,
      'reportCount': status == StockStatus.unverified ? 0 : 1,
      'notes': notes ?? '',
      'contactNumber': contactNumber ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
    });
    return docRef.id;
  }

  /// Delete a gas station from Firestore
  Future<void> deleteStation(String stationId) async {
    await _stationsRef.doc(stationId).delete();
  }

  /// Crowdsource submission to Firestore with Server Timestamp
  Future<void> updateStationStatus(StockUpdatePayload payload) async {
    final batch = _firestore.batch();
    final stationDoc = _stationsRef.doc(payload.stationId);
    final updateDoc = stationDoc.collection('updates').doc();
    final userUpdateDoc = _userUpdatesRef.doc('${payload.userId}_${payload.stationId}');

    // 1. Update station document with latest crowd data & server timestamp
    batch.update(stationDoc, {
      'status': payload.status.toFirestoreValue(),
      'queueCondition': payload.queueCondition.toFirestoreValue(),
      'cylinders': payload.cylinders,
      'notes': payload.notes ?? '',
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastUpdatedBy': payload.userId,
      'reportCount': FieldValue.increment(1),
    });

    // 2. Append to audit log / update history subcollection
    batch.set(updateDoc, {
      'stationId': payload.stationId,
      'status': payload.status.toFirestoreValue(),
      'queueCondition': payload.queueCondition.toFirestoreValue(),
      'cylinders': payload.cylinders,
      'notes': payload.notes ?? '',
      'userId': payload.userId,
      'reporterName': payload.userDisplayName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Record user last update for Firestore 30-min security rule verification
    batch.set(userUpdateDoc, {
      'userId': payload.userId,
      'stationId': payload.stationId,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Seed initial high-quality sample gas stations in Sri Lanka into Firestore
  Future<int> seedSampleStations() async {
    final samples = getInitialSampleStations();
    final batch = _firestore.batch();

    for (final station in samples) {
      final docRef = _stationsRef.doc(station.id);
      batch.set(docRef, {
        'name': station.name,
        'brand': station.brand.shortName.toLowerCase(),
        'address': station.address,
        'town': station.town,
        'latitude': station.latitude,
        'longitude': station.longitude,
        'status': station.status.toFirestoreValue(),
        'queueCondition': station.queueCondition.toFirestoreValue(),
        'cylinders': station.cylinders,
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': 'system_seed',
        'reportCount': station.reportCount,
        'notes': station.notes,
        'contactNumber': station.contactNumber,
      });
    }

    await batch.commit();
    return samples.length;
  }

  /// Curated Sri Lankan Gas Stations (Litro & Laugfs) across major towns
  static List<GasStation> getInitialSampleStations() {
    final now = DateTime.now();

    return [
      GasStation(
        id: 'station_colombo_03_litro',
        name: 'Litro Gas Point - Kollupitiya',
        brand: GasBrand.litro,
        address: '284 Galle Road, Colombo 03',
        town: 'Colombo',
        latitude: 6.9068,
        longitude: 79.8516,
        status: StockStatus.available,
        queueCondition: QueueCondition.short,
        cylinders: {'12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(minutes: 8)),
        reportCount: 38,
        contactNumber: '+94 11 257 3290',
        notes: '12.5kg domestic available. Fresh truck arrived at 4:30 PM.',
      ),
      GasStation(
        id: 'station_rajagiriya_laugfs',
        name: 'Laugfs Gas Super Station - Rajagiriya',
        brand: GasBrand.laugfs,
        address: '512 Sri Jayawardenepura Mawatha, Rajagiriya',
        town: 'Rajagiriya',
        latitude: 6.9082,
        longitude: 79.8967,
        status: StockStatus.available,
        queueCondition: QueueCondition.moderate,
        cylinders: {'12.5kg': true, '5kg': false, '2.3kg': false, '37.5kg': true},
        lastUpdated: now.subtract(const Duration(minutes: 24)),
        reportCount: 52,
        contactNumber: '+94 11 545 5600',
        notes: 'Domestic 12.5kg and commercial 37.5kg in stock. Queue moving fast.',
      ),
      GasStation(
        id: 'station_dehiwala_litro',
        name: 'Litro Gas Dealer - Dehiwala Junction',
        brand: GasBrand.litro,
        address: '148 Hill Street, Dehiwala-Mount Lavinia',
        town: 'Dehiwala',
        latitude: 6.8524,
        longitude: 79.8665,
        status: StockStatus.outOfStock,
        queueCondition: QueueCondition.long,
        cylinders: {'12.5kg': false, '5kg': false, '2.3kg': false, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(minutes: 42)),
        reportCount: 19,
        contactNumber: '+94 11 271 4455',
        notes: 'Sold out by 3 PM. Next delivery expected tomorrow morning.',
      ),
      GasStation(
        id: 'station_nugegoda_laugfs',
        name: 'Laugfs Express Depot - Nugegoda',
        brand: GasBrand.laugfs,
        address: '76 High Level Road, Nugegoda',
        town: 'Nugegoda',
        latitude: 6.8722,
        longitude: 79.8920,
        status: StockStatus.available,
        queueCondition: QueueCondition.short,
        cylinders: {'12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(minutes: 15)),
        reportCount: 64,
        contactNumber: '+94 11 282 3411',
        notes: 'Ample 5kg and 12.5kg cylinders. No line currently.',
      ),
      GasStation(
        id: 'station_kandy_litro',
        name: 'Litro Gas Central Hub - Kandy City',
        brand: GasBrand.litro,
        address: '42 William Gopallawa Mawatha, Kandy',
        town: 'Kandy',
        latitude: 7.2906,
        longitude: 80.6337,
        status: StockStatus.available,
        queueCondition: QueueCondition.moderate,
        cylinders: {'12.5kg': true, '5kg': true, '2.3kg': false, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(minutes: 19)),
        reportCount: 41,
        contactNumber: '+94 81 222 7890',
        notes: 'Token system active. Around 20 people waiting.',
      ),
      GasStation(
        id: 'station_gampaha_laugfs',
        name: 'Laugfs Gas Distributor - Gampaha',
        brand: GasBrand.laugfs,
        address: '19 Miriswatta Road, Gampaha',
        town: 'Gampaha',
        latitude: 7.0873,
        longitude: 79.9945,
        status: StockStatus.unverified,
        queueCondition: QueueCondition.short,
        cylinders: {'12.5kg': false, '5kg': false, '2.3kg': false, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(hours: 4)),
        reportCount: 7,
        contactNumber: '+94 33 222 1450',
        notes: 'Awaiting distributor confirmation. Please verify if visiting.',
      ),
      GasStation(
        id: 'station_negombo_litro',
        name: 'Litro Gas coastal Center - Negombo',
        brand: GasBrand.litro,
        address: '89 Colombo Road, Negombo',
        town: 'Negombo',
        latitude: 7.2008,
        longitude: 79.8736,
        status: StockStatus.available,
        queueCondition: QueueCondition.short,
        cylinders: {'12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': true},
        lastUpdated: now.subtract(const Duration(minutes: 32)),
        reportCount: 30,
        contactNumber: '+94 31 223 4567',
        notes: 'Full stock across all cylinder types.',
      ),
      GasStation(
        id: 'station_galle_litro',
        name: 'Litro Gas Outlet - Galle Fort Entrance',
        brand: GasBrand.litro,
        address: '110 Main Street, Galle',
        town: 'Galle',
        latitude: 6.0535,
        longitude: 80.2210,
        status: StockStatus.available,
        queueCondition: QueueCondition.moderate,
        cylinders: {'12.5kg': true, '5kg': false, '2.3kg': false, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(minutes: 50)),
        reportCount: 22,
        contactNumber: '+94 91 224 8900',
        notes: '12.5kg cylinders available. Limit 1 per household.',
      ),
      GasStation(
        id: 'station_battaramulla_laugfs',
        name: 'Laugfs Gas Service Hub - Battaramulla',
        brand: GasBrand.laugfs,
        address: '320 Pannipitiya Road, Battaramulla',
        town: 'Battaramulla',
        latitude: 6.8997,
        longitude: 79.9234,
        status: StockStatus.available,
        queueCondition: QueueCondition.short,
        cylinders: {'12.5kg': true, '5kg': true, '2.3kg': true, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(minutes: 12)),
        reportCount: 75,
        contactNumber: '+94 11 288 9200',
        notes: 'Well organized drive-through pickup. Quick queue.',
      ),
      GasStation(
        id: 'station_kurunegala_litro',
        name: 'Litro Gas Distribution Point - Kurunegala',
        brand: GasBrand.litro,
        address: '55 Dambulla Road, Kurunegala',
        town: 'Kurunegala',
        latitude: 7.4863,
        longitude: 80.3623,
        status: StockStatus.outOfStock,
        queueCondition: QueueCondition.short,
        cylinders: {'12.5kg': false, '5kg': false, '2.3kg': false, '37.5kg': false},
        lastUpdated: now.subtract(const Duration(hours: 1, minutes: 10)),
        reportCount: 14,
        contactNumber: '+94 37 222 3456',
        notes: 'Delivery expected by 7 PM today.',
      ),
    ];
  }
}
