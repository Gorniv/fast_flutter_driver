import 'dart:convert';

import 'package:example/app.dart';
import 'package:fast_flutter_driver/driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'test_configuration.dart';

Future<void> main(List<String> args) async {
  print('main generic.dart');
  timeDilation = 0.1;
  enableFlutterDriverExtension(
    handler: (playload) async {
      print('playload: $playload');
      await configureTest(
        TestConfiguration.fromJson(json.decode(playload ?? '{}')),
      );
      return '';
    },
  );

  runApp(
    RestartWidget<TestConfiguration>(
        backgroundColor: Colors.red,
        builder: (_, config) {
          print('builder: ${config.route}');
          if (ExampleApp.routesApp.containsKey(config.route)) {
            return MaterialApp(
              home: Material(
                child: ExampleApp.routesApp[config.route]!(_),
              ),
            );
          }
          return MaterialApp(
            home: Material(
              child: Center(child: Text(config.route)),
            ),
          );
        }),
  );
}
