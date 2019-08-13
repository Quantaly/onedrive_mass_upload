import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:onedrive_mass_upload/server.dart';

void main() async {
  var bigfile = File("snippets/bigfile.txt");
  if (!await bigfile.exists()) {
    print("creating bigfile.txt...");
    print("This is pretty slow from Dart, generate_bigfile.go was about 6x "
        "faster on my machine if you have Go installed to compile it");
    var sink = bigfile.openWrite();
    var messageBytes =
        utf8.encode("teh raine inne Spaine falles mainely inne your mom lol\n");
    for (var i = 0; i < 6 * 1024 * 1024; i++) {
      sink.add(messageBytes);
    }
    await sink.flush();
    await sink.close();
  }

  var oauthSettings = jsonDecode(await File("oauth.json").readAsString());

  var client = await authorize(oauthSettings["app_id"]);
  final meal = ComboMeal(
      client: client,
      logger: Logger(
        filter: ProductionFilter(),
        printer: PrettyPrinter(printEmojis: false),
      ));
  Logger.level = Level.info;

  meal.logger.i("Starting");

  var uploadSession = await createUploadSession(meal, "aaaaa/bigfile.txt");

  meal.logger.i("Upload session is ready");

  var rafile = await bigfile.open();
  var fileSize = await rafile.length();

  meal.logger.i("File is open, length is $fileSize");

  var startingOffset = 0;

  while (startingOffset >= 0) {
    await rafile.setPosition(startingOffset);
    meal.logger.i("Uploading from offset $startingOffset");
    startingOffset = await uploadBytes(
        meal, uploadSession, await rafile.read(maxChunkSize),
        fileSize: fileSize, startingOffset: startingOffset);
  }
}
