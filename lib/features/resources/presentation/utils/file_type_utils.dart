import 'package:flutter/material.dart';

/// Returns an appropriate icon for the given MIME type.
IconData getFileIcon(String mimeType) {
  final normalized = mimeType.trim().toLowerCase();

  if (normalized.startsWith('image/')) {
    return Icons.image_rounded;
  }
  if (normalized == 'application/pdf') {
    return Icons.picture_as_pdf_rounded;
  }
  if (normalized == 'application/msword' ||
      normalized.startsWith('application/vnd.') ||
      normalized ==
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
    return Icons.description_rounded;
  }
  if (normalized.startsWith('video/')) {
    return Icons.videocam_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

/// Human-readable label for the file type.
String getFileTypeLabel(String mimeType) {
  final normalized = mimeType.trim().toLowerCase();

  if (normalized.startsWith('image/')) {
    if (normalized.contains('jpeg') || normalized.contains('jpg')) return 'JPEG Image';
    if (normalized.contains('png')) return 'PNG Image';
    if (normalized.contains('gif')) return 'GIF Image';
    if (normalized.contains('webp')) return 'WebP Image';
    return 'Image';
  }
  if (normalized == 'application/pdf') return 'PDF Document';
  if (normalized == 'application/msword') return 'Word Document';
  if (normalized.contains('wordprocessingml')) return 'Word Document';
  if (normalized.contains('spreadsheetml') || normalized.contains('ms-excel')) return 'Spreadsheet';
  if (normalized.contains('presentationml') || normalized.contains('ms-powerpoint')) return 'Presentation';
  if (normalized.startsWith('video/')) return 'Video';
  return 'File';
}

/// Formats bytes into a human-readable string.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

bool isImage(String mimeType) => mimeType.trim().toLowerCase().startsWith('image/');

bool isPdf(String mimeType) => mimeType.trim().toLowerCase() == 'application/pdf';

bool isDocument(String mimeType) {
  final normalized = mimeType.trim().toLowerCase();
  return normalized == 'application/msword' ||
      normalized.startsWith('application/vnd.');
}

bool isVideo(String mimeType) => mimeType.trim().toLowerCase().startsWith('video/');

/// Whether the file can be previewed inline (image, pdf, video).
bool shouldPreview(String mimeType) =>
    isImage(mimeType) || isPdf(mimeType) || isVideo(mimeType);
