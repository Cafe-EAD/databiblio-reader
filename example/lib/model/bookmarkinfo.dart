class Bookmarkedinfo {
  int? id;
  int? bookmarkedindex;
  List<Note>? note;

  Bookmarkedinfo({this.id, this.bookmarkedindex, this.note});

  Bookmarkedinfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookmarkedindex = json['bookmarkedindex'];
    if (json['note'] != null) {
      note = <Note>[];
      json['note'].forEach((v) {
        note!.add(new Note.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['bookmarkedindex'] = bookmarkedindex;
    if (note != null) {
      data['note'] = note!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Note {
  String? notetext;

  Note({this.notetext});

  Note.fromJson(Map<String, dynamic> json) {
    notetext = json['notetext'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['notetext'] = notetext;
    return data;
  }
}
