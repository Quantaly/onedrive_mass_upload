import 'package:http/http.dart' as http;

String formatResponse(http.Response r) {
  var buf = StringBuffer();
  buf.writeln("${r.statusCode} ${r.reasonPhrase}");
  for (var header in r.headers.entries) {
    buf.writeln("${header.key}: ${header.value}");
  }
  buf.writeln();
  buf.write(r.body);
  return buf.toString();
}