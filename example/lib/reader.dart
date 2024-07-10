// ignore_for_file: avoid_print
import 'dart:async';

import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:collection/collection.dart';
import 'package:epub_view/epub_view.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/question.dart';
import 'package:epub_view_example/utils/model_keys.dart';
import 'package:epub_view_example/widget/bookmark_bottom_sheet.dart';
import 'package:epub_view_example/widget/quiz_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/highlight_model.dart';
import 'model/locator.dart';
import 'network/rest.dart';
import 'widget/bottom_Sheet.dart';
import 'widget/search_match.dart';

class ReaderScreen extends StatefulWidget {
  final Future<EpubBook> book;

  const ReaderScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

enum TtsState { playing, stopped, paused, continued }

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {

  late EpubController _epubReaderController;
  late SearchMatch searchMatch;
  TextEditingController textController = TextEditingController();

  late CustomBuilderOptions _builderOptions;
  late int userId;
  late int bookId;

  bool isDefaultFont = true;
  String defaultFont = "";
  String otherFont = "OpenDyslexic";
  late TabController _tabController;
  List<BookmarkModel> bookmarks = [];
  List<BookmarkModel> bookmarksinfo = [];
  List<HighlightModel> highlightsinfo = [];
  final TextEditingController _searchController = TextEditingController();
  int _bottomSheetState = 0; // 0: nenhum, 1: bookmarks/highlights
  bool _isBookmarkMarked = false;
  bool _showSearchField = false;

  EpubChapterViewValue? _currentChapterValue;

  // Mocado question
  final Map<int, List<Question>> _questionsByChapter = {
    2: [
      Question(
        id: 1,
        chapterNumber: 2,
        text: 'Pergunta número 01?',
        options: [
          'Resposta letra A',
          'Resposta letra B',
          'Resposta letra C',
          'Resposta letra D'
        ],
        correctAnswerIndex: 2,
        questionType: 'Múltipla Escolha',
      ),
      Question(
        id: 2,
        chapterNumber: 2,
        text: 'Pergunta número 02?',
        options: ['Verdadeiro', 'Falso'],
        correctAnswerIndex: 0,
        questionType: 'Verdadeiro ou Falso',
      ),
    ],
    3: [
      Question(
        id: 3,
        chapterNumber: 3,
        text: 'Pergunta número 03?',
        options: [],
        correctAnswerIndex: null,
        questionType: 'Resposta Aberta',
      ),
    ],
  };

  late SharedPreferences _prefs;
  int _currentQuestionIndex = 0;
  int _currentChapter = 0;
  bool _showQuiz = false;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    _initPrefs();
    if (kIsWeb) preventContextMenu();

    _tabController = TabController(length: 2, vsync: this);

    _epubReaderController = EpubController(
      document: widget.book,
    );

    _epubReaderController.userId =
        int.parse(Uri.base.queryParameters['userid'] ?? "0");
    _epubReaderController.bookId =
        int.parse(Uri.base.queryParameters['bookid'] ?? "0");

    _epubReaderController.tableOfContentsListenable.addListener(() {
      //  _epubReaderController._epubViewState._paragraphs;
      final chapters = _epubReaderController.tableOfContentsListenable.value;
      _epubReaderController.chapterStartIndices.clear();
      for (int i = 0; i < chapters.length; i++) {
        if (chapters[i].title != null) {
          _epubReaderController.chapterStartIndices[chapters[i].title!] =
              chapters[i].startIndex;
        }
      }
    });

    searchMatch = SearchMatch(_epubReaderController);

    _builderOptions = CustomBuilderOptions();

    getLocationData().then((value) => {
          setState(() {
            _epubReaderController.getIsItemScrollControllerAttached();
            _epubReaderController.jumpTo(index: value ?? 0);
          })
        });

    getBookmarks(_epubReaderController.userId, _epubReaderController.bookId)
        .then((value) => bookmarks = value);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bookmarks = await getBookmarks(
          _epubReaderController.userId, _epubReaderController.bookId);
      debugPrint('>>> bookmarks $bookmarks');
    });

    super.initState();
  }

  @override
  void dispose() {
    _epubReaderController.dispose();
    super.dispose();
  }

  void _showPageNumber() {
    setState(() {
      _epubReaderController.isPageNumberVisible.value = true;
    });

    Timer(const Duration(milliseconds: pageNumberVisibilityDuration), () {
      setState(() {
        _epubReaderController.isPageNumberVisible.value = false;
      });
    });
  }

  ThemeMode _themeMode = ThemeMode.system;
  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
        data:
            _themeMode == ThemeMode.dark ? ThemeData.dark() : ThemeData.light(),

        child: Scaffold(
          floatingActionButton: AnimatedBuilder(
            animation: Listenable.merge([
              _epubReaderController.currentPage,
              _epubReaderController.isPageNumberVisible,
            ]),
            builder: (_, __) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity:
                    _epubReaderController.isPageNumberVisible.value ? 1 : 0,

                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Página ${_epubReaderController.currentPage.value}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          appBar: AppBar(
            title: EpubViewActualChapter(
              controller: _epubReaderController,
              builder: (chapterValue) {
                return Text(
                  chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ??
                      '',
                  textAlign: TextAlign.start,
                );
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.bookmark),
                color: Theme.of(context).colorScheme.onBackground,
                onPressed: () async {
                  await _getInfoPopular();
                  setState(() {
                    _showSearchField = !_showSearchField;
                    _bottomSheetState = 1;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.format_size),
                onPressed: () => showCustomModalBottomSheet(context, toggleTheme, _changeFontSize,
                    _builderOptions, _changeFontFamily, ThemeMode.system == ThemeMode.dark),
              ),
              AnimSearchBar(
                width: 300,
                textController: textController,
                onSuffixTap: () {
                  setState(() {
                    textController.clear();
                  });
                },
                onSubmitted: (busca) async {
                  await searchMatch.busca(busca, context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.assistant_rounded),
                onPressed: () {
                  _epubReaderController.allParagraphs =
                      _epubReaderController.getAllParagraphs();


                  if (_epubReaderController.selectedText != null) {
                    print(_epubReaderController.selectedText);
                    // Encontre o parágrafo correspondente ao texto selecionado
                    final selectedParagraph =
                        _epubReaderController.allParagraphs.firstWhereOrNull(
                      (paragraph) {
                        String paragraphText =
                            paragraph.element.text.replaceAll('\n', ' ');
                        // print(_epubReaderController.selectedText);
                        // print(paragraphText);
                        // print('>>>>>>>>>>>>>>>>');

                        if (paragraphText
                            .contains(_epubReaderController.selectedText!)) {

                          return true;
                        } else {
                          return false;
                        }
                      },
                    );

                    if (selectedParagraph != null) {

                      int chapterIndex =
                          _epubReaderController.currentValueListenable.value!.chapterNumber;
                      final paragraphNode = selectedParagraph.element;
                      final nodeIndex = paragraphNode.nodes.indexWhere((node) =>
                          node.text!.trim().contains(_epubReaderController.selectedText!.trim()));
                      final startIndex = _epubReaderController.chapterStartIndices[
                          _epubReaderController.currentValueListenable.value?.chapter?.Title ?? ''];
                      final selectionLength = _epubReaderController.selectedText!.length;
                      final chapter = chapterIndex.toString();
                      final paragraph = nodeIndex.toString();
                      final startindex = startIndex.toString();
                      final selectionlength = selectionLength.toString();
                      final highlightedText =
                          _epubReaderController.selectedText.toString();


                      postHighlight(
                        _epubReaderController.userId == 0
                            ? 1
                            : _epubReaderController.userId,
                        _epubReaderController.bookId == 0
                            ? 1
                            : _epubReaderController.bookId,
                        chapter,
                        paragraph,
                        startindex,
                        selectionlength,
                        highlightedText,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Highligth salvo com sucesso!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Highligth não foi salvo')),
                      );
                    }

                  }
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: EpubViewTableOfContents(
              controller: _epubReaderController,
              itemBuilder: (context, index, chapter, itemCount) {
                return EpubViewActualChapter(
                  controller: _epubReaderController,
                  builder: (chapterAtual) {
                    return Container(
                      color: chapterAtual!.chapterNumber == (index + 1)
                          ? Theme.of(context).primaryColor
                          : null,
                      child: ListTile(
                          title: Text(chapter.title!.trim()),
                          onTap: () => {
                                setState(() {
                                  _epubReaderController.scrollTo(
                                      index: chapter.startIndex);
                                })
                              }),
                    );
                  },
                );
              },
            ),
          ),
          body: _showQuiz
              ? QuizModal(
                  question: _questionsByChapter[_currentChapter]![_currentQuestionIndex],
                  onCorrectAnswer: () {
                    _onCorrectAnswer(_questionsByChapter[_currentChapter]![_currentQuestionIndex]);
                  },
                )
              : EpubView(
                  builders: EpubViewBuilders(
                    options: _builderOptions,
                    chapterDividerBuilder: (_) => const Divider(),
                  ),
                  controller: _epubReaderController,
                  onChapterChanged: (value) {
                    postLocationData(value?.position.index);
                    _currentChapter = value?.chapterNumber ?? 0;

                    _epubReaderController.updateCurrentPage();
                    // if (!kIsWeb) _showPageNumber();

                    if (_epubReaderController.bookId == 4 &&
                        _currentChapter != 0 &&
                        !_hasAnsweredQuestion(
                            _questionsByChapter[_currentChapter]!.first.id)) {
                      setState(() {
                        _currentChapterValue = value;
                        _showQuiz = true;
                        _currentQuestionIndex = 0;
                      });
                    }
                  },
                ),
          bottomSheet:
              _showSearchField ? _getShowContainer() : const SizedBox.shrink(),
        ),
      );

  Widget _getShowContainer() {
    switch (_bottomSheetState) {
      case 1:
        return BookmarkBottomSheet(
          isBookmarkMarked: _isBookmarkMarked,
          onBookmarkToggle: () {
            setState(() {
              _isBookmarkMarked = !_isBookmarkMarked;
            });
          },
          onClose: () {
            setState(() {
              _showSearchField = !_showSearchField;
              _bottomSheetState = 0;
            });
          },
          tabController: _tabController,
          bookmarksinfo: bookmarksinfo,
          highlightsinfo: highlightsinfo,
          chapterValue: _currentChapterValue,
          epubReaderController: _epubReaderController,
          onBookmarkAdded: _updateBookmarks,
          bookId: _epubReaderController.bookId,
          userId: _epubReaderController.userId,
          chapterStartIndices: _epubReaderController.chapterStartIndices,
        );
      default:
        return Container();
    }
  }

  void _onCorrectAnswer(Question question) {
    _saveAnswer(question.id);
    setState(() {
      if (_currentQuestionIndex <
          _questionsByChapter[_currentChapter]!.length - 1) {
        _currentQuestionIndex++;
      } else {
        _showQuiz = false;
        _currentQuestionIndex = 0;
        final startIndex = _epubReaderController
            .chapterStartIndices[_currentChapterValue?.chapter?.Title];
        if (startIndex != null) {
          _epubReaderController.jumpTo(index: startIndex, alignment: 0);
        }
      }
    });
  }

  // Future<void> _clearAnsweredQuestions() async {
  //   _prefs = await SharedPreferences.getInstance();
  //   await _prefs.clear();
  // }

  Future<void> _saveAnswer(int questionId) async {
    final answeredQuestions = _prefs.getStringList('answeredQuestions') ?? [];
    answeredQuestions.add(questionId.toString());
    await _prefs.setStringList('answeredQuestions', answeredQuestions);
  }

  bool _hasAnsweredQuestion(int questionId) {
    final answeredQuestions = _prefs.getStringList('answeredQuestions') ?? [];
    return answeredQuestions.contains(questionId.toString());
  }

  _getInfoPopular() async {
    final bookmarks = await getBookmarks(
        _epubReaderController.userId == 0 ? 1 : _epubReaderController.userId,
        _epubReaderController.bookId == 0 ? 1 : _epubReaderController.bookId);
    final highlights = await getHighlights(
        _epubReaderController.userId == 0 ? 1 : _epubReaderController.userId,
        _epubReaderController.bookId == 0 ? 1 : _epubReaderController.bookId);
    setState(() {
      bookmarksinfo = bookmarks;
      highlightsinfo = highlights;
    });
  }

  void _updateBookmarks() {
    _getInfoPopular();
  }

  /*
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  */

  void _changeFontSize(double newFontSize) {
    print("FONTSIZE=$newFontSize");
    setState(() {
      _builderOptions.textStyle = TextStyle(
          height: _builderOptions.textStyle.height,
          fontSize: newFontSize,
          fontFamily: _builderOptions.textStyle.fontFamily);
    });
  }

  void _changeFontFamily() {
    var currFont = _builderOptions.textStyle.fontFamily;
    var newFontFamily = isDefaultFont ? otherFont : defaultFont;
    isDefaultFont = !isDefaultFont;
    setState(() {
      _builderOptions.textStyle = TextStyle(
          height: _builderOptions.textStyle.height,
          fontSize: _builderOptions.textStyle.fontSize,
          fontFamily: newFontFamily,
          package: "epub_view");
    });
  }

  Future<int?> getLocationData() async {
    try {
      List<LocatorModel> locatorList = await getLocatorData(
          _epubReaderController.userId, _epubReaderController.bookId);
      LocatorModel? locator = locatorList.firstOrNull;
      var index = locator?.lastIndex;
      print('GET Locator Index ==== $index');
      return index;
    } catch (e, t) {
      print('GET Locator Error ==== $e  $t');
    }
    return null;
  }

  void postLocationData(int? index) async {
    try {
      Map<String, dynamic> locatorMap = {};
      locatorMap[CommonModelKeys.bookId] = _epubReaderController.bookId;
      locatorMap[CommonModelKeys.userId] = _epubReaderController.userId;
      locatorMap[LocatorModelKeys.lastIndex] = index;
      var result = await postLocatorData(locatorMap);
      print('POST Locator return ==== $result');
    } catch (e, t) {
      print('POST Locator Error ==== $e  $t');
    }
  }
}
