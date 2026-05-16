import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/resource_entity.dart';

/// Data model for Resource, handles Firestore serialization/deserialization
class ResourceModel extends ResourceEntity {
  const ResourceModel({
    required super.id,
    required super.title,
    super.description,
    required super.fileUrl,
    required super.fileName,
    required super.fileSize,
    required super.mimeType,
    required super.category,
    super.tags = const [],
    required super.uploadedBy,
    required super.uploadedByName,
    required super.uploadedAt,
    super.downloadCount = 0,
  });

  /// Create a [ResourceModel] from Firestore document data
  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType'] as String? ?? '',
      category: ResourceCategory.fromString(json['category'] as String? ?? 'other'),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploadedByName: json['uploadedByName'] as String? ?? '',
      uploadedAt: _parseTimestamp(json['uploadedAt']),
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert model to a Firestore-compatible map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'category': category.value,
      'tags': tags,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'downloadCount': downloadCount,
    };
  }

  /// Create a [ResourceModel] from a domain [ResourceEntity]
  factory ResourceModel.fromEntity(ResourceEntity entity) {
    return ResourceModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      category: entity.category,
      tags: entity.tags,
      uploadedBy: entity.uploadedBy,
      uploadedByName: entity.uploadedByName,
      uploadedAt: entity.uploadedAt,
      downloadCount: entity.downloadCount,
    );
  }

  /// Convert model back to domain [ResourceEntity]
  ResourceEntity toEntity() {
    return ResourceEntity(
      id: id,
      title: title,
      description: description,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      category: category,
      tags: tags,
      uploadedBy: uploadedBy,
      uploadedByName: uploadedByName,
      uploadedAt: uploadedAt,
      downloadCount: downloadCount,
    );
  }

  /// Helper: parse Firestore Timestamp or fallback to DateTime.now()
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}
