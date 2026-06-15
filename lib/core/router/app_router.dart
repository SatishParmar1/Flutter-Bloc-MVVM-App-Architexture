import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:restart_app/restart_app.dart';
import '../auth/auth_guard.dart';
import '../custom_transition_builders.dart';
import '../storage/secure_storage.dart';
import '../di/service_locator.dart';
import '../config/app_config.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';
import '../services/background_service.dart';
import '../services/location_service.dart';
import '../services/network_service.dart';
import '../services/gallery_service.dart';
import '../services/offline_sync_service.dart';
import '../utils/custom_bottom_sheets.dart';
import '../utils/confetti_manager.dart';
import '../widgets/app_svg_viewer.dart';
import '../widgets/app_lottie_viewer.dart';
import '../extensions/context_extensions.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../utils/toast_manager.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: ToastManager.navigatorKey,
    initialLocation: '/',
    redirect: AuthGuard.redirect,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionBuilders.fadeTransitionPage<void>(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionBuilders.fadeTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/camera',
        pageBuilder: (context, state) => CustomTransitionBuilders.fadeTransitionPage<String>(
          key: state.pageKey,
          child: const CustomCameraPage(),
        ),
      ),
      GoRoute(
        path: '/shared-media',
        pageBuilder: (context, state) {
          final filePaths = state.extra as List<String>? ?? [];
          return CustomTransitionBuilders.fadeTransitionPage<void>(
            key: state.pageKey,
            child: SharedMediaPage(filePaths: filePaths),
          );
        },
      ),
    ],
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _screenshotProtected = true;
  String _locationText = 'Tap below to fetch your high-accuracy GPS coordinates';
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;

  List<String> _selectedMediaPaths = [];

  // Offline queue testing variables
  int _pendingSyncCount = 0;
  final _simulatedDataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initNetworkWatcher();
    _refreshPendingCount();
  }

  Future<void> _initNetworkWatcher() async {
    final connected = await NetworkService.isConnected();
    if (mounted) {
      setState(() {
        _isOffline = !connected;
      });
    }

    _networkSubscription = NetworkService.onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOffline = offline;
        });
        _refreshPendingCount();
        if (context.mounted) {
          context.showSnackBar(
            offline ? 'You are offline!' : 'You are back online!',
            backgroundColor: offline ? context.colors.error : Colors.green,
          );
        }
      }
    });
  }

  Future<void> _refreshPendingCount() async {
    final pending = await OfflineSyncService.getPendingRequests();
    if (mounted) {
      setState(() {
        _pendingSyncCount = pending.length;
      });
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _simulatedDataController.dispose();
    super.dispose();
  }

  void _showMediaSelectorBottomSheet() {
    CustomBottomSheets.showActionSheet<void>(
      context: context,
      title: 'Choose Media Source',
      subtitle: 'Capture new photos/videos or pick from your gallery',
      isGrid: true,
      options: [
        BottomSheetOption(
          icon: Icons.photo_camera,
          title: 'Camera',
          onTap: () async {
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final navigator = GoRouter.of(context);
            final result = await navigator.push<String>('/camera');
            if (result != null) {
              setState(() {
                _selectedMediaPaths = [result];
              });
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Camera capture saved successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BottomSheetOption(
          icon: Icons.photo,
          title: 'Single Image',
          onTap: () async {
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final path = await GalleryService.pickSingleImage();
            if (path != null) {
              setState(() {
                _selectedMediaPaths = [path];
              });
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Single image loaded from gallery!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BottomSheetOption(
          icon: Icons.collections,
          title: 'Multi-Images',
          onTap: () async {
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final paths = await GalleryService.pickMultiImages();
            if (paths.isNotEmpty) {
              setState(() {
                _selectedMediaPaths = paths;
              });
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Loaded ${paths.length} images from gallery!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BottomSheetOption(
          icon: Icons.video_library,
          title: 'Gallery Video',
          onTap: () async {
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final path = await GalleryService.pickVideo();
            if (path != null) {
              setState(() {
                _selectedMediaPaths = [path];
              });
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Video loaded from gallery!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final themeState = context.watch<ThemeBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            icon: Icon(themeState.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              context.read<ThemeBloc>().add(ToggleThemeEvent(!themeState.isDark));
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await getIt<SecureStorage>().clearAll();
              if (context.mounted) {
                GoRouter.of(context).go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to ${config.appName}!',
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Network Status Banner
              Card(
                color: _isOffline ? context.colors.errorContainer : Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        _isOffline ? Icons.wifi_off : Icons.wifi,
                        color: _isOffline ? context.colors.onErrorContainer : Colors.green.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isOffline ? 'Network: Offline (Running in Local Cache fallback)' : 'Network: Connected / Online',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isOffline ? context.colors.onErrorContainer : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flavor: ${config.flavor.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('API Base URL: ${config.baseUrl}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Advanced Features Showcase',
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // UI Delight & Session Panels (Restart app & Confetti)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('UX Delight & Control Utilities', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.celebration, color: Colors.amber),
                              label: const Text('Confetti!'),
                              onPressed: () {
                                ConfettiManager.play();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.restart_alt, color: Colors.red),
                              label: const Text('Restart App'),
                              onPressed: () {
                                Restart.restartApp();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              label: const Text('Success Toast'),
                              onPressed: () {
                                ToastManager.showSuccess('Operation completed successfully!');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.error, color: Colors.red),
                              label: const Text('Error Toast (2 Lines)'),
                              onPressed: () {
                                ToastManager.showError('This is an extremely long error message simulated to test the maximum line clamping. It should cleanly truncate at exactly two lines and display ellipses instead of spilling further!');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Offline Sync & Cache Fallback Panel (New Feature)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Offline First Sync Queue', style: context.textTheme.titleSmall),
                          Chip(
                            label: Text('Queue: $_pendingSyncCount'),
                            backgroundColor: _pendingSyncCount > 0 ? Colors.orange.shade100 : Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _simulatedDataController,
                        decoration: const InputDecoration(
                          labelText: 'Simulated Form Input (Test Sync)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send_and_archive),
                        label: const Text('Submit simulated API request'),
                        onPressed: () async {
                          if (_simulatedDataController.text.trim().isEmpty) {
                            context.showErrorSnackBar('Enter some input text first.');
                            return;
                          }
                          
                          // Mocking an offline request enqueue
                          await OfflineSyncService.enqueueRequest(
                            path: '/user/save-settings',
                            method: 'POST',
                            data: {'input': _simulatedDataController.text},
                          );
                          
                          _simulatedDataController.clear();
                          await _refreshPendingCount();
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync_alt),
                        label: const Text('Force Trigger Queue Synchronization'),
                        onPressed: () async {
                          await OfflineSyncService.syncPendingRequests();
                          await _refreshPendingCount();
                          ConfettiManager.play(); // Celebrate sync completion!
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Vector & Animation Renderer (SVG / Lottie)', style: context.textTheme.titleSmall),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text('Adaptive SVG Icon', style: context.textTheme.bodySmall),
                              const SizedBox(height: 12),
                              const AppSvgViewer(
                                path: 'https://pub.dev/static/img/pub-dev-logo-2x.svg',
                                source: SvgSource.network,
                                width: 80,
                                height: 80,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Adaptive Lottie', style: context.textTheme.bodySmall),
                              const SizedBox(height: 12),
                              const AppLottieViewer(
                                path: 'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json',
                                source: LottieSource.network,
                                width: 80,
                                height: 80,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Camera & Gallery Controller', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      
                      if (_selectedMediaPaths.isNotEmpty) ...[
                        const Text('Selected / Captured Media Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedMediaPaths.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final path = _selectedMediaPaths[index];
                              final isVideo = path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov');
                              
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  width: 100,
                                  color: context.colors.surfaceContainerHighest,
                                  child: isVideo
                                      ? const Center(child: Icon(Icons.video_library, size: 40))
                                      : Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(child: Icon(Icons.broken_image));
                                          },
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      ElevatedButton.icon(
                        icon: const Icon(Icons.perm_media),
                        label: const Text('Open Unified Media Bottom Sheet'),
                        onPressed: _showMediaSelectorBottomSheet,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Geolocation Utility', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _locationText,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Current GPS Position'),
                        onPressed: () async {
                          if (context.mounted) {
                            setState(() {
                              _locationText = 'Requesting permission & fetching coordinates...';
                            });
                          }
                          final position = await LocationService.getCurrentLocation();
                          if (context.mounted) {
                            if (position != null) {
                              setState(() {
                                _locationText = 'Latitude: ${position.latitude.toStringAsFixed(6)}\nLongitude: ${position.longitude.toStringAsFixed(6)}\nAccuracy: ${position.accuracy.toStringAsFixed(1)} meters\nTimestamp: ${position.timestamp.toLocal()}';
                              });
                              context.showSuccessSnackBar('GPS location fetched successfully!');
                            } else {
                              setState(() {
                                _locationText = 'Could not retrieve coordinates. Verify GPS and permissions.';
                              });
                              context.showErrorSnackBar('Location request failed.');
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings_applications),
                        label: const Text('Open Device GPS Settings'),
                        onPressed: () async {
                          await LocationService.openLocationSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Sharing & Communication (Android/iOS)', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Share App Info'),
                        onPressed: () async {
                          await Share.share(
                            'Hey! Check out this awesome high-performance Flutter app. Powered by BLoC, GoRouter, secure storage, and local notifications!',
                            subject: 'Discover ${config.appName}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Notifications Control', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Show Instant Notification'),
                        onPressed: () async {
                          await NotificationService.requestPermissions();
                          await NotificationService.showNotification(
                            id: 100,
                            title: 'Instant Alert',
                            body: 'This is an instant notification from Flutter App!',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.timer),
                        label: const Text('Schedule Alert (5s delay)'),
                        onPressed: () async {
                          await NotificationService.requestPermissions();
                          final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
                          await NotificationService.scheduleNotification(
                            id: 101,
                            title: 'Scheduled Alert',
                            body: 'This was scheduled 5 seconds ago!',
                            scheduledDate: scheduledTime,
                          );
                          if (context.mounted) {
                            context.showSuccessSnackBar('Notification scheduled for 5 seconds from now.');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Device & Data Security', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Screenshot Blocker'),
                        subtitle: const Text('Prevents screenshots & recordings'),
                        value: _screenshotProtected,
                        onChanged: (bool value) async {
                          if (value) {
                            await SecurityService.enableScreenshotProtection();
                          } else {
                            await SecurityService.disableScreenshotProtection();
                          }
                          setState(() {
                            _screenshotProtected = value;
                          });
                          if (context.mounted) {
                            context.showSnackBar(
                              value ? 'Screenshot protection turned ON' : 'Screenshot protection turned OFF',
                            );
                          }
                        },
                      ),
                      const Divider(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Test Biometric Auth'),
                        onPressed: () async {
                          final canUse = await SecurityService.canUseBiometrics();
                          if (!canUse) {
                            if (context.mounted) {
                              context.showErrorSnackBar('Biometric hardware is not available on this device.');
                            }
                            return;
                          }
                          final success = await SecurityService.authenticate(
                            localizedReason: 'Verify your identity to authenticate',
                          );
                          if (context.mounted) {
                            if (success) {
                              context.showSuccessSnackBar('Biometrics verified successfully!');
                            } else {
                              context.showErrorSnackBar('Authentication failed.');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Background Processing', style: context.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.sync),
                        label: const Text('Register Periodic Sync Task (15m)'),
                        onPressed: () async {
                          await BackgroundTaskService.registerPeriodicSyncTask();
                          if (context.mounted) {
                            context.showSuccessSnackBar('Periodic background sync task registered.');
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel All Tasks'),
                        onPressed: () async {
                          await BackgroundTaskService.cancelAllTasks();
                          if (context.mounted) {
                            context.showSnackBar('All background tasks cancelled.');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomCameraPage extends StatelessWidget {
  const CustomCameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photoAndVideo(),
        onMediaTap: (mediaCapture) {
          final path = mediaCapture.captureRequest.path;
          if (path != null) {
            Navigator.of(context).pop(path);
          }
        },
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(SensorPosition.back),
          aspectRatio: CameraAspectRatios.ratio_16_9,
        ),
        previewFit: CameraPreviewFit.cover,
      ),
    );
  }
}

class SharedMediaPage extends StatefulWidget {
  final List<String> filePaths;

  const SharedMediaPage({super.key, required this.filePaths});

  @override
  State<SharedMediaPage> createState() => _SharedMediaPageState();
}

class _SharedMediaPageState extends State<SharedMediaPage> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Shared Media'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.system_update_alt,
              size: 64,
              color: context.colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'You received ${widget.filePaths.length} shared file(s)!',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.filePaths.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final path = widget.filePaths[index];
                  final isVideo = path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov');

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      width: 180,
                      color: context.colors.surfaceContainerHighest,
                      child: isVideo
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library, size: 50, color: Colors.blue),
                                  SizedBox(height: 8),
                                  Text('Shared Video', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            )
                          : Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, size: 40));
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: 'Add Caption / Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.closed_caption),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Media & Caption'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () async {
                await NotificationService.showNotification(
                  id: 200,
                  title: 'Upload Successful',
                  body: 'Shared media files and caption uploaded successfully!',
                );
                if (context.mounted) {
                  context.showSuccessSnackBar('Shared files uploaded and logged successfully!');
                  context.pop();
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Cancel & Return Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  await getIt<SecureStorage>().saveAccessToken('mock-jwt-access-token');
                  await getIt<SecureStorage>().saveRefreshToken('mock-jwt-refresh-token');
                  if (context.mounted) {
                    GoRouter.of(context).go('/');
                  }
                },
                child: const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
