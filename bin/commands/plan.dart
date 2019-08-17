import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:onedrive_mass_upload/bin.dart';

// TODO include/exclude, autostart
class PlanCommand extends Command<int> {
  @override
  final name = "plan";
  @override
  final description = "Create an initial state to be executed.";

  PlanCommand() {
    argParser
      ..addOption(
        "local-path",
        abbr: 'l',
        help: "The local directory from which to recursively upload files.",
      )
      ..addOption(
        "cloud-path",
        abbr: 'c',
        help: "The path from the root of your OneDrive to upload files to.\n"
            "(directory must already exist)",
      )
      ..addOption(
        "output-file",
        abbr: 'o',
        help: "The file to initialize the state to.",
        defaultsTo: "upload_state.json",
      );
  }

  @override
  Future<int> run() async {
    var localPath = argResults["local-path"],
        cloudPath = argResults["cloud-path"],
        outputFile = argResults["output-file"];

    if (localPath == null || cloudPath == null || outputFile == null) {
      print("--local-path and --cloud-path are required.");
      return -1;
    }

    var client = await authorizeWithTerminal(await appId);

    var state = AppState();
    try {
      state
        ..localDirectory = p.absolute(localPath)
        ..cloudDirectoryId = await () async {
          var resp =
              await client.get("https://graph.microsoft.com/v1.0/me/drive/root"
                  "${urlFormatDrivePath(cloudPath)}");
          //print(formatResponse(resp));
          if (resp.statusCode == 404) {
            print("Please create the cloud directory first.");
            throw -1;
          }
          Map<String, dynamic> driveItem = jsonDecode(resp.body);
          if (!driveItem.containsKey("folder")) {
            print("Please specify a directory with --cloud-path.");
            throw -1;
          }
          return jsonDecode(resp.body)["id"];
        }()
        ..filesToUpload = await Directory(localPath)
            .list(recursive: true)
            .where((fse) => fse is File)
            .map((f) => p.relative(f.path, from: localPath))
            .toList()
        ..uploaded = []
        ..credentials = client.credentials;
    } on int catch (e) {
      return e;
    } on FileSystemException {
      print("Please specify an accessible directory with --local-path.");
      return -1;
    }

    var outfile = File(outputFile);
    await outfile.writeAsString(jsonEncode(state));

    client.close();

    return 0;
  }
}
