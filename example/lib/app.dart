import 'dart:math';

import 'package:example/pages/base_page.dart';
import 'package:example/pages/page_1.dart';
import 'package:example/pages/page_2.dart';
import 'package:example/pages/page_3.dart';
import 'package:example/pages/page_4.dart';
import 'package:example/routes.dart' as routes;
import 'package:flutter/material.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({Key? key, this.route}) : super(key: key);

  final String? route;

  static Map<String, Widget Function(BuildContext)> routesApp = {
    routes.page1: (_) => const Page1(),
    routes.page2: (_) => const Page2(),
    routes.page3: (_) => const Page3(),
    routes.page4: (_) => const Page4(),
  };

  @override
  Widget build(BuildContext context) {
    final r = route ?? routes.page1;
    return MaterialApp(
      title: 'Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: r,
      onUnknownRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BasePage(
            title: r,
            color:
                Color.lerp(Colors.red, Colors.orange, Random().nextDouble())!,
          ),
        );
      },
      routes: routesApp,
    );
  }
}
