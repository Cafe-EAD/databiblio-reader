part of 'ui/epub_view.dart';

const int charactersPerPage = 1024;
const int pageNumberVisibilityDuration = 2000; // in milliseconds

class EpubController {
  EpubController({
    required this.document,
    this.epubCfi,
  });

  Future<EpubBook> document;
  final String? epubCfi;

  _EpubViewState? _epubViewState;
  List<EpubViewChapter>? _cacheTableOfContents;
  EpubBook? _document;
  String? selectedText;

  final isPageNumberVisible = ValueNotifier<bool>(false);
  final currentPage = ValueNotifier<int>(1);

  EpubChapterViewValue? get currentValue => _epubViewState?._currentValue;

  final isBookLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<EpubViewLoadingState> loadingState =
      ValueNotifier(EpubViewLoadingState.loading);

  final currentValueListenable = ValueNotifier<EpubChapterViewValue?>(null);

  final tableOfContentsListenable = ValueNotifier<List<EpubViewChapter>>([]);

  List<Paragraph> getAllParagraphs() {
    return _epubViewState?._paragraphs ?? [];
  }

  void jumpTo({required int index, double alignment = 0}) async {
    int passCount = 0;

    while (passCount < 5) {
      if (_epubViewState?._itemScrollController?.isAttached ?? false) {
        _epubViewState?._itemScrollController?.jumpTo(
          index: index,
          alignment: alignment,
        );
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      passCount++;
    }
  }

  bool getIsItemScrollControllerAttached() {
    return _epubViewState?._itemScrollController?.isAttached ?? false;
  }

  Future<void>? scrollTo({
    required int index,
    Duration duration = const Duration(milliseconds: 250),
    double alignment = 0,
    Curve curve = Curves.linear,
  }) =>
      _epubViewState?._itemScrollController?.scrollTo(
        index: index,
        duration: duration,
        alignment: alignment,
        curve: curve,
      );

  void gotoEpubCfi(
    String epubCfi, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
  }) {
    _epubViewState?._gotoEpubCfi(
      epubCfi,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  int? getCurrentIndex() {
    return _epubViewState?._currentValue?.position.index;
  }

  String? generateEpubCfi() => _epubViewState?._epubCfiReader?.generateCfi(
        book: _document,
        chapter: _epubViewState?._currentValue?.chapter,
        paragraphIndex: _epubViewState?._getAbsParagraphIndexBy(
          positionIndex: _epubViewState?._currentValue?.position.index ?? 0,
          trailingEdge:
              _epubViewState?._currentValue?.position.itemTrailingEdge,
          leadingEdge: _epubViewState?._currentValue?.position.itemLeadingEdge,
        ),
      );

  List<EpubViewChapter> tableOfContents() {
    if (_cacheTableOfContents != null) {
      return _cacheTableOfContents ?? [];
    }

    if (_document == null) {
      return [];
    }

    int index = -1;

    return _cacheTableOfContents =
        _document!.Chapters!.fold<List<EpubViewChapter>>(
      [],
      (acc, next) {
        index += 1;
        acc.add(EpubViewChapter(next.Title, _getChapterStartIndex(index)));
        for (final subChapter in next.SubChapters!) {
          index += 1;
          acc.add(EpubViewSubChapter(
              subChapter.Title, _getChapterStartIndex(index)));
        }
        return acc;
      },
    );
  }

  Future<void> loadDocument(Future<EpubBook> document) {
    this.document = document;
    return _loadDocument(document);
  }

  void dispose() {
    _epubViewState = null;
    isBookLoaded.dispose();
    currentValueListenable.dispose();
    tableOfContentsListenable.dispose();
  }

  Future<void> _loadDocument(Future<EpubBook> document) async {
    isBookLoaded.value = false;
    try {
      loadingState.value = EpubViewLoadingState.loading;
      _document = await document;
      await _epubViewState!._init();
      tableOfContentsListenable.value = tableOfContents();
      loadingState.value = EpubViewLoadingState.success;
    } catch (error) {
      _epubViewState!._loadingError = error is Exception
          ? error
          : Exception('An unexpected error occurred');
      loadingState.value = EpubViewLoadingState.error;
    }
  }

  int _getChapterStartIndex(int index) =>
      index < _epubViewState!._chapterIndexes.length
          ? _epubViewState!._chapterIndexes[index]
          : 0;

  void _attach(_EpubViewState epubReaderViewState) {
    _epubViewState = epubReaderViewState;
    _loadDocument(document);
  }

  void _detach() {
    _epubViewState = null;
  }

  void updateCurrentPage() {
    final currentValue = this.currentValue;
    if (currentValue != null) {
      final positionIndex = currentValue.position.index;
      final paragraphIndex = _epubViewState?._getAbsParagraphIndexBy(
        positionIndex: positionIndex,
        trailingEdge: currentValue.position.itemTrailingEdge,
        leadingEdge: currentValue.position.itemLeadingEdge,
      );
      if (paragraphIndex != null) {
        final totalCharacters = paragraphIndex * charactersPerPage;
        final newPage = (totalCharacters / charactersPerPage).ceil();
        if (newPage != currentPage.value) {
          currentPage.value = newPage;
          debugPrint('>>> Current Page: ${currentPage.value}');
        }
      }
    }
  }
}
