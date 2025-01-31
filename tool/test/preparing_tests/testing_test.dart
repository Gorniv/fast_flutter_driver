import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:fast_flutter_driver_tool/src/preparing_tests/command_line/streams.dart'
    as streams;
import 'package:fast_flutter_driver_tool/src/preparing_tests/devices.dart'
    as devices;
import 'package:fast_flutter_driver_tool/src/preparing_tests/parameters.dart';
import 'package:fast_flutter_driver_tool/src/preparing_tests/testing.dart'
    as test_executor;
import 'package:fast_flutter_driver_tool/src/running_tests/parameters.dart';
import 'package:fast_flutter_driver_tool/src/utils/system.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks/mock_file.dart';
import 'testing_test.mocks.dart';

@GenerateMocks([
  Logger,
  Directory,
  streams.InputCommandLineStream,
  Progress,
])
void main() {
  late MockLogger logger;
  setUp(() {
    logger = MockLogger();
    when(logger.trace(any)).thenAnswer((_) {});
    when(logger.stdout(any)).thenAnswer((_) {});
    when(logger.progress(any)).thenReturn(_MockProgress(''));
  });

  _MockFile createFile() {
    final file = _MockFile()
      ..fieldExistsSync = true
      ..copyMock = _MockFile()
      ..writeAsStringMock = _MockFile()
      ..renameMock = _MockFile();
    return file;
  }

  MockInputCommandLineStream createStream() {
    final mock = MockInputCommandLineStream();
    when(mock.write(any)).thenAnswer((_) {});
    when(mock.dispose()).thenAnswer((_) async {});
    return mock;
  }

  group('setup', () {
    tearDown(() {
      linuxOverride = null;
    });

    test('overrides resolution on linux', () async {
      linuxOverride = true;
      final parser = scriptParameters;
      final args = parser.parse(['-r', '1x1']);

      await IOOverrides.runZoned(
        () async {
          await test_executor.setUp(
            args,
            () async {},
            logger: logger,
          );
        },
        getCurrentDirectory: () {
          final mockDir = MockDirectory();
          when(mockDir.path).thenReturn('');
          return mockDir;
        },
        createFile: (name) {
          if (name.endsWith('window_configuration.cc_copy')) {
            return createFile()..fieldExistsSync = false;
          }
          return createFile()
            ..fieldExistsSync = true
            ..readAsStringMock = '';
        },
      );

      expect(
        verify(logger.trace(captureAny)).captured.single,
        'Overriding resolution',
      );
    });

    test('runs tests straight away on non linux', () async {
      linuxOverride = false;
      bool haveRunTests = false;

      await test_executor.setUp(
        scriptParameters.parse(['-r', '1x1']),
        () async {
          haveRunTests = true;
        },
        logger: logger,
      );

      verifyNever(logger.trace(any));
      expect(haveRunTests, isTrue);
    });
  });

  group('test', () {
    test_executor.TestExecutor tested;

    test('builds application', () {
      const flavor = 'vanilla';
      final commands = <String>[];
      tested = test_executor.TestExecutor(
        outputFactory: streams.output,
        inputFactory: streams.input,
        run: (
          String command,
          streams.OutputCommandLineStream stdout, {
          streams.InputCommandLineStream? stdin,
          streams.OutputCommandLineStream? stderr,
        }) async {
          commands.add(command);
        },
        logger: logger,
      );

      // ignore: cascade_invocations
      tested.test(
        'generic_test.dart',
        parameters: test_executor.ExecutorParameters(
          withScreenshots: false,
          language: 'pl',
          resolution: '800x600',
          platform: TestPlatform.android,
          device: devices.device,
          flavor: flavor,
          dartArguments: '',
          flutterArguments: '',
          testArguments: '',
          fvm: false,
        ),
      );

      expect(
        commands,
        contains(
          'flutter run -d ${devices.device} '
          '--target=generic.dart '
          '--flavor $flavor ',
        ),
      );
    });

    test('passes flutter arguments', () {
      const arguments = '--device-user=10 --host-vmservice-port';
      final commands = <String>[];
      tested = test_executor.TestExecutor(
        outputFactory: streams.output,
        inputFactory: streams.input,
        run: (
          String command,
          streams.OutputCommandLineStream stdout, {
          streams.InputCommandLineStream? stdin,
          streams.OutputCommandLineStream? stderr,
        }) async {
          commands.add(command);
        },
        logger: logger,
      );

      // ignore: cascade_invocations
      tested.test(
        'generic_test.dart',
        parameters: test_executor.ExecutorParameters(
          withScreenshots: false,
          language: 'pl',
          resolution: '800x600',
          platform: TestPlatform.android,
          device: devices.device,
          flutterArguments: arguments,
          dartArguments: '',
          testArguments: '',
          fvm: false,
        ),
      );

      expect(
        commands,
        contains(
          'flutter run -d ${devices.device} '
          '--target=generic.dart '
          '$arguments',
        ),
      );
    });

    test('builds application for specific device', () {
      final commands = <String>[];
      const device = 'some_special_device';
      tested = test_executor.TestExecutor(
        outputFactory: streams.output,
        inputFactory: streams.input,
        run: (
          String command,
          streams.OutputCommandLineStream stdout, {
          streams.InputCommandLineStream? stdin,
          streams.OutputCommandLineStream? stderr,
        }) async {
          commands.add(command);
        },
        logger: logger,
      );

      // ignore: cascade_invocations
      tested.test(
        'generic_test.dart',
        parameters: const test_executor.ExecutorParameters(
          withScreenshots: false,
          language: 'pl',
          resolution: '800x600',
          platform: TestPlatform.android,
          device: device,
          dartArguments: '',
          flutterArguments: '',
          testArguments: '',
          fvm: false,
        ),
      );

      expect(
        commands,
        contains('flutter run -d $device --target=generic.dart '),
      );
    });

    group('runs tests application', () {
      test('on native', () async {
        final commands = <String>[];
        const url = 'http://127.0.0.1:50512/CKxutzePXlo/';
        tested = test_executor.TestExecutor(
          outputFactory: streams.output,
          inputFactory: createStream,
          run: (
            String command,
            streams.OutputCommandLineStream stdout, {
            streams.InputCommandLineStream? stdin,
            streams.OutputCommandLineStream? stderr,
          }) async {
            commands.add(command);
            if (command.startsWith(
                'flutter run -d ${devices.device} --target=generic.dart')) {
              stdout.stream.add(
                utf8.encode(
                  ' The Flutter DevTools debugger and profiler '
                  'on macos is available at: $url',
                ),
              );
            }
          },
          logger: logger,
        );
        await tested.test(
          'generic_test.dart',
          parameters: test_executor.ExecutorParameters(
            withScreenshots: false,
            language: 'pl',
            resolution: '800x600',
            platform: TestPlatform.android,
            device: devices.device,
            dartArguments: '',
            flutterArguments: '',
            testArguments: '',
            fvm: false,
          ),
        );

        expect(
          commands,
          contains(
              'dart generic_test.dart -u http://127.0.0.1:50512/CKxutzePXlo/ -r 800x600 -l pl -p android'),
        );
      });

      test('on web', () async {
        final commands = <String>[];
        const url = 'ws://127.0.0.1:52464/rjc_-3ZH0N0=';
        tested = test_executor.TestExecutor(
          outputFactory: streams.output,
          inputFactory: createStream,
          run: (
            String command,
            streams.OutputCommandLineStream stdout, {
            streams.InputCommandLineStream? stdin,
            streams.OutputCommandLineStream? stderr,
          }) async {
            commands.add(command);
            if (command.startsWith(
                'flutter run -d ${devices.device} --target=generic.dart')) {
              stdout.stream.add(
                utf8.encode('Debug service listening on $url'),
              );
            }
          },
          logger: logger,
        );
        await tested.test(
          'generic_test.dart',
          parameters: test_executor.ExecutorParameters(
            withScreenshots: false,
            language: 'pl',
            resolution: '800x600',
            platform: TestPlatform.android,
            device: devices.device,
            dartArguments: '',
            flutterArguments: '',
            testArguments: '',
            fvm: false,
          ),
        );

        expect(
          commands,
          contains(
              'dart generic_test.dart -u $url -r 800x600 -l pl -p android'),
        );
      });
    });

    test('passes dart arguments', () async {
      const dartArgs = '--enable-experiment=non-nullable';
      final commands = <String>[];
      tested = test_executor.TestExecutor(
        outputFactory: streams.output,
        inputFactory: createStream,
        run: (
          String command,
          streams.OutputCommandLineStream stdout, {
          streams.InputCommandLineStream? stdin,
          streams.OutputCommandLineStream? stderr,
        }) async {
          commands.add(command);
          if (command.startsWith(
              'flutter run -d ${devices.device} --target=generic.dart')) {
            stdout.stream.add(
              utf8.encode(
                'The Flutter DevTools debugger and profiler '
                'on Windows is available at: http://127.0.0.1:50512/CKxutzePXlo/',
              ),
            );
          }
        },
        logger: logger,
      );
      await tested.test(
        'generic_test.dart',
        parameters: test_executor.ExecutorParameters(
          withScreenshots: false,
          language: 'pl',
          resolution: '800x600',
          platform: TestPlatform.android,
          device: devices.device,
          dartArguments: dartArgs,
          flutterArguments: '',
          testArguments: '',
          fvm: false,
        ),
      );

      expect(
        commands,
        contains(
          'dart $dartArgs generic_test.dart -u http://127.0.0.1:50512/CKxutzePXlo/ -r 800x600 -l pl -p android',
        ),
      );
    });

    test('passes test arguments', () async {
      const testArgs = 'additional arguments';
      final commands = <String>[];
      tested = test_executor.TestExecutor(
        outputFactory: streams.output,
        inputFactory: createStream,
        run: (
          String command,
          streams.OutputCommandLineStream stdout, {
          streams.InputCommandLineStream? stdin,
          streams.OutputCommandLineStream? stderr,
        }) async {
          commands.add(command);
          if (command.startsWith(
              'flutter run -d ${devices.device} --target=generic.dart')) {
            stdout.stream.add(
              utf8.encode(
                'The Flutter DevTools debugger and profiler '
                'on Windows is available at: http://127.0.0.1:50512/CKxutzePXlo/',
              ),
            );
          }
        },
        logger: logger,
      );
      await tested.test(
        'generic_test.dart',
        parameters: test_executor.ExecutorParameters(
          withScreenshots: false,
          language: 'pl',
          resolution: '800x600',
          platform: TestPlatform.android,
          device: devices.device,
          testArguments: testArgs,
          dartArguments: '',
          flutterArguments: '',
          fvm: false,
        ),
      );

      expect(
        commands,
        contains(
          'dart generic_test.dart -u http://127.0.0.1:50512/CKxutzePXlo/ -r 800x600 -l pl -p android --test-args "$testArgs"',
        ),
      );
    });
  });
}

class _MockProgress extends Progress {
  _MockProgress(String message) : super(message);

  @override
  void cancel() {}

  @override
  void finish({String? message, bool showTiming = false}) {}
}

class _MockFile extends NonMockitoFile {
  bool fieldExistsSync = false;

  @override
  bool existsSync() {
    return fieldExistsSync;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    return _MockFile();
  }
}
