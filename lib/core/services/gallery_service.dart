import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

class GalleryService {
  GalleryService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        AppLogger.success('Successfully picked single image: ${image.path}', tag: 'GalleryService');
        return image.path;
      }
      AppLogger.info('User cancelled picking single image.', tag: 'GalleryService');
      return null;
    } catch (e, stack) {
      AppLogger.error('Failed to pick single image', error: e, stackTrace: stack, tag: 'GalleryService');
      return null;
    }
  }

  static Future<List<String>> pickMultiImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        final List<String> paths = images.map((image) => image.path).toList();
        AppLogger.success('Successfully picked ${paths.length} images from gallery.', tag: 'GalleryService');
        return paths;
      }
      AppLogger.info('User cancelled picking multi-images.', tag: 'GalleryService');
      return [];
    } catch (e, stack) {
      AppLogger.error('Failed to pick multi-images', error: e, stackTrace: stack, tag: 'GalleryService');
      return [];
    }
  }

  static Future<String?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        AppLogger.success('Successfully picked video: ${video.path}', tag: 'GalleryService');
        return video.path;
      }
      AppLogger.info('User cancelled picking video.', tag: 'GalleryService');
      return null;
    } catch (e, stack) {
      AppLogger.error('Failed to pick video', error: e, stackTrace: stack, tag: 'GalleryService');
      return null;
    }
  }
}
