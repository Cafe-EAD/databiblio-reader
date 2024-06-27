import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:epub_view/src/data/epub_cfi_reader.dart';
import 'package:epub_view/src/data/epub_parser.dart';

class SearchMatch {
  final EpubController _epubReaderController;
  EpubCfiReader? _epubCfiReader;

  SearchMatch(this._epubReaderController);

  Future<void> busca(String item, BuildContext context) async {
    // Obtém o EpubBook resolvendo o Future
    EpubBook document = await _epubReaderController.document;
    int paragraf = 0;

    // Verifica se o documento e capítulos não são nulos
    if (document.Chapters != null) {
      List<Item> results = [];

      for (int i = 0; i < document.Chapters!.length; i++) {
        EpubChapter chapter = document.Chapters![i];
        if (chapter.HtmlContent != null) {
          String htmlContent = chapter.HtmlContent!;
          final parsedHtml = html_parser.parse(htmlContent);

          // Extrai os parágrafos do conteúdo HTML
          final paragraphs = parsedHtml.querySelectorAll('p');

          // Itera pelos parágrafos para verificar se contêm o item
          for (int j = 0; j < paragraphs.length; j++) {
            String paragraphText = paragraphs[j].text.toLowerCase();
            paragraf++;

            if (paragraphText.contains(item.toLowerCase())) {
              results.add(Item(
                chapter: chapter,
                paragraphIndex: j,
                paragraphText: paragraphs[j].text,
              ));
            }
          }
        }
      }

      if (results.isNotEmpty) {
        showBottomSheet(context, results);
      } else {
        showNoResultsDialog(context, item);
      }
    } else {
      showNoResultsDialog(context, item);
    }
  }

  Future<void> showBottomSheet(BuildContext context, List<Item> results) async {
    EpubBook document = await _epubReaderController.document;

    final _chapters = parseChapters(document!);
    final parseParagraphsResult = parseParagraphs(_chapters, document!.Content);
    final _paragraphs = parseParagraphsResult.flatParagraphs;

    _epubCfiReader = EpubCfiReader.parser(
      cfiInput: _epubReaderController.epubCfi,
      chapters: _chapters,
      paragraphs: _paragraphs,
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (BuildContext context, int index) {
            final result = results[index];
            return ListTile(
              title: Text("Capítulo: ${result.chapter?.Title}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Parágrafo: ${result.paragraphIndex}"),
                  SizedBox(height: 4),
                  Text(result.paragraphText,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                // final cfi = _epubCfiReader!.generateCfi(
                //     book: document,
                //     chapter: result.chapter,
                //     paragraphIndex: result.paragraphIndex);
                //     print(cfi);
                // if (cfi != null) {
                //   _epubReaderController.gotoEpubCfi(cfi);
                // }
                _epubReaderController.scrollTo(index: result.paragraphIndex!);
              },
            );
          },
        );
      },
    );
  }

  void showNoResultsDialog(BuildContext context, String item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Item não encontrado'),
          content:
              Text('O item "$item" não foi encontrado em nenhum capítulo.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class Item {
  final EpubChapter? chapter;
  final int? paragraphIndex;
  final String paragraphText;

  Item(
      {required this.chapter,
      required this.paragraphIndex,
      required this.paragraphText});
}