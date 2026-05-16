import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/attachment_service.dart';
import '../data/appwrite_attachment_storage_adapter.dart';
import '../data/attachment_storage_adapter.dart';

final attachmentStorageAdapterProvider = Provider<AttachmentStorageAdapter>((
  ref,
) {
  return AppwriteAttachmentStorageAdapter();
});

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentServiceImpl(
    storage: ref.watch(attachmentStorageAdapterProvider),
  );
});
