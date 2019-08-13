import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:oauth2/oauth2.dart';

/// Everything that needs to be passed around the entire server.
///
/// I couldn't think of a better name.
class ComboMeal {
  final Client client;
  final Logger logger;

  ComboMeal({@required this.client, @required this.logger});
}
