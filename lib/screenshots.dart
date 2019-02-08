import 'dart:io';

import 'package:screenshots/config.dart';
import 'package:screenshots/screens.dart';
import 'package:screenshots/process_images.dart' as processImages;
import 'package:screenshots/resources.dart' as resources;
import 'package:screenshots/utils.dart' as utils;
import 'package:screenshots/fastlane.dart' as fastlane;

/// default config file name
const String kConfigFileName = 'screenshots.yaml';

/// Distinguish device OS.
enum DeviceType { android, ios }

/// Capture screenshots, process, and load into fastlane according to config file.
///
/// For each locale and emulator/simulator:
///
/// 1. Start the emulator/simulator for current locale.
/// 2. Run each integration test and capture the screenshots.
/// 3. Process the screenshots including adding a frame if required.
/// 4. Move processed screenshots to fastlane destination for upload to stores.
/// 5. Stop emulator/simulator.
Future<void> run([String configPath = kConfigFileName]) async {
  final _config = Config(configPath);
  // validate config file
  await _config.validate();

  final Map config = _config.config;
  final Map screens = await Screens().init();

  // init
  final stagingDir = config['staging'];
  await Directory(stagingDir + '/test').create(recursive: true);
  await resources.unpackScripts(stagingDir);

  // run integration tests in each android emulator for each locale and
  // process screenshots
  if (config['devices']['android'] != null)
    for (final emulatorName in config['devices']['android']) {
      for (final locale in config['locales']) {
        await emulator(emulatorName, true, stagingDir, locale);
        await clearFastlaneDir(
            screens, emulatorName, locale, DeviceType.android);

        for (final testPath in config['tests']) {
          print(
              'Capturing screenshots with test $testPath on emulator $emulatorName in locale $locale ...');
          await screenshots(testPath, stagingDir);
          // process screenshots
//          print('Capturing screenshots from  test $testPath ...');
          // process images in background
          await processImages.process(
//          processImages.process(
              screens,
              config,
              DeviceType.android,
              emulatorName,
              locale);
        }
        await emulator(emulatorName, false, stagingDir);
      }
    }

  // run integration tests in each ios simulator for each locale and
  // process screenshots
  if (config['devices']['ios'] != null)
    for (final simulatorName in config['devices']['ios']) {
      for (final locale in config['locales']) {
        simulator(simulatorName, true, stagingDir, locale);
        await clearFastlaneDir(screens, simulatorName, locale, DeviceType.ios);
        for (final testPath in config['tests']) {
          print(
              'Capturing screenshots with test $testPath on simulator $simulatorName in locale $locale ...');
          await screenshots(testPath, stagingDir);
          await processImages.process(
              screens, config, DeviceType.ios, simulatorName, locale);
        }
        simulator(simulatorName, false);
      }
    }

  print('\n\nScreen images are available in:');
  print('  ios/fastlane/screenshots');
  print('  android/fastlane/metadata/android');
  print('for upload to both Apple and Google consoles.');
  print('\nFor uploading and other automation options see:');
  print('  https://github.com/mmcc007/fledge');
  print('\nscreenshots completed successfully.');
}

/// Clear image destination
Future clearFastlaneDir(
    Map screens, deviceName, locale, DeviceType deviceType) async {
  final Map screenProps = Screens().screenProps(screens, deviceName);

  final dstDir = fastlane.path(deviceType, locale, '', screenProps['destName']);

  print('clearing $dstDir');
  await utils.clearDirectory(dstDir);
}

///
/// Run the screenshot integration test on current emulator or simulator.
///
/// Test is expected to generate a sequential number of screenshots.
///
/// Assumes the integration test captures the screen shots into a known directory using
/// provided [capture_screen.screenshot()].
///
void screenshots(String testPath, String stagingDir) async {
  // clear existing screenshots from staging area
  utils.clearDirectory('$stagingDir/test');
  // run the test
  await utils.streamCmd('flutter', ['drive', testPath]);
}

///
/// Start/stop emulator.
///
Future<void> emulator(String emulatorName, bool start,
    [String stagingDir, String locale = "en-US"]) async {
  emulatorName = emulatorName.replaceAll(' ', '_');
  if (start) {
    print('Starting emulator \'$emulatorName\' in locale $locale ...');

//    final emulatorName =
//        utils.emulators().firstWhere((emulator) => emulator.contains(name));
//    utils.cmd(
//        'bash',
//        ['-c', '\'\$ANDROID_HOME/tools/emulator -avd $emulatorName &\''],
//        '\$ANDROID_HOME/tools');

    // Note: the 'flutter build' of the test should allow enough time for emulator to start
    // otherwise, wait for emulator to start
    await utils.streamCmd('flutter', ['emulator', '--launch', emulatorName]);
    await utils.streamCmd(
        '$stagingDir/resources/script/android-wait-for-emulator', []);
    if (utils.cmd('adb', ['root'], '.', true) ==
        'adbd cannot run as root in production builds\n') {
      stdout.write(
          'warning: locale has not been changed. Running in default locale.\n');
      stdout.write(
          'To change locale you must use a non-production emulator (one that does not depend on Play Store). See:\n');
      stdout.write(
          '    https://stackoverflow.com/questions/43923996/adb-root-is-not-working-on-emulator/45668555#45668555 for details.\n');
    } else {
//      adb shell "setprop persist.sys.locale fr-CA; setprop ctl.restart zygote"
      utils.cmd('adb', [
        'shell',
        'setprop',
        'persist.sys.locale',
        locale,
        ';',
        'setprop',
        'ctl.restart',
        'zygote'
      ]);
      // note: there should be enough time to allow the emulator to restart
      // while app is being compiled.
    }
  } else {
    print('Stopping emulator: $emulatorName ...');
    utils.cmd('adb', ['emu', 'kill']);
    // wait for emulator to stop
//    utils.streamCmd(
//        '$stagingDir/resources/script/android-wait-for-emulator-to-stop', []);
  }
}

///
/// Start/stop simulator.
///
void simulator(String name, bool start,
    [String stagingDir, String locale = 'en-US']) {
  Map simulatorInfo = utils.simulators()[name];
//  print('simulatorInfo=$simulatorInfo');

  if (start) {
    if (simulatorInfo['status'] == 'Booted') {
      print('Restarting simulator \'$name\' in locale $locale ...');
      utils.cmd('xcrun', ['simctl', 'shutdown', simulatorInfo['id']]);
    } else {
      print('Starting simulator \'$name\' in locale $locale ...');
    }
    utils.streamCmd('$stagingDir/resources/script/simulator-controller',
        [name, 'locale', locale]);
    // xcrun simctl boot A23897F7-11DF-4F22-82E6-8BEB741F1990
//    if (simulatorInfo['status'] == 'Shutdown')
    utils.cmd('xcrun', ['simctl', 'boot', simulatorInfo['id']]);
  } else {
    print('Stopping simulator: $name ...');
    if (simulatorInfo['status'] == 'Booted')
      utils.cmd('xcrun', ['simctl', 'shutdown', simulatorInfo['id']]);
  }
}
