import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'appwrite_config.dart';

/// Helper class for testing Appwrite integration with visible results
class AppwriteTestHelper {
  // Get bucket ID from environment
  static String get testBucketId =>
      dotenv.env['APPWRITE_CHAT_ATTACHMENTS_BUCKET_ID'] ?? '';

  /// Upload a test file that will be visible in Appwrite Console
  ///
  /// IMPORTANT: Before running this, create a bucket in Appwrite Console:
  /// 1. Go to https://cloud.appwrite.io
  /// 2. Select project: campusconnect
  /// 3. Navigate to Storage → Create Bucket
  /// 4. Set Bucket ID to: test-bucket (or update testBucketId above)
  /// 5. Set permissions to allow public read/write for testing
  static Future<void> uploadTestFile() async {
    try {
      final storage = Storage(AppwriteConfig.client);

      // Create a simple test file
      final testContent =
          '''
Hello from CampusConnect! 🎉

This is a test file created at: ${DateTime.now()}

If you can see this file in your Appwrite Console:
✅ Your Flutter app is connected to Appwrite
✅ Storage is working correctly
✅ You can now upload real files!

Project: ${AppwriteConfig.projectName}
Project ID: ${AppwriteConfig.projectId}
''';

      final fileId = 'test-${DateTime.now().millisecondsSinceEpoch}';

      // Upload the file
      final file = await storage.createFile(
        bucketId: testBucketId,
        fileId: fileId,
        file: InputFile.fromBytes(
          bytes: testContent.codeUnits,
          filename:
              'test-connection-${DateTime.now().millisecondsSinceEpoch}.png',
        ),
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.any()),
        ],
      );

      // ignore: avoid_print
      print('✅ Test file uploaded successfully!');
      // ignore: avoid_print
      print('📁 File ID: ${file.$id}');
      // ignore: avoid_print
      print('📦 Bucket ID: $testBucketId');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('🎉 SUCCESS! Check your Appwrite Console:');
      // ignore: avoid_print
      print('   1. Go to https://cloud.appwrite.io');
      // ignore: avoid_print
      print('   2. Select project: ${AppwriteConfig.projectName}');
      // ignore: avoid_print
      print('   3. Navigate to Storage → $testBucketId');
      // ignore: avoid_print
      print('   4. You should see your test file!');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Test file upload failed: $e');
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print(
        '💡 Make sure you created a bucket with ID "$testBucketId" in Appwrite Console!',
      );
      rethrow;
    }
  }

  /// Complete test that uploads a file
  static Future<void> runCompleteTest() async {
    // ignore: avoid_print
    print('🚀 Starting Appwrite integration test...');
    // ignore: avoid_print
    print('');

    try {
      // Ensure anonymous session exists before upload
      await AppwriteConfig.ensureSession();

      await uploadTestFile();
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('✅ All tests passed! Your Appwrite integration is working!');
    } catch (e) {
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('❌ Test failed: $e');
      rethrow;
    }
  }
}
