import 'dart:convert';
import 'dart:io';

import 'package:oauth2/oauth2.dart';

final Future<String> appId = () async {
  var json = await File("oauth.json").readAsString();
  return jsonDecode(json)["app_id"] as String;
}();

/// plz only use *before* spawning isolates
Future<Client> authorizeWithTerminal(String appId) {
  const urlPrefix = "https://login.microsoftonline.com/common/oauth2/v2.0";
  var granter = AuthorizationCodeGrant(
    /* identifier: */ appId,
    /* authorizationEndpoint: */ Uri.parse("$urlPrefix/authorize"),
    /* tokenEndpoint: */ Uri.parse("$urlPrefix/token"),
  );

  print(granter.getAuthorizationUrl(
      Uri.parse("https://login.microsoftonline.com/common/oauth2/nativeclient"),
      scopes: ["User.Read", "Files.ReadWrite", "offline_access"]));

  stdout.write("plz paste the code> ");
  return granter.handleAuthorizationCode(stdin.readLineSync());
}
