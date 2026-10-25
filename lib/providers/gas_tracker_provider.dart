import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_theme.dart';
import '../models/gas_station.dart';
import '../models/stock_update.dart';
import '../services/cooldown_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/marker_generator.dart';

class GasTrackerProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CooldownService _cooldownService = CooldownService();
  final NotificationService _notificationService = NotificationService();

  List<GasStation> _allStations = [];
  bool _isLoading = true;
  String? _error;

  GasBrand? _selectedBrand;
  StockStatus? _selectedStatus;
  String _searchQuery = '';

  GasStation? _selectedStation;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  GoogleMapController? _mapController;
  LatLng _currentMapCenter = const LatLng(6.9271, 79.8612);

  // User GPS Location & 4 KM radius tracking
  Position? _userPosition;
  final Map<String, StockStatus> _previousStatuses = {};

  // Anti-Spam: remaining cooldown durations per stationId
  final Map<String, Duration> _remainingCooldowns = {};
  Timer? _cooldownTicker;
  StreamSubscription<List<GasStation>>? _stationsSubscription;

  // Callback when marker is tapped
  void Function(GasStation)? onStationSelected;

  GasTrackerProvider() {
    _init();
  }

  List<GasStation> get allStations => _allStations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GasBrand? get selectedBrand => _selectedBrand;
  StockStatus? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  GasStation? get selectedStation => _selectedStation;
  Set<Marker> get markers => _markers;
  Set<Circle> get circles => _circles;
  GoogleMapController? get mapController => _mapController;
  LatLng get currentMapCenter => _currentMapCenter;
  Position? get userPosition => _userPosition;
  LatLng? get userLocation => _userPosition != null ? LatLng(_userPosition!.latitude, _userPosition!.longitude) : null;

  void updateMapCenter(LatLng center) {
    _currentMapCenter = center;
  }

  List<GasStation> get filteredStations {
    return _allStations.where((station) {
      if (_selectedBrand != null && station.brand != _selectedBrand) {
        return false;
      }
      if (_selectedStatus != null && station.status != _selectedStatus) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchesTown = station.town.toLowerCase().contains(query);
        final matchesName = station.name.toLowerCase().contains(query);
        final matchesAddress = station.address.toLowerCase().contains(query);
        if (!matchesTown && !matchesName && !matchesAddress) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _init() async {
    // 1. Initialize Local Notifications Plugin
    await _notificationService.initialize();

    // 2. Preload custom vector markers for smooth rendering
    await MarkerGenerator.preloadMarkers();

    // 3. Request user location and draw 4 KM proximity circle
    requestLocationAndCenter();

    // 4. Listen to real-time snapshots from Firestore
    _stationsSubscription = _firestoreService.streamGasStations().listen(
      (stations) {
        _check4KmProximityAlerts(stations);
        _allStations = stations;
        _isLoading = false;
        _updateMarkers();
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    // 5. Start 1-second interval ticker for live anti-spam cooldown counter
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCooldowns();
    });
  }

  /// Request GPS Location, center map, and create 4 KM proximity circle
  Future<void> requestLocationAndCenter() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        _userPosition = pos;
        _updateCircles();
        notifyListeners();

        // Animate camera to user's real GPS coordinates
        await moveToLocation(pos.latitude, pos.longitude, zoom: 14.5);
      }
    } catch (e) {
      debugPrint('Location request error: $e');
    }
  }

  void _updateCircles() {
    if (_userPosition == null) return;
    _circles = {
      Circle(
        circleId: const CircleId('user_4km_proximity_circle'),
        center: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        radius: 4000, // 4,000 meters = 4 KM radius
        strokeWidth: 2,
        strokeColor: AppColors.primary.withValues(alpha: 0.65),
        fillColor: AppColors.primary.withValues(alpha: 0.08),
      ),
    };
  }

  /// Check if newly arrived gas is within 4 KM of user's GPS
  void _check4KmProximityAlerts(List<GasStation> updatedStations) {
    for (final station in updatedStations) {
      final oldStatus = _previousStatuses[station.id];

      // Detect status change to In Stock
      if (station.status == StockStatus.available && oldStatus != StockStatus.available) {
        if (_userPosition != null) {
          final distanceMeters = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            station.latitude,
            station.longitude,
          );

          if (distanceMeters <= 4000) {
            final distanceKm = distanceMeters / 1000;
            _notificationService.showGasArrivalAlert(
              title: '🔥 Gas Available Near You (Within 4 KM)!',
              body: '${station.name} (${station.brand.displayName}) has gas in stock (${distanceKm.toStringAsFixed(1)} km away)!',
              payload: station.id,
            );
          }
        }
      }
      _previousStatuses[station.id] = station.status;
    }
  }

  void _tickCooldowns() {
    if (_remainingCooldowns.isEmpty) return;

    bool changed = false;
    final keys = List<String>.from(_remainingCooldowns.keys);
    for (final id in keys) {
      final current = _remainingCooldowns[id]!;
      if (current.inSeconds <= 1) {
        _remainingCooldowns.remove(id);
        changed = true;
      } else {
        _remainingCooldowns[id] = current - const Duration(seconds: 1);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<Duration> checkUserCooldown(String stationId, String userId) async {
    final remaining = await _cooldownService.getRemainingCooldown(stationId, userId);
    if (remaining > Duration.zero) {
      _remainingCooldowns[stationId] = remaining;
      notifyListeners();
    } else {
      _remainingCooldowns.remove(stationId);
    }
    return remaining;
  }

  Duration getRemainingCooldown(String stationId) {
    return _remainingCooldowns[stationId] ?? Duration.zero;
  }

  bool isStationInCooldown(String stationId) {
    final rem = getRemainingCooldown(stationId);
    return rem.inSeconds > 0;
  }

  void setBrandFilter(GasBrand? brand) {
    _selectedBrand = brand;
    _updateMarkers();
    notifyListeners();
  }

  void setStatusFilter(StockStatus? status) {
    _selectedStatus = status;
    _updateMarkers();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _updateMarkers();
    notifyListeners();
  }

  void selectStation(GasStation? station) {
    _selectedStation = station;
    notifyListeners();
    if (station != null && _mapController != null) {
      try {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(station.latitude, station.longitude),
              zoom: 15.5,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Camera animation ignored: $e');
      }
    }
  }

  Future<void> moveToLocation(double latitude, double longitude, {double zoom = 14.5}) async {
    if (_mapController != null) {
      try {
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: zoom,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Camera animation ignored: $e');
      }
    }
  }

  Future<void> _updateMarkers() async {
    final currentList = filteredStations;
    final Set<Marker> newMarkers = {};

    for (final station in currentList) {
      final icon = await MarkerGenerator.getMarker(station.brand, station.status);

      newMarkers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.brand.displayName} • ${station.status.displayName}',
          ),
          onTap: () {
            selectStation(station);
            if (onStationSelected != null) {
              onStationSelected!(station);
            }
          },
        ),
      );
    }

    _markers = newMarkers;
    notifyListeners();
  }

  Future<bool> submitStockUpdate(StockUpdatePayload payload) async {
    try {
      final canUpdate = await _cooldownService.canUserUpdate(payload.stationId, payload.userId);
      if (!canUpdate) {
        final remaining = await _cooldownService.getRemainingCooldown(payload.stationId, payload.userId);
        _remainingCooldowns[payload.stationId] = remaining;
        notifyListeners();
        return false;
      }

      await _firestoreService.updateStationStatus(payload);
      await _cooldownService.recordUpdate(payload.stationId, payload.userId);
      _remainingCooldowns[payload.stationId] = const Duration(minutes: 30);

      final index = _allStations.indexWhere((s) => s.id == payload.stationId);
      if (index != -1) {
        final existing = _allStations[index];
        _allStations[index] = existing.copyWith(
          status: payload.status,
          queueCondition: payload.queueCondition,
          cylinders: payload.cylinders,
          lastUpdated: DateTime.now(),
          lastUpdatedBy: payload.userId,
          notes: payload.notes,
          reportCount: existing.reportCount + 1,
        );
        _selectedStation = _allStations[index];
        await _updateMarkers();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to submit stock update: $e');
      rethrow;
    }
  }

  Future<String> addNewStation({
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
    try {
      final docId = await _firestoreService.addGasStation(
        name: name,
        brand: brand,
        address: address,
        town: town,
        latitude: latitude,
        longitude: longitude,
        status: status,
        queueCondition: queueCondition,
        cylinders: cylinders,
        userId: userId,
        contactNumber: contactNumber,
        notes: notes,
      );

      await moveToLocation(latitude, longitude, zoom: 16.0);
      return docId;
    } catch (e) {
      debugPrint('Failed to add new gas station: $e');
      rethrow;
    }
  }

  Future<void> deleteStation(String stationId) async {
    try {
      await _firestoreService.deleteStation(stationId);
      if (_selectedStation?.id == stationId) {
        selectStation(null);
      }
    } catch (e) {
      debugPrint('Failed to delete gas station: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _stationsSubscription?.cancel();
    super.dispose();
  }
}
