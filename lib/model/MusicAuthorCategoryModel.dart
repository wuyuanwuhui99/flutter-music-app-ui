class MusicAuthorCategoryModel{
  int id;// 分类id
  String categoryName;// 歌手分类名称
  int? rank;// 排名
  int disabled;// 是否禁用
  String createTime;// 创建时间
  String updateTime;// 更新时间
  MusicAuthorCategoryModel({
    required this.id,// 分类id
    required this.categoryName,// 歌手分类名称
    this.rank,// 排名
    required this.disabled,// 是否禁用
    required this.createTime,// 创建时间
    required this.updateTime// 更新时间
  });

  //工厂模式-用这种模式可以省略New关键字
  factory MusicAuthorCategoryModel.fromJson(dynamic json){
    return MusicAuthorCategoryModel(
        id:json["id"],
        categoryName:json["categoryName"],
        rank:json["rank"],
        disabled:json["disabled"],
        createTime:json["createTime"],
        updateTime:json["updateTime"]
    );
  }
}