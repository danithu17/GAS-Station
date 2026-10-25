import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/gas_station.dart';
import '../models/stock_update.dart';
import '../providers/auth_provider.dart';
import '../providers/gas_tracker_provider.dart';
import '../utils/time_formatter.dart';

class CrowdsourceBottomSheet extends StatefulWidget {
  final GasStation station;

  const CrowdsourceBottomSheet({super.key, required this.station});

  static void show(BuildContext context, GasStation station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CrowdsourceBottomSheet(station: station),
    );
  }

  @override
  State<CrowdsourceBottomSheet> createState() => _CrowdsourceBottomSheetState();
}

class _CrowdsourceBottomSheetState extends State<CrowdsourceBottomSheet> {
  late StockStatus _selectedStatus;
  late QueueCondition _selectedQueue;
  late Map<String, bool> _cylinders;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.station.status;
    _selectedQueue = widget.station.queueCondition;
    _cylinders = Map<String, bool>.from(widget.station.cylinders);
    if (_cylinders.isEmpty) {
      _cylinders = {'12.5kg': true, '5kg': true, '2.3kg': false, '37.5kg': false};
    }

    // Check anti-spam cooldown on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      if (auth.isAuthenticated) {
        context.read<GasTrackerProvider>().checkUserCooldown(widget.station.id, auth.userId);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final auth = context.read<AppAuthProvider>();
    final gasProvider = context.read<GasTrackerProvider>();

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in (or use 1-Tap Anonymous) to report gas stock.'),
          backgroundColor: AppColors.outOfStockRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = StockUpdatePayload(
        stationId: widget.station.id,
        status: _selectedStatus,
        queueCondition: _selectedQueue,
        cylinders: _cylinders,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        userId: auth.userId,
        userDisplayName: auth.displayName,
      );

      final success = await gasProvider.submitStockUpdate(payload);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.availableGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Stock updated for ${widget.station.name}! Thank you.'),
                ),
              ],
            ),
          ),
        );
      } else {
        final rem = gasProvider.getRemainingCooldown(widget.station.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.unverifiedAmber,
            content: Text(
              'Anti-spam cooldown active: ${TimeFormatter.formatDuration(rem)} remaining.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.outOfStockRed,
          content: Text('Update failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final gasProvider = context.watch<GasTrackerProvider>();
    final isLitro = widget.station.isLitro;
    final brandColor = isLitro ? AppColors.litroBlue : AppColors.laugfsYellow;

    final remainingCooldown = gasProvider.getRemainingCooldown(widget.station.id);
    final isCooldownActive = remainingCooldown > Duration.zero;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SingleChildScrollView(
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

            // Header: Station Name & Brand Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.18),
                    border: Border.all(color: brandColor, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.station.brand.displayName.toUpperCase(),
                    style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.station.address} • ${widget.station.town}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Last confirmed: ${TimeFormatter.formatRelative(widget.station.lastUpdated)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.station.reportCount} reports',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Authentication Banner if user not logged in
            if (!auth.isAuthenticated) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Crowdsource Sign-in Required',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to verify gas availability and prevent spam reports.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.red),
                        label: const Text('Sign in with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        onPressed: () => auth.signInWithGoogle(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Anti-Spam Cooldown Banner
            if (isCooldownActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.unverifiedAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.unverifiedAmber.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.unverifiedAmber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anti-Spam Cooldown Active',
                            style: TextStyle(
                              color: AppColors.unverifiedAmber,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'To keep data reliable, 1 report allowed per 30 minutes. Remaining: ${TimeFormatter.formatDuration(remainingCooldown)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1. Stock Status Selection
            const Text(
              '1. Current Stock Availability',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatusRadio(
                    status: StockStatus.available,
                    title: 'In Stock',
                    color: AppColors.availableGreen,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusRadio(
                    status: StockStatus.outOfStock,
                    title: 'Out of Stock',
                    color: AppColors.outOfStockRed,
                    icon: Icons.cancel_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusRadio(
                    status: StockStatus.unverified,
                    title: 'Unverified',
                    color: AppColors.unverifiedAmber,
                    icon: Icons.help_outline_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Queue Conditions Selection
            const Text(
              '2. Queue Waiting Time',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQueueRadio(
                    condition: QueueCondition.short,
                    title: 'Short',
                    subtitle: '< 15 mins',
                    color: AppColors.availableGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQueueRadio(
                    condition: QueueCondition.moderate,
                    title: 'Moderate',
                    subtitle: '15-45 mins',
                    color: AppColors.unverifiedAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQueueRadio(
                    condition: QueueCondition.long,
                    title: 'Long',
                    subtitle: '> 45 mins',
                    color: AppColors.outOfStockRed,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Cylinder Types Selection
            const Text(
              '3. Cylinder Types In Stock',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
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

            const SizedBox(height: 20),

            // 4. Notes / Crowd Observation
            const Text(
              '4. Notes / Live Observations (Optional)',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Truck arrived 10 mins ago. Token system in place...',
                fillColor: AppColors.surfaceElevated,
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCooldownActive
                      ? AppColors.surfaceVariant
                      : AppColors.primary,
                  foregroundColor: isCooldownActive
                      ? AppColors.textMuted
                      : Colors.black,
                  elevation: isCooldownActive ? 0 : 3,
                ),
                onPressed: (_isSubmitting || isCooldownActive || !auth.isAuthenticated)
                    ? null
                    : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCooldownActive ? Icons.lock_clock : Icons.cloud_upload_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCooldownActive
                                ? 'Cooldown (${TimeFormatter.formatDuration(remainingCooldown)})'
                                : 'Submit Stock Update',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRadio({
    required StockStatus status,
    required String title,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueRadio({
    required QueueCondition condition,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedQueue == condition;
    return InkWell(
      onTap: () => setState(() => _selectedQueue = condition),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? color : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
        fontSize: 12.5,
      ),
      onSelected: (val) {
        setState(() {
          _cylinders[key] = val;
        });
      },
    );
  }
}
