// ignore_for_file: avoid_function_literals_in_foreach_calls
import 'dart:convert';

import 'package:example/routes.dart' as routes;
import 'package:fast_flutter_driver/tool.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'generic/screenshots.dart';
import 'generic/test_configuration.dart';

void main(List<String> args) {
  late FlutterDriver driver;
  final properties = TestProperties(args);

  setUpAll(() async {
    print('setUpAll start ${properties.vmUrl}');
    final url = properties.vmUrl.split('?uri=').last;
    print('url ${url}');
    driver = await FlutterDriver.connect(dartVmServiceUrl: url);
    await driver.waitUntilFirstFrameRasterized();
    print('setUpAll finish');
  });

  tearDownAll(() async {
    await driver.close();
  });

  Future<void> restart(String route) {
    print('route: restart ${route}');
    return driver.requestData(
      json.encode(
        TestConfiguration(
          resolution: properties.resolution,
          platform: properties.platform,
          route: route,
        ),
      ),
    );
  }

  group('Route navigation', () {
    [
      routes.page1,
      routes.page2,
      routes.page3,
      routes.page4,
    ].forEach((route) {
      test(route, () async {
        await restart(route);

        await driver.waitFor(find.text(route));
      });
    });
  });

  group('Speed test', () {
    List.generate(10, (index) => '/generated_page_$index').forEach((route) {
      test(route, () async {
        await restart(route);

        await driver.waitFor(find.text(route));
      });
    });

    group('with screenshots', () {
      late Screenshot screenshot;

      setUpAll(() async {
        screenshot = await Screenshot.create(driver, 'route_test',
            enabled: properties.screenshotsEnabled);
      });

      List.generate(10, (index) => '/generated_screenshots_page_$index')
          .forEach((route) {
        test(route, () async {
          await restart(route);

          await driver.waitFor(find.text(route));
          await screenshot.takeScreenshot(route);
        });
      });
    });
  });
}
