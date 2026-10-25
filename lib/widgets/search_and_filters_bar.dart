import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/gas_station.dart';
import '../providers/gas_tracker_provider.dart';
import 'add_station_dialog.dart';
import 'town_selector_dialog.dart';

class SearchAndFiltersBar extends StatefulWidget {
  final VoidCallback onOpenTownSelector;
  final VoidCallback onToggleView;
  final bool isListView;

  const SearchAndFiltersBar({
    super.key,
    required this.onOpenTownSelector,
    required this.onToggleView,
    required this.isListView,
  });

  @override
  State<SearchAndFiltersBar> createState() => _SearchAndFiltersBarState();
}

class _SearchAndFiltersBarState extends State<SearchAndFiltersBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GasTrackerProvider>();
    final count = provider.filteredStations.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Top Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.location_city_rounded, color: AppColors.primary),
                    tooltip: 'Select Town',
                    onPressed: widget.onOpenTownSelector,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                      decoration: const InputDecoration(
                        hintText: 'Search town or station (Colombo, Kandy, Galle...)...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      onChanged: (val) {
                        provider.setSearchQuery(val);
                      },
                      onSubmitted: (val) {
                        final query = val.trim().toLowerCase();
                        if (query.isEmpty) return;

                        // 1. If matching stations found, jump to the first one
                        final matchedStations = provider.filteredStations;
                        if (matchedStations.isNotEmpty) {
                          provider.moveToLocation(
                            matchedStations.first.latitude,
                            matchedStations.first.longitude,
                            zoom: 15.0,
                          );
                          return;
                        }

                        // 2. Check if query matches a known Sri Lanka town
                        final matchedTown = majorTowns.firstWhere(
                          (t) => t.name.toLowerCase().contains(query) || t.district.toLowerCase().contains(query),
                          orElse: () => const SriLankaTown(name: '', district: '', latitude: 0, longitude: 0),
                        );
                        if (matchedTown.latitude != 0) {
                          provider.moveToLocation(matchedTown.latitude, matchedTown.longitude, zoom: 14.0);
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    ),
                  Container(
                    height: 24,
                    width: 1,
                    color: AppColors.border,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isListView ? Icons.map_outlined : Icons.format_list_bulleted_rounded,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: widget.isListView ? 'Show Map' : 'Show List',
                    onPressed: widget.onToggleView,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Horizontal Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Results Counter Chip
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_gas_station_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$count Found',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Add Station Action Chip
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                      label: const Text('Add Station'),
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      backgroundColor: AppColors.primary,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () {
                        AddStationDialog.show(context);
                      },
                    ),
                  ),

                  // Brand Filters
                  _buildBrandChip(
                    label: 'All Brands',
                    isSelected: provider.selectedBrand == null,
                    onSelected: () => provider.setBrandFilter(null),
                  ),
                  _buildBrandChip(
                    label: 'Litro',
                    brandColor: AppColors.litroBlue,
                    isSelected: provider.selectedBrand == GasBrand.litro,
                    onSelected: () => provider.setBrandFilter(
                      provider.selectedBrand == GasBrand.litro ? null : GasBrand.litro,
                    ),
                  ),
                  _buildBrandChip(
                    label: 'Laugfs',
                    brandColor: AppColors.laugfsYellow,
                    textColor: Colors.black87,
                    isSelected: provider.selectedBrand == GasBrand.laugfs,
                    onSelected: () => provider.setBrandFilter(
                      provider.selectedBrand == GasBrand.laugfs ? null : GasBrand.laugfs,
                    ),
                  ),

                  const SizedBox(width: 4),
                  Container(height: 18, width: 1, color: AppColors.border),
                  const SizedBox(width: 4),

                  // Status Filters
                  _buildStatusChip(
                    label: 'All Status',
                    isSelected: provider.selectedStatus == null,
                    onSelected: () => provider.setStatusFilter(null),
                  ),
                  _buildStatusChip(
                    label: 'In Stock',
                    dotColor: AppColors.availableGreen,
                    isSelected: provider.selectedStatus == StockStatus.available,
                    onSelected: () => provider.setStatusFilter(
                      provider.selectedStatus == StockStatus.available ? null : StockStatus.available,
                    ),
                  ),
                  _buildStatusChip(
                    label: 'Out of Stock',
                    dotColor: AppColors.outOfStockRed,
                    isSelected: provider.selectedStatus == StockStatus.outOfStock,
                    onSelected: () => provider.setStatusFilter(
                      provider.selectedStatus == StockStatus.outOfStock ? null : StockStatus.outOfStock,
                    ),
                  ),
                  _buildStatusChip(
                    label: 'Unverified',
                    dotColor: AppColors.unverifiedAmber,
                    isSelected: provider.selectedStatus == StockStatus.unverified,
                    onSelected: () => provider.setStatusFilter(
                      provider.selectedStatus == StockStatus.unverified ? null : StockStatus.unverified,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandChip({
    required String label,
    Color? brandColor,
    Color? textColor,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
        selectedColor: brandColor != null
            ? brandColor.withValues(alpha: 0.3)
            : AppColors.primary.withValues(alpha: 0.3),
        side: BorderSide(
          color: isSelected
              ? (brandColor ?? AppColors.primary)
              : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
        avatar: brandColor != null
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: brandColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    Color? dotColor,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
        selectedColor: dotColor != null
            ? dotColor.withValues(alpha: 0.25)
            : AppColors.primary.withValues(alpha: 0.25),
        side: BorderSide(
          color: isSelected ? (dotColor ?? AppColors.primary) : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
        avatar: dotColor != null
            ? Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
