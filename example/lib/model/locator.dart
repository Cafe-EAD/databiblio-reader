import '../utils/model_keys.dart';

class LocatorModel {
  int? bookId;
  int? lastIndex;

  LocatorModel({ this.bookId, this.lastIndex });

  factory LocatorModel.fromJson(Map<String, dynamic> json) {
    return LocatorModel(
      bookId: json[CommonModelKeys.bookId],
      lastIndex: json[LocatorModelKeys.lastIndex],
    );
  }
}
