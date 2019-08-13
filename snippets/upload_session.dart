import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:onedrive_mass_upload/server.dart';
import 'package:logger/logger.dart';

void main() async {
  var oauthSettings = jsonDecode(await File("oauth.json").readAsString());

  var client = await authorize(oauthSettings["app_id"]);
  final meal = ComboMeal(
      client: client,
      logger: Logger(
        filter: ProductionFilter(),
        printer: PrettyPrinter(printEmojis: false),
      ));

  meal.logger.i("Starting");

  var uploadSession = await createUploadSession(meal, "aaaaa/bbbbb.txt");

  meal.logger.i("Upload session is ready");

  var byteses = messages.map(utf8.encode).toList();
  var fileSize = byteses.fold(0, (l, m) => l + m.length);

  var startingOffset = 0;
  for (var bytes in byteses) {
    meal.logger.i(
        "Uploading bytes $startingOffset-${bytes.length + startingOffset - 1}/$fileSize");
    await uploadBytes(meal, uploadSession, bytes,
        startingOffset: startingOffset, fileSize: fileSize);
    startingOffset += bytes.length;
  }

  client.close();
}

const messages = [
  "teh raine inne Spaine",
  " falles mainely inne ",
  "your mom lol"
];
