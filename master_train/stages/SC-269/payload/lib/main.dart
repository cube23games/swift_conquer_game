import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sc_master/ui/sc_master_debug_screen.dart';
import 'screens/game_screen.dart';

const bool _useMasterSlice =
    bool.fromEnvironment('SC_MASTER_SLICE', defaultValue: false);

Future<void> _applyDemoSystemUi() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _applyDemoSystemUi();
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
    _applyDemoSystemUi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyDemoSystemUi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _useMasterSlice ? ScMasterDebugScreen() : GameScreen(),
    );
  }
}
