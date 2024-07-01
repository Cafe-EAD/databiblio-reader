import '../utils/model_keys.dart';

class BookmarkModel {
  int id;
  int index;
  NoteModel? note;

  BookmarkModel({required this.id, required this.index, this.note});

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
        id: json[CommonModelKeys.id],
        index: json[BookmarkKeys.index],
        note: json[BookmarkKeys.note]);
  }
}

class NoteModel {
  String noteText;
  int id;

  NoteModel({required this.noteText, required this.id});
}
