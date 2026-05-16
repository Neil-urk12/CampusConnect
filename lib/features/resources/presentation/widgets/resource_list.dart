import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/resource_entity.dart';
import 'resource_card.dart';
import '../../../../core/theme/design_tokens.dart';

/// Grid view of resource cards with empty and loading states.
class ResourceList extends StatelessWidget {
  final List<ResourceEntity> resources;
  final bool isLoading;
  final String? emptyMessage;
  const ResourceList({
    super.key,
    required this.resources,
    this.isLoading = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: DesignTokens.primaryContainer),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              'Loading resources...',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: DesignTokens.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: DesignTokens.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: DesignTokens.spacing16),
            Text(
              emptyMessage ?? 'No resources yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DesignTokens.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing8),
            Text(
              'Upload the first resource to get started',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: DesignTokens.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DesignTokens.spacing12,
        mainAxisSpacing: DesignTokens.spacing12,
        childAspectRatio: 0.72,
      ),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        return ResourceCard(resource: resources[index]);
      },
    );
  }
}
