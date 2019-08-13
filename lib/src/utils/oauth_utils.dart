import 'dart:io';

import 'package:oauth2/oauth2.dart';

/// plz only use *before* spawning isolates
Future<Client> authorize(String appId) {
  const urlPrefix = "https://login.microsoftonline.com/common/oauth2/v2.0";
  var granter = AuthorizationCodeGrant(
    /* identifier: */ appId,
    /* authorizationEndpoint: */ Uri.parse("$urlPrefix/authorize"),
    /* tokenEndpoint: */ Uri.parse("$urlPrefix/token"),
  );

  print(granter.getAuthorizationUrl(
      Uri.parse("https://login.microsoftonline.com/common/oauth2/nativeclient"),
      scopes: ["User.Read", "Files.ReadWrite"]));

  stdout.write("plz paste the code> ");
  return granter.handleAuthorizationCode(stdin.readLineSync());
}
