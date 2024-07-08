// ignore_for_file: avoid_print
import 'package:collection/collection.dart';
import 'package:epub_view/epub_view.dart';
import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/question.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epub_view_example/widget/quiz_modal.dart';
import 'package:epub_view_example/utils/model_keys.dart';
import 'package:epub_view_example/widget/bookmark_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:anim_search_bar/anim_search_bar.dart';

//import 'package:epub_view_example/utils/tts_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:epub_view/src/data/models/paragraph.dart' as epub_paragraph;
import 'model/highlight_model.dart';
import 'model/locator.dart';
import 'network/rest.dart';
import 'widget/bottom_Sheet.dart';
import 'widget/search_match.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';

class ReaderScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;

  final Future<EpubBook> book;

  const ReaderScreen({
    Key? key,
    required this.onToggleTheme,
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

  late FlutterTts _flutterTts;
  late CustomBuilderOptions _builderOptions;
  late int userId;
  late int bookId;
  TtsState ttsState = TtsState.stopped;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isDefaultFont = true;
  String defaultFont = "";
  String otherFont = "OpenDyslexic";
  late TabController _tabController;
  List<BookmarkModel> bookmarks = [];
  List<BookmarkModel> bookmarksinfo = [];
  List<HighlightModel> highlightsinfo = [];
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

  final Map<String, int> _chapterStartIndices = {};
  late SharedPreferences _prefs;
  int _currentQuestionIndex = 0;
  int _currentChapter = 0;
  bool _showQuiz = false;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  late List<epub_paragraph.Paragraph> allParagraphs;

  @override
  void initState() {
    _initPrefs();
    if (kIsWeb) preventContextMenu();
    _tabController = TabController(length: 2, vsync: this);

    userId = int.parse(Uri.base.queryParameters['userid'] ?? "0");
    bookId = int.parse(Uri.base.queryParameters['bookid'] ?? "0");

    // _epubReaderController = EpubController(
    //   document: EpubDocument.openAsset(
    //     kDebugMode
    //         ? 'assets/burroughs-mucker.epub'
    //         : '$contextId/$revision/$bookName',
    //   ),
    // );

    _epubReaderController = EpubController(
      document: widget.book,
    );

    _epubReaderController.tableOfContentsListenable.addListener(() {
      final chapters = _epubReaderController.tableOfContentsListenable.value;
      _chapterStartIndices.clear();
      for (int i = 0; i < chapters.length; i++) {
        if (chapters[i].title != null) {
          _chapterStartIndices[chapters[i].title!] = chapters[i].startIndex;
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

    getBookmarks(userId, bookId).then((value) => bookmarks = value);

    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    _flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setVolume(volume);
    _flutterTts.setSpeechRate(rate);
    _flutterTts.setPitch(pitch);
  }

  @override
  void dispose() {
    _epubReaderController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: EpubViewActualChapter(
            controller: _epubReaderController,
            builder: (chapterValue) {
              return Text(
                chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? '',
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
              icon: const Icon(Icons.save_alt),
              onPressed: () => _speak(_epubReaderController.selectedText ?? ""),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => _changeFontSize(20),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _changeFontFamily(),
            ),
            IconButton(
              icon: const Icon(Icons.format_size),
              onPressed: () => showCustomModalBottomSheet(
                  context,
                  widget.onToggleTheme,
                  _changeFontSize,
                  _builderOptions,
                  _changeFontFamily,
                  ThemeMode.system == ThemeMode.dark),
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
                allParagraphs = _epubReaderController.getAllParagraphs();

                if (_epubReaderController.selectedText != null) {
                  print(_epubReaderController.selectedText);
                  // Encontre o parágrafo correspondente ao texto selecionado
                  final selectedParagraph = allParagraphs.firstWhereOrNull(
                    (paragraph) {
                      String paragraphText =
                          paragraph.element.text.replaceAll('\n', ' ');
                      if (paragraphText
                          .contains(_epubReaderController.selectedText!)) {
                        return true;
                      } else {
                        return false;
                      }
                    },
                  );

                  if (selectedParagraph != null) {
                    // Obter o número do capítulo
                    int chapterIndex = _epubReaderController
                        .currentValueListenable.value!.chapterNumber;
                    print('chapter: $chapterIndex');
                    // Obter o nó do parágrafo
                    final paragraphNode = selectedParagraph.element;
                    // print('paragraph: ${paragraphNode.outerHtml}');
                    final nodeIndex = paragraphNode.nodes.indexWhere(
                      (node) => node.text!
                          .contains(_epubReaderController.selectedText!),
                    );
                    print('nodeIndex: $nodeIndex');
                    // Obter o startIndex
                    final startIndex = _chapterStartIndices[
                        _epubReaderController
                                .currentValueListenable.value?.chapter?.Title ??
                            ''];
                    print('startIndex: $startIndex');
                    // Obter o comprimento do texto selecionado
                    final selectionLength =
                        _epubReaderController.selectedText!.length;
                    print('selectionLength: $selectionLength');

                    // Declarar as variáveis antes de usá-las
                    final chapter = chapterIndex.toString();
                    final paragraph = nodeIndex.toString();
                    final startindex = startIndex.toString();
                    final selectionlength = selectionLength.toString();
                    final highlightedText =
                        _epubReaderController.selectedText.toString();

                    postHighlight(
                      userId == 0 ? 1 : userId,
                      bookId == 0 ? 1 : bookId,
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
                    print('Parágrafo selecionado não encontrado.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Highligth não foi salvo')),
                    );
                  }
                }
                // print(allParagraphs);
                //   if (_epubReaderController.selectedText != null &&
                //       _epubReaderController.generateEpubCfi() != null &&
                //       _epubReaderController.currentValueListenable.value !=
                //           null) {
                //     HighlightModel(
                //             value: _epubReaderController
                //                 .currentValueListenable.value,
                //             selectedText: _epubReaderController.selectedText,
                //             cfi: _epubReaderController.generateEpubCfi())
                //         .printar();
                //   }
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: EpubViewTableOfContents(controller: _epubReaderController),
        ),
        body: _showQuiz
            ? QuizModal(
                question: _questionsByChapter[_currentChapter]![
                    _currentQuestionIndex],
                onCorrectAnswer: () {
                  _onCorrectAnswer(_questionsByChapter[_currentChapter]![
                      _currentQuestionIndex]);
                },
              )
            : EpubView(
                onChapterChanged: (value) {
                  postLocationData(value?.position.index);
                  _currentChapter = value?.chapterNumber ?? 0;
                  // Verifica se o capítulo mudou e se há perguntas não respondidas no novo capítulo
                  if (_currentChapter != 0 &&
                      !_hasAnsweredQuestion(
                          _questionsByChapter[_currentChapter]!.first.id)) {
                    setState(() {
                      _currentChapterValue = value;
                      _showQuiz = true;
                      _currentQuestionIndex = 0;
                    });
                  }
                },
                builders: EpubViewBuilders(
                  options: _builderOptions,
                  chapterDividerBuilder: (_) => const Divider(),
                ),
                controller: _epubReaderController,
              ),
        bottomSheet:
            _showSearchField ? _getShowContainer() : const SizedBox.shrink(),
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
          bookId: bookId,
          userId: userId,
          chapterStartIndices: _chapterStartIndices,
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
        // Obter startIndex usando o nome do capítulo
        final startIndex =
            _chapterStartIndices[_currentChapterValue?.chapter?.Title];
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
    final bookmarks =
        await getBookmarks(userId == 0 ? 1 : userId, bookId == 0 ? 1 : bookId);
    final highlights =
        await getHighlights(userId == 0 ? 1 : userId, bookId == 0 ? 1 : bookId);
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

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<int?> getLocationData() async {
    try {
      List<LocatorModel> locatorList = await getLocatorData(userId, bookId);
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
      locatorMap[CommonModelKeys.bookId] = bookId;
      locatorMap[CommonModelKeys.userId] = userId;
      locatorMap[LocatorModelKeys.lastIndex] = index;
      var result = await postLocatorData(locatorMap);
      print('POST Locator return ==== $result');
    } catch (e, t) {
      print('POST Locator Error ==== $e  $t');
    }
  }
}
