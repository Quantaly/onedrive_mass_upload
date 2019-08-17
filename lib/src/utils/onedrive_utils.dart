import 'dart:convert';

import 'package:meta/meta.dart';

import '../combo_meal.dart';
import 'logging_utils.dart';

Future<String> getDriveRootId(ComboMeal meal) async {
  var resp =
      await meal.client.get("https://graph.microsoft.com/v1.0/me/drive/root");
  return jsonDecode(resp.body)["id"];
}

final _leadingSlash = RegExp("^/");
String urlFormatDrivePath(String path) {
  return path == "/" ? "/" : (":/${path.replaceFirst(_leadingSlash, "")}:/");
}

Future<String> createUploadSession(ComboMeal meal, String filePath,
    {String rootId, String conflictBehavior = "replace"}) async {
  rootId ??= await getDriveRootId(meal);
  var resp = await meal.client.post(
      "https://graph.microsoft.com/v1.0/me/drive/items/$rootId:/$filePath:"
      "/createUploadSession",
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "item": {
          "@microsoft.graph.conflictBehavior": conflictBehavior,
        },
      }));
  meal.logger.v(formatResponse(resp));
  return jsonDecode(resp.body)["uploadUrl"];
}

const maxChunkSize = 62914560; // greatest multiple of 320 KiB less than 60 MiB

/// Returns the start of the next expected range
Future<int> uploadBytes(ComboMeal meal, String uploadUrl, List<int> bytes,
    {@required int startingOffset, @required int fileSize}) async {
  meal.logger.v(bytes.length);
  var resp = await meal.client.put(uploadUrl,
      headers: {
        //"Content-Length": "${bytes.length}",
        "Content-Range": "bytes $startingOffset-"
            "${startingOffset + bytes.length - 1}/$fileSize",
      },
      body: bytes);
  meal.logger.v(formatResponse(resp));
  if (resp.statusCode == 202) {
    return parseNextExpectedRanges(
        jsonDecode(resp.body)["nextExpectedRanges"].cast<String>());
  } else {
    return -1;
  }
}

int parseNextExpectedRanges(List<String> nextExpectedRanges) =>
    int.parse(nextExpectedRanges[0].split("-")[0]);
