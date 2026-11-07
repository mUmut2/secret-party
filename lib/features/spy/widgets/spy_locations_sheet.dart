import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/spy/spy_location.dart';

/// "Muhtemel Konumlar" rehberini alt sayfa olarak açar.
///
/// Oyunda çıkabilecek tüm konumlar listelenir; ajan da masumlar da soru
/// sorarken bu listeye bakabilir. [showRoles] açıksa her konumun rolleri de
/// gösterilir (kurulumda); oyun sırasında roller gizlenir ki ekran ajan
/// için ipucu olmasın.
Future<void> showSpyLocationsSheet(
  BuildContext context, {
  required List<SpyLocation> locations,
  bool showRoles = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    barrierColor: AppColors.overlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => _LocationsList(
        locations: locations,
        showRoles: showRoles,
        controller: controller,
      ),
    ),
  );
}

class _LocationsList extends StatelessWidget {
  const _LocationsList({
    required this.locations,
    required this.showRoles,
    required this.controller,
  });

  final List<SpyLocation> locations;
  final bool showRoles;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: locations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Muhtemel Konumlar', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Oyunda bu ${locations.length} konumdan biri çıkacak.',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          );
        }
        final location = locations[index - 1];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place,
                    size: AppSpacing.l,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(location.name, style: AppTypography.title),
                  ),
                ],
              ),
              if (showRoles) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  location.roles.join(' · '),
                  style: AppTypography.caption,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
