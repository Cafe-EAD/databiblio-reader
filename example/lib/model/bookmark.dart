// import '../utils/model_keys.dart';

class BookmarkModel {
  int? id;
  int? bookmarkedindex;
  List<NoteModel>? note;

  BookmarkModel({this.id, this.bookmarkedindex, this.note});

  BookmarkModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookmarkedindex = json['bookmarkedindex'];
    if (json['note'] != null) {
      note = <NoteModel>[];
      json['note'].forEach((v) {
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
    id = json['id'];
    notetext = json['notetext'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['notetext'] = notetext;
    return data;
  }
}
