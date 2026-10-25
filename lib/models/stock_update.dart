import 'gas_station.dart';

class StockUpdatePayload {
  final String stationId;
  final StockStatus status;
  final QueueCondition queueCondition;
  final Map<String, bool> cylinders;
  final String? notes;
  final String userId;
  final String userDisplayName;

  StockUpdatePayload({
    required this.stationId,
    required this.status,
    required this.queueCondition,
    required this.cylinders,
    this.notes,
    required this.userId,
    required this.userDisplayName,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'status': status.toFirestoreValue(),
      'queueCondition': queueCondition.toFirestoreValue(),
      'cylinders': cylinders,
      'notes': notes,
      'lastUpdatedBy': userId,
      'reporterName': userDisplayName,
    };
  }
}
