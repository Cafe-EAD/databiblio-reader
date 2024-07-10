// ignore_for_file: non_constant_identifier_names

import '../utils/model_keys.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';

class HighlightModel {
  EpubChapterViewValue? value;
  String? selectedText;
  String? cfi;
  String? highlighted_text;
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
    this.highlighted_text,
    this.chapter,
    this.paragraph,
    this.startindex,
    this.selectionlength,
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
