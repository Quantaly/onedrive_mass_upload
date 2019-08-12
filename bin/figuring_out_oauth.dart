import 'dart:convert';
import 'dart:io';

import 'package:oauth2/oauth2.dart' as o;

void main(List<String> arguments) async {
  var oauthSettings = jsonDecode(await File("oauth.json").readAsString());

  const urlPrefix = "https://login.microsoftonline.com/common/oauth2/v2.0";
  var granter = o.AuthorizationCodeGrant(
    /* identifier: */ oauthSettings["app_id"],
    /* authorizationEndpoint: */ Uri.parse("$urlPrefix/authorize"),
    /* tokenEndpoint: */ Uri.parse("$urlPrefix/token"),
  );

  print(granter.getAuthorizationUrl(
      Uri.parse("https://login.microsoftonline.com/common/oauth2/nativeclient"),
      scopes: ["User.Read", "Files.ReadWrite"]));

  stdout.write("code> ");
  var client = await granter.handleAuthorizationCode(stdin.readLineSync());

  var resp = await client
      .get("https://graph.microsoft.com/v1.0/me/drive/root/children");
  print("${resp.statusCode} ${resp.reasonPhrase}");
  print(resp.body);
}
