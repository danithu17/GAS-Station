import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/gas_station.dart';
import '../providers/auth_provider.dart';
import '../providers/gas_tracker_provider.dart';

class AddStationDialog extends StatefulWidget {
  final LatLng? initialPosition;

  const AddStationDialog({super.key, this.initialPosition});

  static Future<void> show(BuildContext context, {LatLng? position}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddStationDialog(initialPosition: position),
    );
  }

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  GasBrand _selectedBrand = GasBrand.litro;
  StockStatus _selectedStatus = StockStatus.unverified;
  final QueueCondition _selectedQueue = QueueCondition.short;
  late double _latitude;
  late double _longitude;
  bool _isSubmitting = false;

  final Map<String, bool> _cylinders = {
    '12.5kg': true,
    '5kg': true,
    '2.3kg': false,
    '37.5kg': false,
  };

  @override
  void initState() {
    super.initState();
    final gasProvider = context.read<GasTrackerProvider>();
    final pos = widget.initialPosition ?? gasProvider.currentMapCenter;
    _latitude = pos.latitude;
    _longitude = pos.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _townController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final gasProvider = context.read<GasTrackerProvider>();

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in (or wait for 1-Tap Anonymous) to add stations.'),
          backgroundColor: AppColors.outOfStockRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await gasProvider.addNewStation(
        name: _nameController.text.trim(),
        brand: _selectedBrand,
        address: _addressController.text.trim(),
        town: _townController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        status: _selectedStatus,
        queueCondition: _selectedQueue,
        cylinders: _cylinders,
        userId: auth.userId,
        contactNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.availableGreen,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Gas station "${_nameController.text.trim()}" published to map!'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.outOfStockRed,
          content: Text('Failed to add station: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = _selectedBrand == GasBrand.litro ? AppColors.litroBlue : AppColors.laugfsYellow;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Gas Station',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Register a Litro or Laugfs dealer for Sri Lanka',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. Brand Selection
              const Text(
                '1. Select Gas Brand *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedBrand = GasBrand.litro),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedBrand == GasBrand.litro
                              ? AppColors.litroBlue.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedBrand == GasBrand.litro ? AppColors.litroBlue : AppColors.border,
                            width: _selectedBrand == GasBrand.litro ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.litroBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Litro Gas (Blue)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedBrand = GasBrand.laugfs),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedBrand == GasBrand.laugfs
                              ? AppColors.laugfsYellow.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedBrand == GasBrand.laugfs ? AppColors.laugfsYellow : AppColors.border,
                            width: _selectedBrand == GasBrand.laugfs ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.laugfsYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Laugfs Gas (Yellow)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Station Name
              const Text(
                '2. Station / Dealer Name *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g., Litro Point - Kollupitiya',
                  prefixIcon: Icon(Icons.storefront_rounded, size: 20, color: brandColor),
                  fillColor: AppColors.surfaceElevated,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter station name';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 3. Town / City & Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Town / City *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _townController,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'e.g., Colombo',
                            prefixIcon: Icon(Icons.location_city_rounded, size: 20, color: AppColors.textSecondary),
                            fillColor: AppColors.surfaceElevated,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter town';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Street Address / Landmark *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'e.g., 284 Galle Road',
                            prefixIcon: Icon(Icons.place_outlined, size: 20, color: AppColors.textSecondary),
                            fillColor: AppColors.surfaceElevated,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter address';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Coordinates / Location Picker
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Map Position (GPS Coordinates)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Sync Center', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        final center = context.read<GasTrackerProvider>().currentMapCenter;
                        setState(() {
                          _latitude = center.latitude;
                          _longitude = center.longitude;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Initial Stock Status
              const Text(
                '5. Current Stock Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusRadio(StockStatus.unverified, 'Unverified', AppColors.unverifiedAmber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusRadio(StockStatus.available, 'In Stock', AppColors.availableGreen),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusRadio(StockStatus.outOfStock, 'Out of Stock', AppColors.outOfStockRed),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 6. Cylinder Sizes
              const Text(
                '6. Cylinder Sizes Typically Supplied',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCylinderChip('12.5kg', '12.5 kg Domestic'),
                  _buildCylinderChip('5kg', '5.0 kg Mini'),
                  _buildCylinderChip('2.3kg', '2.3 kg Portable'),
                  _buildCylinderChip('37.5kg', '37.5 kg Industrial'),
                ],
              ),

              const SizedBox(height: 16),

              // 7. Contact Number & Notes
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Contact Phone Number (Optional, e.g. +94 11 257 3290)',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.textSecondary),
                  fillColor: AppColors.surfaceElevated,
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Additional notes or opening hours (Optional)...',
                  prefixIcon: Icon(Icons.notes_rounded, size: 20, color: AppColors.textSecondary),
                  fillColor: AppColors.surfaceElevated,
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Publishing Station...' : 'Add Station to Live Map',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRadio(StockStatus status, String label, Color color) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCylinderChip(String key, String label) {
    final isChecked = _cylinders[key] == true;
    return FilterChip(
      selected: isChecked,
      label: Text(label),
      showCheckmark: true,
      checkmarkColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(
        color: isChecked ? AppColors.primary : AppColors.border,
        width: isChecked ? 1.5 : 1,
      ),
      labelStyle: TextStyle(
        color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isChecked ? FontWeight.w700 : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (val) {
        setState(() {
          _cylinders[key] = val;
        });
      },
    );
  }
}
