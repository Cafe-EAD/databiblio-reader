import '../utils/model_keys.dart';

class BookmarkModel {
  int id;
  int index;

  BookmarkModel({ required this.id, required this.index });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
        id: json[CommonModelKeys.id],
        index: json[BookmarkKeys.index]
    );
  }
}

class PostBookmarkResponse {
  bool success;
  String message;

  PostBookmarkResponse({ required this.success, required this.message });

  factory PostBookmarkResponse.fromJson(Map<String, dynamic> json) {
    return PostBookmarkResponse(
        success: json[CommonModelKeys.success],
        message: json[CommonModelKeys.message]
    );
  }
}