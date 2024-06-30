import '../utils/model_keys.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';

class HighlightModel {
   EpubChapterViewValue? value;
   String? selectedText;
   String? cfi;

  HighlightModel({required this.value, required this.selectedText, required this.cfi});

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      value: json[HighlightKeys.value],
      selectedText: json[HighlightKeys.selectedText],
      cfi: json[HighlightKeys.cfi],
    );
  }
void printar(){
print('========================================');
print('selecionado');
print('capitulo nome: ${value!.chapter!.Title}');
print('capitulo: ${value!.chapterNumber}');
print('paragrafo: ${value!.paragraphNumber}');
print('index: ${value!.position.index}');
print('texto: ${selectedText!}');
print('cfi: ${cfi!}');
print('========================================');
}

}

