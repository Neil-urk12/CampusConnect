import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/resource_entity.dart';
import '../../../resources/presentation/utils/file_type_utils.dart';
import '../../../../app/routes.dart';
import '../../../../core/theme/design_tokens.dart';

/// A card displaying a resource summary in the browse grid.
class ResourceCard extends StatelessWidget {
  final ResourceEntity resource;

  const ResourceCard({super.key, required this.resource});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.resourceDetail,
          arguments: resource,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          boxShadow: [DesignTokens.cardShadow()],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / icon area
            _buildPreview(context),
            // Metadata
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacing8,
                      vertical: DesignTokens.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: _categoryColor(resource.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    child: Text(
                      _categoryLabel(resource.category),
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _categoryColor(resource.category),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing8),
                  // Title
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  // Uploader
                  Text(
                    resource.uploadedByName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: DesignTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing8),
                  // Bottom row: date + downloads
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: DesignTokens.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: DesignTokens.spacing4),
                      Expanded(
                        child: Text(
                          DateFormat('MMM d').format(resource.uploadedAt),
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: DesignTokens.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.download_rounded,
                        size: 12,
                        color: DesignTokens.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${resource.downloadCount}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: DesignTokens.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final double height = 120;
    if (isImage(resource.mimeType) && resource.fileUrl.isNotEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(
          resource.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconPlaceholder(height),
        ),
      );
    }
    return _iconPlaceholder(height);
  }

  Widget _iconPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: DesignTokens.surfaceContainerLow,
      child: Center(
        child: Icon(
          getFileIcon(resource.mimeType),
          size: 40,
          color: DesignTokens.primaryContainer.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  static Color _categoryColor(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.studyMaterials:
        return DesignTokens.categoryAcademic;
      case ResourceCategory.photos:
        return DesignTokens.categorySocial;
      case ResourceCategory.other:
        return DesignTokens.onSurfaceVariant;
    }
  }

  static String _categoryLabel(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.studyMaterials:
        return 'Study Materials';
      case ResourceCategory.photos:
        return 'Photos';
      case ResourceCategory.other:
        return 'Other';
    }
  }
}
