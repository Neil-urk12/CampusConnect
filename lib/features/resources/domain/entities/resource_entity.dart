import 'package:equatable/equatable.dart';

/// Categories for uploaded resources
enum ResourceCategory {
  studyMaterials('study_materials'),
  photos('photos'),
  other('other');

  final String value;
  const ResourceCategory(this.value);

  static ResourceCategory fromString(String value) {
    return ResourceCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ResourceCategory.other,
    );
  }
}

/// Domain entity representing a shared resource in the library
class ResourceEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final ResourceCategory category;
  final List<String> tags;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;
  final int downloadCount;

  const ResourceEntity({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.category,
    this.tags = const [],
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    this.downloadCount = 0,
  });

  ResourceEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    ResourceCategory? category,
    List<String>? tags,
    String? uploadedBy,
    String? uploadedByName,
    DateTime? uploadedAt,
    int? downloadCount,
  }) {
    return ResourceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        fileUrl,
        fileName,
        fileSize,
        mimeType,
        category,
        tags,
        uploadedBy,
        uploadedByName,
        uploadedAt,
        downloadCount,
      ];
}
