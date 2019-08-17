import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/plan.dart';

Future<void> main(List<String> args) async {
  exitCode = await (CommandRunner<int>(
          "onedrive_mass_upload", "Mass uploads to Microsoft OneDrive")
        ..addCommand(PlanCommand()))
      .run(args) ?? 0;
}
