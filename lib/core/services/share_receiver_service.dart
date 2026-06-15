import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../utils/logger.dart';
import '../router/app_router.dart';

class ShareReceiverService {
  ShareReceiverService._();

  static StreamSubscription? _intentSub;

  static void initialize() {
    try {
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            AppLogger.success('Received hot shared media: ${value.length} files', tag: 'ShareReceiverService');
            _navigateToSharedMedia(value);
          }
        },
        onError: (err) {
          AppLogger.error('Error listening to media intent stream', error: err, tag: 'ShareReceiverService');
        },
      );

      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          AppLogger.success('Received cold shared media: ${value.length} files', tag: 'ShareReceiverService');
          _navigateToSharedMedia(value);
        }
      }).catchError((err) {
        AppLogger.error('Error getting initial media intent', error: err, tag: 'ShareReceiverService');
      });

      AppLogger.success('ShareReceiverService initialized successfully', tag: 'ShareReceiverService');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize ShareReceiverService', error: e, stackTrace: stack, tag: 'ShareReceiverService');
    }
  }

  static void _navigateToSharedMedia(List<SharedMediaFile> files) {
    try {
      final List<String> paths = files.map((f) => f.path).toList();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        AppRouter.router.push('/shared-media', extra: paths);
      });
    } catch (e) {
      AppLogger.error('Routing to shared media page failed', error: e, tag: 'ShareReceiverService');
    }
  }

  static void dispose() {
    _intentSub?.cancel();
  }
}
