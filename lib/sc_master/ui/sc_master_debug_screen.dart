import 'package:flutter/material.dart';

import 'sc_master_demo_controller.dart';

class ScMasterDebugScreen extends StatefulWidget {
  const ScMasterDebugScreen({super.key});

  @override
  State<ScMasterDebugScreen> createState() => _ScMasterDebugScreenState();
}

class _ScMasterDebugScreenState extends State<ScMasterDebugScreen> {
  final ScMasterDemoController controller = ScMasterDemoController();

  void run(void Function() action) {
    setState(action);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('SwiftConquer Master Shadow Slice'),
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF172033),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Credits: ${controller.wallet.balance}   '
                        'Friendly assets: ${controller.friendlyAssets}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _button('Move Mobile HQ', controller.moveMobileHq),
                  _button('Deploy HQ', controller.deployHq),
                  _button('Harvest Ore', controller.harvestOre),
                  _button('Spawn Enemy', controller.spawnEnemy),
                  _button('Attack Enemy', controller.attackEnemy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, void Function() action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => run(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label),
        ),
      ),
    );
  }
}
