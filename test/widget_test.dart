import 'package:flutter_test/flutter_test.dart';
import 'package:gas_tracker/models/gas_station.dart';

void main() {
  test('GasStation model parses sample data and calculates availability correctly', () {
    final now = DateTime.now();
    final station = GasStation(
      id: 'test_litro_01',
      name: 'Test Litro Station',
      brand: GasBrand.litro,
      address: 'Test Road, Colombo',
      town: 'Colombo',
      latitude: 6.9271,
      longitude: 79.8612,
      status: StockStatus.available,
      queueCondition: QueueCondition.short,
      cylinders: {'12.5kg': true, '5kg': true},
      lastUpdated: now,
    );

    expect(station.isLitro, isTrue);
    expect(station.isLaugfs, isFalse);
    expect(station.isAvailable, isTrue);
    expect(station.status.displayName, 'In Stock');
    expect(station.queueCondition.displayName, 'Short (< 15 mins)');
  });
}
