import 'package:epub_view/src/data/models/chapter_view_value.dart';

class HighlightModel {
  EpubChapterViewValue? value;
  String? selectedText;
  String? cfi;
  int? highlightid;
  String? chapter;
  String? paragraph;
  String? startindex;
  String? selectionlength;

  HighlightModel({
    this.value,
    this.selectedText,
    this.cfi,
    this.highlightid,
    this.chapter,
    this.paragraph,
    this.startindex,
    this.selectionlength,
    highlighted_text,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      value: json[HighlightKeys.value],
      selectedText: json[HighlightKeys.selectedText],
      cfi: json[HighlightKeys.cfi],
      highlightid: json[HighlightKeys.highlightid],
      highlighted_text: json[HighlightKeys.highlighted_text],
      chapter: json[HighlightKeys.chapter],
      paragraph: json[HighlightKeys.paragraph],
      startindex: json[HighlightKeys.startindex],
      selectionlength: json[HighlightKeys.selectionlength],
    );
  }
  void printar() {
    print('========================================');
    print('selecionado');
    print('capitulo nome: ${value!.chapter!.Title}');
    print('capitulo: ${value!.chapterNumber}');
    print('paragrafo: ${value!.paragraphNumber}');
    print('index: ${value!.position.index}');
    print('texto: ${selectedText!}');
    print('quantidade caracter: ${selectedText!.length}');
    print('cfi: ${cfi!}');
    print('========================================');
  }
}

class HighlightKeys {
  static const String value = 'value';
  static const String selectedText = 'selectedText';
  static const String cfi = 'cfi';
  static const String highlighted_text = 'highlighted_text';
  static const String highlightid = 'highlightid';
  static const String chapter = 'chapter';
  static const String paragraph = 'paragraph';
  static const String startindex = 'startindex';
  static const String selectionlength = 'selectionlength';
}
