import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/gas_tracker_provider.dart';

class SriLankaTown {
  final String name;
  final String district;
  final double latitude;
  final double longitude;

  const SriLankaTown({
    required this.name,
    required this.district,
    required this.latitude,
    required this.longitude,
  });
}

const List<SriLankaTown> majorTowns = [
  // Colombo & Suburbs
  SriLankaTown(name: 'Colombo', district: 'Colombo District', latitude: 6.9271, longitude: 79.8612),
  SriLankaTown(name: 'Kollupitiya', district: 'Colombo 03', latitude: 6.9068, longitude: 79.8516),
  SriLankaTown(name: 'Bambalapitiya', district: 'Colombo 04', latitude: 6.8924, longitude: 79.8559),
  SriLankaTown(name: 'Borella', district: 'Colombo 08', latitude: 6.9147, longitude: 79.8778),
  SriLankaTown(name: 'Pettah', district: 'Colombo 11', latitude: 6.9366, longitude: 79.8532),
  SriLankaTown(name: 'Rajagiriya', district: 'Colombo Suburbs', latitude: 6.9082, longitude: 79.8967),
  SriLankaTown(name: 'Nugegoda', district: 'Colombo Suburbs', latitude: 6.8722, longitude: 79.8920),
  SriLankaTown(name: 'Dehiwala', district: 'Colombo South', latitude: 6.8524, longitude: 79.8665),
  SriLankaTown(name: 'Mount Lavinia', district: 'Colombo South', latitude: 6.8333, longitude: 79.8667),
  SriLankaTown(name: 'Moratuwa', district: 'Colombo South', latitude: 6.7730, longitude: 79.8816),
  SriLankaTown(name: 'Battaramulla', district: 'Colombo East', latitude: 6.8997, longitude: 79.9234),
  SriLankaTown(name: 'Malabe', district: 'Colombo East', latitude: 6.9042, longitude: 79.9547),
  SriLankaTown(name: 'Maharagama', district: 'Colombo Suburbs', latitude: 6.8480, longitude: 79.9267),
  SriLankaTown(name: 'Kottawa', district: 'Colombo Suburbs', latitude: 6.8417, longitude: 79.9654),
  SriLankaTown(name: 'Homagama', district: 'Colombo Suburbs', latitude: 6.8436, longitude: 80.0031),

  // Gampaha District
  SriLankaTown(name: 'Gampaha', district: 'Gampaha District', latitude: 7.0873, longitude: 79.9945),
  SriLankaTown(name: 'Negombo', district: 'Gampaha Coastal', latitude: 7.2008, longitude: 79.8736),
  SriLankaTown(name: 'Wattala', district: 'Gampaha District', latitude: 6.9895, longitude: 79.8919),
  SriLankaTown(name: 'Ja-Ela', district: 'Gampaha District', latitude: 7.0754, longitude: 79.8913),
  SriLankaTown(name: 'Kadawatha', district: 'Gampaha District', latitude: 7.0016, longitude: 79.9530),
  SriLankaTown(name: 'Kelaniya', district: 'Gampaha District', latitude: 6.9553, longitude: 79.9224),

  // Kalutara District
  SriLankaTown(name: 'Panadura', district: 'Kalutara District', latitude: 6.7132, longitude: 79.9074),
  SriLankaTown(name: 'Kalutara', district: 'Kalutara District', latitude: 6.5854, longitude: 79.9607),
  SriLankaTown(name: 'Horana', district: 'Kalutara District', latitude: 6.7161, longitude: 80.0637),

  // Central Province
  SriLankaTown(name: 'Kandy', district: 'Kandy District', latitude: 7.2906, longitude: 80.6337),
  SriLankaTown(name: 'Peradeniya', district: 'Kandy District', latitude: 7.2608, longitude: 80.5976),
  SriLankaTown(name: 'Gampola', district: 'Kandy District', latitude: 7.1643, longitude: 80.5694),
  SriLankaTown(name: 'Matale', district: 'Matale District', latitude: 7.4675, longitude: 80.6234),
  SriLankaTown(name: 'Nuwara Eliya', district: 'Central Highlands', latitude: 6.9497, longitude: 80.7891),
  SriLankaTown(name: 'Hatton', district: 'Central Highlands', latitude: 6.8917, longitude: 80.5966),

  // Southern Province
  SriLankaTown(name: 'Galle', district: 'Galle District', latitude: 6.0535, longitude: 80.2210),
  SriLankaTown(name: 'Hikkaduwa', district: 'Galle Coastal', latitude: 6.1408, longitude: 80.1030),
  SriLankaTown(name: 'Matara', district: 'Matara District', latitude: 5.9549, longitude: 80.5550),
  SriLankaTown(name: 'Weligama', district: 'Matara Coastal', latitude: 5.9750, longitude: 80.4290),
  SriLankaTown(name: 'Tangalle', district: 'Hambantota District', latitude: 6.0243, longitude: 80.7941),
  SriLankaTown(name: 'Hambantota', district: 'Hambantota District', latitude: 6.1246, longitude: 81.1185),

  // North Western Province
  SriLankaTown(name: 'Kurunegala', district: 'Kurunegala District', latitude: 7.4863, longitude: 80.3623),
  SriLankaTown(name: 'Kuliyapitiya', district: 'Kurunegala District', latitude: 7.4689, longitude: 80.0401),
  SriLankaTown(name: 'Chilaw', district: 'Puttalam District', latitude: 7.5758, longitude: 79.7953),
  SriLankaTown(name: 'Puttalam', district: 'Puttalam District', latitude: 8.0362, longitude: 79.8283),

  // North Central Province
  SriLankaTown(name: 'Anuradhapura', district: 'Anuradhapura District', latitude: 8.3114, longitude: 80.4037),
  SriLankaTown(name: 'Polonnaruwa', district: 'Polonnaruwa District', latitude: 7.9403, longitude: 81.0188),

  // Northern Province
  SriLankaTown(name: 'Jaffna', district: 'Jaffna District', latitude: 9.6615, longitude: 80.0255),
  SriLankaTown(name: 'Kilinochchi', district: 'Northern Province', latitude: 9.3803, longitude: 80.3770),
  SriLankaTown(name: 'Vavuniya', district: 'Northern Province', latitude: 8.7514, longitude: 80.4971),

  // Eastern Province
  SriLankaTown(name: 'Trincomalee', district: 'Trincomalee District', latitude: 8.5874, longitude: 81.2152),
  SriLankaTown(name: 'Batticaloa', district: 'Batticaloa District', latitude: 7.7310, longitude: 81.6747),
  SriLankaTown(name: 'Ampara', district: 'Ampara District', latitude: 7.2912, longitude: 81.6724),

  // Uva Province
  SriLankaTown(name: 'Badulla', district: 'Badulla District', latitude: 6.9934, longitude: 81.0550),
  SriLankaTown(name: 'Bandarawela', district: 'Badulla District', latitude: 6.8333, longitude: 80.9833),
  SriLankaTown(name: 'Monaragala', district: 'Monaragala District', latitude: 6.8728, longitude: 81.3507),

  // Sabaragamuwa Province
  SriLankaTown(name: 'Ratnapura', district: 'Ratnapura District', latitude: 6.7056, longitude: 80.3847),
  SriLankaTown(name: 'Kegalle', district: 'Kegalle District', latitude: 7.2513, longitude: 80.3464),
];

class TownSelectorDialog extends StatefulWidget {
  const TownSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TownSelectorDialog(),
    );
  }

  @override
  State<TownSelectorDialog> createState() => _TownSelectorDialogState();
}

class _TownSelectorDialogState extends State<TownSelectorDialog> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = majorTowns.where((t) {
      if (_filter.isEmpty) return true;
      return t.name.toLowerCase().contains(_filter.toLowerCase()) ||
          t.district.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Jump to Sri Lanka Town / City',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: false,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search city or district (Colombo, Kandy, Galle...)...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              fillColor: AppColors.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) => setState(() => _filter = val),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final town = filtered[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    town.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    town.district,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    final provider = context.read<GasTrackerProvider>();
                    provider.setSearchQuery(town.name);
                    provider.moveToLocation(town.latitude, town.longitude, zoom: 14.0);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
