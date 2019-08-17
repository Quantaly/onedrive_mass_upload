import 'package:path/path.dart';

void main() {
  print(Style.posix.context.dirname("/a/b"));
  print(Style.posix.context.dirname("a/b"));
  print(Style.posix.context.dirname("/b"));
  print(Style.posix.context.dirname("b"));
}
