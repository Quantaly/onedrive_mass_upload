import 'package:logger/logger.dart';

void main() {
  var logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(printEmojis: false),
  );

  logger
    ..v("Verbose")
    ..d("Debug")
    ..i("Info")
    ..w("Warning")
    ..e("Error")
    ..wtf("Oh SHit");
}
