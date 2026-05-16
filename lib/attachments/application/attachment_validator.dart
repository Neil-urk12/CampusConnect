import '../domain/attachment_exception.dart';
import '../domain/attachment_types.dart';

class AttachmentValidator {
  const AttachmentValidator({
    this.maxImageSizeBytes = 45 * 1024 * 1024,
    this.allowedImageMimeTypes = const {
      'image/jpeg',
      'image/png',
      'image/webp',
    },
  });

  final int maxImageSizeBytes;
  final Set<String> allowedImageMimeTypes;

  void validateImage({
    required AttachmentOwnerRef owner,
    required AttachmentInput image,
  }) {
    if (owner.ownerId.trim().isEmpty) {
      throw const AttachmentException(
        code: AttachmentErrorCode.invalidOwner,
        message: 'Attachment ownerId is required.',
        field: 'ownerId',
      );
    }

    if (!allowedImageMimeTypes.contains(image.mimeType.toLowerCase())) {
      throw AttachmentException(
        code: AttachmentErrorCode.unsupportedType,
        message: 'Unsupported image type: ${image.mimeType}.',
        field: 'mimeType',
      );
    }

    if (image.sizeBytes > maxImageSizeBytes) {
      throw AttachmentException(
        code: AttachmentErrorCode.fileTooLarge,
        message: 'Image is too large.',
        field: 'sizeBytes',
      );
    }
  }
}
