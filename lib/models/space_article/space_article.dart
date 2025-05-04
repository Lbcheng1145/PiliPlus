import 'package:json_annotation/json_annotation.dart';

import 'package:PiliPlus/models/space_article/data.dart';

part 'space_article.g.dart';

@JsonSerializable()
class SpaceArticle {
  int? code;
  String? message;
  int? ttl;
  SpaceArticleData? data;

  SpaceArticle({this.code, this.message, this.ttl, this.data});

  factory SpaceArticle.fromJson(Map<String, dynamic> json) {
    return _$SpaceArticleFromJson(json);
  }

  Map<String, dynamic> toJson() => _$SpaceArticleToJson(this);
}
