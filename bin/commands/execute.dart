import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logger/logger.dart';
import 'package:oauth2/oauth2.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

import 'package:onedrive_mass_upload/bin.dart';

class ExecuteCommand extends Command<int> {
  @override
  final name = "execute";
  @override
  final description = "Upload files.";

  ExecuteCommand() {
    argParser
      ..addOption(
        "state",
        abbr: 's',
        help: "The file to load the state from and save the state to.",
        defaultsTo: "upload_state.json",
      )
      ..addOption("service-port",
          abbr: 'p',
          help: "The port to run the HTTP status viewer on.",
          defaultsTo: "8888")
      ..addOption(
        "service-hostname",
        help: "The hostname to run the HTTP status viewer on.",
        defaultsTo: "localhost",
      );
  }

  @override
  Future<int> run() async {
    var logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(printEmojis: false),
    );
    Logger.level = Level.debug;

    var stateFile = File(argResults["state"]);

    if (!await stateFile.exists()) {
      logger.e("State file does not exist");
      return -1;
    }

    // setup state
    var state = AppState.fromJson(jsonDecode(await stateFile.readAsString()));
    var stateIndex = 0;
    void setState([void Function() callback]) {
      if (callback != null) callback();
      var index = stateIndex++;
      logger.v("Saving state $index");
      stateFile.writeAsString(jsonEncode(state)).then((_) {
        logger.v("State $index saved");
      });
    }

    var client = Client(state.credentials, identifier: await appId,
        onCredentialsRefreshed: (cr) {
      logger.d("Credentials refreshed");
      setState(() => state.credentials = cr);
    });
    var meal = ComboMeal(client: client, logger: logger);

    // resume progress
    RandomAccessFile uploadFile;
    int fileSize;
    int currentOffset;
    if (state.currentUploadSession != null) {
      if (state.currentUploadFile == null) {
        logger.w("Upload session is not null but upload file is, "
            "discarding upload session");
        setState(() => state
          ..currentUploadFile = null
          ..currentUploadSession = null);
      } else {
        var resp = await client.get(state.currentUploadSession);
        logger.d(formatResponse(resp));
        if (resp.statusCode != 200) {
          logger.w("Upload session in state not found");
          setState(() => state
            ..currentUploadFile = null
            ..currentUploadSession = null);
        } else {
          logger.i("Resuming upload of ${state.currentUploadFile}");
          uploadFile =
              await File(p.join(state.localDirectory, state.currentUploadFile))
                  .open();
          fileSize = await uploadFile.length();
          currentOffset = parseNextExpectedRanges(
              jsonDecode(resp.body)["nextExpectedRanges"].cast<String>());
          logger.d("currentOffset is $currentOffset");
        }
      }
    }

    // shelf setup
    var handler = const shelf.Pipeline().addMiddleware(
        shelf.logRequests(logger: (msg, isError) {
      if (isError) {
        logger.e(msg);
      } else {
        logger.d(msg);
      }
    })).addHandler(
        (req) => shelf.Response.ok("uploaded ${state.uploaded.length} files "
            "of ${state.filesToUpload.length}, "
            "currently uploading ${state.currentUploadFile}"));
    var server = await io.serve(handler, argResults["service-hostname"],
        int.parse(argResults["service-port"]));
    logger.i("Serving at http://${server.address.host}:${server.port}");

    // do the thing
    while (true) {
      // find a new file to upload
      if (state.currentUploadSession == null) {
        setState(() => state.currentUploadFile = state.filesToUpload.firstWhere(
            (f) => !state.uploaded.contains(f),
            orElse: () => null));
        if (state.currentUploadFile == null) {
          logger.i("Done!!!");
          client.close();
          await server.close();
          return 0;
        }
        logger.i("Starting upload of ${state.currentUploadFile}");
        var uploadSession = await createUploadSession(
            meal, state.currentUploadFile,
            rootId: state.cloudDirectoryId);
        setState(() => state.currentUploadSession = uploadSession);
        uploadFile =
            await File(p.join(state.localDirectory, state.currentUploadFile))
                .open();
        fileSize = await uploadFile.length();
        currentOffset = 0;
      }

      // upload from the current offset
      await uploadFile.setPosition(currentOffset);
      logger
          .v("Uploading ${state.currentUploadFile} from offset $currentOffset");
      currentOffset = await uploadBytes(
          meal, state.currentUploadSession, await uploadFile.read(maxChunkSize),
          fileSize: fileSize, startingOffset: currentOffset);
      logger.d("currentOffset is $currentOffset");

      // finish the completed upload
      if (currentOffset < 0) {
        logger.i("Finished uploading ${state.currentUploadFile}");
        unawaited(uploadFile.close());
        setState(() => state
          ..uploaded.add(state.currentUploadFile)
          ..currentUploadFile = null
          ..currentUploadSession = null);
      }
    }
  }
}

// Importing pedantic is for suckers.
void unawaited(Future f) {}
