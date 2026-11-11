import 'dart:async';

import 'package:flutter/material.dart';

import 'repository/data_repository.dart';
import 'services/hive_store.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStore.init();
  runApp(FluHivApp());
}

/// Hosts both aurora themes and persists the user's choice in Hive.
class FluHivApp extends StatefulWidget {
  FluHivApp({super.key});

  final DataRepository repository = DataRepository();

  @override
  State<FluHivApp> createState() => _FluHivAppState();
}

class _FluHivAppState extends State<FluHivApp> {
  late bool _light;

  @override
  void initState() {
    super.initState();
    _light = HiveStore().isLightMode;
  }

  void _toggleTheme() {
    setState(() => _light = !_light);
    unawaited(HiveStore().setLightMode(_light));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluHiv',
      debugShowCheckedModeBanner: false,
      theme: AuroraTheme.build(Brightness.light),
      darkTheme: AuroraTheme.build(Brightness.dark),
      themeMode: _light ? ThemeMode.light : ThemeMode.dark,
      home: HomeShell(
        repository: widget.repository,
        lightMode: _light,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
