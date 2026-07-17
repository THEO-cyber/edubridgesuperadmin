import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'app/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const ProviderScope(child: EduBridgeAdminApp()));
}

class EduBridgeAdminApp extends ConsumerStatefulWidget {
  const EduBridgeAdminApp({super.key});

  @override
  ConsumerState<EduBridgeAdminApp> createState() => _EduBridgeAdminAppState();
}

class _EduBridgeAdminAppState extends ConsumerState<EduBridgeAdminApp> {
  @override
  void initState() {
    super.initState();
    // Wire after first frame so both providers are fully initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiClientProvider).setSessionExpiredCallback(() {
        ref.read(authProvider.notifier).handleSessionExpired();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EduBridge Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
