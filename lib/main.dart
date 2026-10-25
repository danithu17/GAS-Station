import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/map_style.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/gas_tracker_provider.dart';
import 'providers/language_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'widgets/add_station_dialog.dart';
import 'widgets/search_and_filters_bar.dart';
import 'widgets/station_details_sheet.dart';
import 'widgets/station_list_view.dart';
import 'widgets/town_selector_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const GasTrackerApp());
}

class GasTrackerApp extends StatelessWidget {
  const GasTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => GasTrackerProvider()),
      ],
      child: Consumer<AppAuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Lanka Gas Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: _resolveAppScreen(auth),
          );
        },
      ),
    );
  }

  Widget _resolveAppScreen(AppAuthProvider auth) {
    // 1. Initial loading state
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Starting Lanka Gas Tracker...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Mandatory Authentication with Google
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // 3. Mandatory Profile Setup (Name, Mobile Phone Number, Town)
    if (auth.needsProfileSetup) {
      return const ProfileSetupScreen();
    }

    // 4. Main Gas Tracker Map View
    return const GasTrackerHomeScreen();
  }
}

class GasTrackerHomeScreen extends StatefulWidget {
  const GasTrackerHomeScreen({super.key});

  @override
  State<GasTrackerHomeScreen> createState() => _GasTrackerHomeScreenState();
}

class _GasTrackerHomeScreenState extends State<GasTrackerHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isListView = false;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GasTrackerProvider>();
      // Request location immediately upon entering screen
      provider.requestLocationAndCenter();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    context.read<GasTrackerProvider>().setMapController(controller);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GasTrackerProvider>();
    final auth = context.watch<AppAuthProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAppDrawer(context, auth, provider, lang),
      body: Stack(
        children: [
          // 1. Map View or List View (IndexedStack keeps GoogleMap state alive)
          Positioned.fill(
            child: IndexedStack(
              index: _isListView ? 1 : 0,
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  markers: provider.markers,
                  circles: provider.circles,
                  style: darkMapStyle,
                  onMapCreated: _onMapCreated,
                  onCameraMove: (cam) => provider.updateMapCenter(cam.target),
                  onLongPress: (pos) => AddStationDialog.show(context, position: pos),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  onTap: (_) {
                    provider.selectStation(null);
                  },
                ),
                StationListView(
                  onSelectStationFromList: () {
                    setState(() => _isListView = false);
                  },
                ),
              ],
            ),
          ),

          // 2. Top Floating Search & Filter Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SearchAndFiltersBar(
              isListView: _isListView,
              onToggleView: () {
                setState(() => _isListView = !_isListView);
              },
              onOpenTownSelector: () {
                TownSelectorDialog.show(context);
              },
            ),
          ),

          // 3. Floating Action Buttons (Add Station, Recenter & Menu Drawer)
          if (!_isListView)
            Positioned(
              right: 14,
              bottom: provider.selectedStation != null ? 230 : 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'fab_add_station',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                    label: Text(
                      lang.isSinhala ? 'Station එක් කරන්න' : 'Add Station',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      AddStationDialog.show(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'fab_menu',
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.textPrimary,
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: const Icon(Icons.menu_rounded),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'fab_recenter',
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.primary,
                        tooltip: 'Recenter to My GPS Location',
                        onPressed: () {
                          provider.requestLocationAndCenter();
                        },
                        child: const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 3b. Empty Station Guidance Banner (When 0 stations present)
          if (provider.filteredStations.isEmpty && !provider.isLoading && !_isListView)
            Positioned(
              top: 112,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.searchQuery.isNotEmpty
                                ? (lang.isSinhala
                                    ? '"${provider.searchQuery}" හි stations හමුනොවීය'
                                    : 'No stations found in "${provider.searchQuery}"')
                                : (lang.isSinhala
                                    ? 'තවමත් stations ඇතුළත් කර නොමැත'
                                    : 'No gas stations registered yet'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.isSinhala
                                ? 'නව Litro/Laugfs station එකක් එක් කිරීමට "Add Now" ඔබන්න.'
                                : 'Tap "Add Now" to register a Litro or Laugfs dealer.',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => AddStationDialog.show(context),
                      child: Text(
                        lang.isSinhala ? 'එක් කරන්න' : 'Add Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Station Details Bottom Preview Sheet (When Marker Tapped)
          if (provider.selectedStation != null && !_isListView)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: StationDetailsSheet(
                  station: provider.selectedStation!,
                  onClose: () {
                    provider.selectStation(null);
                  },
                ),
              ),
            ),

          // 5. Initial Loading Indicator
          if (provider.isLoading)
            Positioned(
              bottom: 24,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Syncing Firestore live data...',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(
    BuildContext context,
    AppAuthProvider auth,
    GasTrackerProvider gasProvider,
    LanguageProvider lang,
  ) {
    final profile = auth.userProfile;
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.appTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Litro & Laugfs Real-Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Registered Profile Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.availableGreen.withValues(alpha: 0.2),
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, size: 22, color: AppColors.availableGreen)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.name ?? auth.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (profile?.phone.isNotEmpty == true)
                                Text(
                                  profile!.phone,
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                ),
                              Text(
                                profile?.town.isNotEmpty == true
                                    ? profile!.town
                                    : (user?.email ?? 'Citizen User'),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4 KM Proximity Alert Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.proximityAlert,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          gasProvider.userPosition != null
                              ? (lang.isSinhala ? 'GPS සක්‍රීයයි • 4 KM කවය ඇඳ ඇත' : 'GPS Active • 4 KM Circle Active')
                              : (lang.isSinhala ? 'GPS ලබාගනිමින්...' : 'Acquiring GPS...'),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Add New Gas Station
            ListTile(
              leading: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
              title: Text(lang.addStation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Register a new Litro or Laugfs outlet in Sri Lanka',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                AddStationDialog.show(context);
              },
            ),

            // Jump to Town
            ListTile(
              leading: const Icon(Icons.location_city_rounded, color: AppColors.litroBlue),
              title: const Text('Find City / Town', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Jump directly to Colombo, Kandy, Galle, etc.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                TownSelectorDialog.show(context);
              },
            ),

            // Language Selector
            ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.laugfsYellow),
              title: Text(lang.selectLanguage, style: const TextStyle(fontSize: 14)),
              trailing: DropdownButton<AppLanguage>(
                value: lang.currentLanguage,
                dropdownColor: AppColors.surfaceElevated,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('English', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.sinhala,
                    child: Text('සිංහල', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    lang.setLanguage(val);
                  }
                },
              ),
            ),

            const Spacer(),

            // Sign Out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                onPressed: () async {
                  Navigator.pop(context);
                  await auth.signOut();
                },
              ),
            ),

            // App Version Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              alignment: Alignment.center,
              child: const Text(
                'Version 1.0.0 • Verified Citizens\nBuilt for Sri Lanka Community',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
