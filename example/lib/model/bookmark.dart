import 'package:epub_view_example/utils/model_keys.dart';

class BookmarkModel {
  int? id;
  int? bookmarkedindex;
  String? title;
  List<NoteModel>? note;

  BookmarkModel({this.id, this.bookmarkedindex, this.note});

  BookmarkModel.fromJson(Map<String, dynamic> json) {
    id = json[BookmarkKeys.id];
    title = json[BookmarkKeys.title];
    bookmarkedindex = json[BookmarkKeys.bookmarkedindex];
    if (json[BookmarkKeys.note] != null) {
      note = <NoteModel>[];
      json[BookmarkKeys.note].forEach((v) {
        note!.add(NoteModel.fromJson(v));
      });
    }
  }
}

class NoteModel {
  int? id;
  String? notetext;

  NoteModel({
    this.id,
    this.notetext,
  });

  NoteModel.fromJson(Map<String, dynamic> json) {
    id = json[BookmarkKeys.id];
    notetext = json[BookmarkKeys.notetext];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data[BookmarkKeys.id] = id;
    data[BookmarkKeys.notetext] = notetext;
    return data;
  }
}
