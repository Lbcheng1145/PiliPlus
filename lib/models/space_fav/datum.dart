import 'package:PiliPlus/models/space_fav/media_list_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'datum.g.dart';

@JsonSerializable()
class SpaceFavData {
  int? id;
  String? name;
  MediaListResponse? mediaListResponse;
  String? uri;

  SpaceFavData({this.id, this.name, this.mediaListResponse, this.uri});

  factory SpaceFavData.fromJson(Map<String, dynamic> json) =>
      _$DatumFromJson(json);

  Map<String, dynamic> toJson() => _$DatumToJson(this);
}
