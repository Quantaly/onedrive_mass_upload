import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../combo_meal.dart';
import 'logging_utils.dart';

Future<String> getDriveRootId(ComboMeal meal) async {
  var resp =
      await meal.client.get("https://graph.microsoft.com/v1.0/me/drive/root");
  return jsonDecode(resp.body)["id"];
}

Future<String> createUploadSession(ComboMeal meal, String filePath,
    {String conflictBehavior = "replace"}) async {
  var resp = await meal.client.post(
      "https://graph.microsoft.com/v1.0/me/drive/root:/$filePath:"
      "/createUploadSession",
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "item": {
          "@microsoft.graph.conflictBehavior": conflictBehavior,
        },
      }));
  meal.logger.d(formatResponse(resp));
  return jsonDecode(resp.body)["uploadUrl"];
}

const maxChunkSize = 62914560; // greatest multiple of 320 KiB less than 60 MiB

/// Returns the start of the next expected range
Future<int> uploadBytes(ComboMeal meal, String uploadUrl, List<int> bytes,
    {@required int startingOffset, @required int fileSize}) async {
  meal.logger.d(bytes.length);
  var resp = await meal.client.put(uploadUrl,
      headers: {
        //"Content-Length": "${bytes.length}",
        "Content-Range": "bytes $startingOffset-"
            "${startingOffset + bytes.length - 1}/$fileSize",
      },
      body: bytes);
  meal.logger.d(formatResponse(resp));
  if (resp.statusCode == 202) {
    return int.parse((jsonDecode(resp.body)["nextExpectedRanges"][0] as String)
        .split("-")[0]);
  } else {
    return -1;
  }
}
