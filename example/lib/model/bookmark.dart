import '../utils/model_keys.dart';

class BookmarkModel {
  int id;
  int index;
  NoteModel? note;

  BookmarkModel({ required this.id, required this.index, this.note });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
        id: json[CommonModelKeys.id],
        index: json[BookmarkKeys.index],
        note: json[BookmarkKeys.note]
    );
  }
}

class NoteModel {
  String noteText;

  NoteModel({ required this.noteText });
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