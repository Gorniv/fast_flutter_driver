import 'dart:convert';

import 'package:fast_flutter_driver/driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'test_configuration.dart';

Future<void> main() async {
  timeDilation = 0.1;
  enableFlutterDriverExtension(
    handler: (playload) async {
      await configureTest(
        TestConfiguration.fromJson(json.decode(playload ?? '{}')),
      );
      return '';
    },
  );
  runApp(
    RestartWidget<TestConfiguration>(
      backgroundColor: Colors.red,
      builder: (_, config) => MaterialApp(
        home: Material(
          child: Center(child: Text(config.route)),
        ),
      ),
    ),
  );
}
