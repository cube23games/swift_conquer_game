import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sc_app/ui/swift_conquer_rts_screen.dart';
import 'sc_master/ui/sc_master_debug_screen.dart';
import 'screens/game_screen.dart';

const bool _useMasterSlice =
    bool.fromEnvironment('SC_MASTER_SLICE', defaultValue: false);
const bool _useLegacyGameScreen =
    bool.fromEnvironment('SC_LEGACY_GAME_SCREEN', defaultValue: false);

Future<void> _applyGameSystemUi() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _applyGameSystemUi();
  runApp(const SwiftConquerApp());
}

class SwiftConquerApp extends StatefulWidget {
  const SwiftConquerApp({super.key});

  @override
  State<SwiftConquerApp> createState() => _SwiftConquerAppState();
}

class _SwiftConquerAppState extends State<SwiftConquerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyGameSystemUi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyGameSystemUi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _useMasterSlice
          ? ScMasterDebugScreen()
          : _useLegacyGameScreen
              ? GameScreen()
              : SwiftConquerRtsScreen(),
    );
  }
}
