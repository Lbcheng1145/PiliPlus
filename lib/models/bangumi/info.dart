class BangumiInfoModel {
  BangumiInfoModel({
    this.activity,
    this.actors,
    this.alias,
    this.areas,
    this.bkgCover,
    this.cover,
    this.enableVt,
    this.episodes,
    this.evaluate,
    this.freya,
    this.jpTitle,
    this.link,
    this.mediaId,
    this.newEp,
    this.playStrategy,
    this.positive,
    this.publish,
    this.rating,
    this.record,
    this.rights,
    this.seasonId,
    this.seasonTitle,
    this.seasons,
    this.series,
    this.shareCopy,
    this.shareSubTitle,
    this.shareUrl,
    this.show,
    this.showSeasonType,
    this.squareCover,
    this.stat,
    this.status,
    this.styles,
    this.subTitle,
    this.title,
    this.total,
    this.type,
    this.userStatus,
    this.staff,
  });

  Map? activity;
  String? actors;
  String? alias;
  List? areas;
  String? bkgCover;
  String? cover;
  String? enableVt;
  List<EpisodeItem>? episodes;
  String? evaluate;
  Map? freya;
  String? jpTitle;
  String? link;
  int? mediaId;
  Map? newEp;
  Map? playStrategy;
  Map? positive;
  Map? publish;
  Map? rating;
  String? record;
  Map? rights;
  int? seasonId;
  String? seasonTitle;
  List? seasons;
  Map? series;
  String? shareCopy;
  String? shareSubTitle;
  String? shareUrl;
  Map? show;
  int? showSeasonType;
  String? squareCover;
  Map? stat;
  int? status;
  List? styles;
  String? subTitle;
  String? title;
  int? total;
  int? type;
  UserStatus? userStatus;
  String? staff;
  List<Section>? section;

  BangumiInfoModel.fromJson(Map<String, dynamic> json) {
    activity = json['activity'];
    actors = json['actors'];
    alias = json['alias'];
    areas = json['areas'];
    bkgCover = json['bkg_cover'];
    cover = json['cover'];
    enableVt = json['enableVt'];
    episodes = (json['episodes'] as List?)
        ?.map<EpisodeItem>((e) => EpisodeItem.fromJson(e))
        .toList();
    evaluate = json['evaluate'];
    freya = json['freya'];
    jpTitle = json['jp_title'];
    link = json['link'];
    mediaId = json['media_id'];
    newEp = json['new_ep'];
    playStrategy = json['play_strategy'];
    positive = json['positive'];
    publish = json['publish'];
    rating = json['rating'];
    record = json['record'];
    rights = json['rights'];
    seasonId = json['season_id'];
    seasonTitle = json['season_title'];
    seasons = json['seasons'];
    series = json['series'];
    shareCopy = json['share_copy'];
    shareSubTitle = json['share_sub_title'];
    shareUrl = json['share_url'];
    show = json['show'];
    showSeasonType = json['show_season_type'];
    squareCover = json['square_cover'];
    stat = json['stat'];
    status = json['status'];
    styles = json['styles'];
    subTitle = json['sub_title'];
    title = json['title'];
    total = json['total'];
    type = json['type'];
    if (json['user_status'] != null) {
      userStatus = UserStatus.fromJson(json['user_status']);
    }
    staff = json['staff'];
    section = (json['section'] as List?)
        ?.map((item) => Section.fromJson(item))
        .toList();
  }
}

class Section {
  Section({
    this.episodes,
  });
  List<EpisodeItem>? episodes;

  Section.fromJson(Map<String, dynamic> json) {
    episodes = (json['episodes'] as List?)
        ?.map<EpisodeItem>((e) => EpisodeItem.fromJson(e))
        .toList();
  }
}

class EpisodeItem {
  EpisodeItem({
    this.aid,
    this.badge,
    this.badgeInfo,
    this.badgeType,
    this.bvid,
    this.cid,
    this.cover,
    this.dimension,
    this.duration,
    this.enableVt,
    this.epId,
    this.from,
    this.id,
    this.isViewHide,
    this.link,
    this.longTitle,
    this.pubTime,
    this.pv,
    this.releaseDate,
    this.rights,
    this.shareCopy,
    this.shareUrl,
    this.shortLink,
    this.skip,
    this.status,
    this.subtitle,
    this.title,
    this.vid,
    this.showTitle,
  });

  int? aid;
  String? badge;
  Map? badgeInfo;
  int? badgeType;
  String? bvid;
  int? cid;
  String? cover;
  Map? dimension;
  int? duration;
  bool? enableVt;
  int? epId;
  String? from;
  int? id;
  bool? isViewHide;
  String? link;
  String? longTitle;
  int? pubTime;
  int? pv;
  String? releaseDate;
  Map? rights;
  String? shareCopy;
  String? shareUrl;
  String? shortLink;
  Map? skip;
  int? status;
  String? subtitle;
  String? title;
  String? vid;
  String? showTitle;

  EpisodeItem.fromJson(Map<String, dynamic> json) {
    aid = json['aid'];
    badge = json['badge'] != '' ? json['badge'] : null;
    badgeInfo = json['badge_info'];
    badgeType = json['badge_type'];
    bvid = json['bvid'];
    cid = json['cid'];
    cover = json['cover'];
    dimension = json['dimension'];
    duration = json['duration'];
    enableVt = json['enable_vt'];
    epId = json['ep_id'];
    from = json['from'];
    id = json['id'];
    isViewHide = json['is_view_hide'];
    link = json['link'];
    longTitle = json['long_title'];
    pubTime = json['pub_time'];
    pv = json['pv'];
    releaseDate = json['release_date'];
    rights = json['rights'];
    shareCopy = json['share_copy'];
    shareUrl = json['share_url'];
    shortLink = json['short_link'];
    skip = json['skip'];
    status = json['status'];
    subtitle = json['subtitle'];
    title = json['title'];
    vid = json['vid'];
    showTitle = json['show_title'];
  }
}

class UserStatus {
  UserStatus({
    this.areaLimit,
    this.banAreaShow,
    this.follow,
    this.followStatus,
    this.login,
    this.pay,
    this.payPackPaid,
    this.progress,
    this.sponsor,
    this.vipInfo,
  });
  int? areaLimit;
  int? banAreaShow;
  int? follow;
  int? followStatus;
  int? login;
  int? pay;
  int? payPackPaid;
  UserProgress? progress;
  int? sponsor;
  VipInfo? vipInfo;
  UserStatus.fromJson(Map<String, dynamic> json) {
    areaLimit = json['area_limit'];
    banAreaShow = json['ban_area_show'];
    follow = json['follow'];
    followStatus = json['follow_status'];
    login = json['login'];
    pay = json['pay'];
    payPackPaid = json['pay_pack_paid'];
    if (json['progress'] != null) {
      progress = UserProgress.fromJson(json['progress']);
    }
    sponsor = json['sponsor'];
    if (json['vip_info'] != null) {
      vipInfo = VipInfo.fromJson(json['vip_info']);
    }
  }
}

class UserProgress {
  UserProgress({
    this.lastEpId,
    this.lastEpIndex,
    this.lastTime,
  });
  int? lastEpId;
  String? lastEpIndex;
  int? lastTime;
  UserProgress.fromJson(Map<String, dynamic> json) {
    lastEpId = json['last_ep_id'];
    lastEpIndex = json['last_ep_index'];
    lastTime = json['last_time'];
  }
}

class VipInfo {
  VipInfo({
    this.dueDate,
    this.status,
    this.type,
  });
  int? dueDate;
  int? status;
  int? type;
  VipInfo.fromJson(Map<String, dynamic> json) {
    dueDate = json['due_date'];
    status = json['status'];
    type = json['type'];
  }
}
