import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/gas_station.dart';
import '../providers/gas_tracker_provider.dart';
import '../utils/time_formatter.dart';
import 'add_station_dialog.dart';
import 'crowdsource_bottom_sheet.dart';

class StationListView extends StatelessWidget {
  final VoidCallback onSelectStationFromList;

  const StationListView({
    super.key,
    required this.onSelectStationFromList,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GasTrackerProvider>();
    final stations = provider.filteredStations;

    if (stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No gas stations found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting your search query, town, or brand filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset Filters'),
                    onPressed: () {
                      provider.setBrandFilter(null);
                      provider.setStatusFilter(null);
                      provider.setSearchQuery('');
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('Add Gas Station'),
                    onPressed: () {
                      AddStationDialog.show(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 130, 14, 80),
      itemCount: stations.length,
      itemBuilder: (ctx, index) {
        final station = stations[index];
        final isLitro = station.isLitro;
        final brandColor = isLitro ? AppColors.litroBlue : AppColors.laugfsYellow;

        Color statusColor;
        switch (station.status) {
          case StockStatus.available:
            statusColor = AppColors.availableGreen;
            break;
          case StockStatus.outOfStock:
            statusColor = AppColors.outOfStockRed;
            break;
          case StockStatus.unverified:
            statusColor = AppColors.unverifiedAmber;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              provider.selectStation(station);
              onSelectStationFromList();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: brandColor),
                        ),
                        child: Text(
                          station.brand.displayName,
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          station.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        TimeFormatter.formatRelative(station.lastUpdated),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${station.address} • ${station.town}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Queue: ${station.queueCondition.displayName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          CrowdsourceBottomSheet.show(context, station);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
