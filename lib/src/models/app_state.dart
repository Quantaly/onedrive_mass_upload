import 'package:json_annotation/json_annotation.dart';
import 'package:oauth2/oauth2.dart';

part 'app_state.g.dart';

@JsonSerializable()
class AppState {
  String localDirectory;
  String cloudDirectoryId;

  List<String> filesToUpload;
  List<String> uploaded;

  Credentials credentials;

  String currentUploadFile;
  String currentUploadSession;

  AppState();
  factory AppState.fromJson(Map<String, dynamic> json) =>
      _$AppStateFromJson(json);

  Map<String, dynamic> toJson() => _$AppStateToJson(this);
}
