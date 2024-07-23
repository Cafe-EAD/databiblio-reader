// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:collection/collection.dart';
import 'package:epub_view/epub_view.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/quiz_attempt_data.dart';
import 'package:epub_view_example/model/quiz_data.dart';
import 'package:epub_view_example/model/common.dart';
import 'package:epub_view_example/utils/model_keys.dart';
import 'package:epub_view_example/widget/bookmark_bottom_sheet.dart';
import 'package:epub_view_example/widget/quiz_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';

import 'model/highlight_model.dart';
import 'model/locator.dart';
import 'network/rest.dart';
import 'widget/bottom_Sheet.dart';
import 'widget/search_match.dart';
import 'widget/text-to-speech_button.dart';

bool disl = false;
bool? tema;

class ReaderScreen extends StatefulWidget {
  final Future<EpubBook> book;
  final int userId;
  final int bookId;

  const ReaderScreen({
    Key? key,
    required this.book,
    required this.bookId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late EpubController _epubReaderController;
  late SearchMatch searchMatch;
  TextEditingController textController = TextEditingController();

  late CustomBuilderOptions _builderOptions;

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
  QuizAttemptData? quizAttemptData;
  List<QuizData>? quizData;
  final Set<int> _paginasComQuizzes = {};
  int? idAttemptId;
  EpubChapterViewValue? _currentChapterValue;

  late SharedPreferences _prefs;
  int _currentChapter = 0;
  bool _showQuiz = false;
  EpubBook? _document;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadEpubDocument() async {
    EpubBook? document = await widget.book;
    if (document != null) {
      setState(() {
        _document = document;
      });
    }
  }

  @override
  void initState() {
    _initPrefs();

    _loadEpubDocument();

    if (kIsWeb) preventContextMenu();

    _tabController = TabController(length: 2, vsync: this);

    _epubReaderController = EpubController(
      document: widget.book,
    );

    _epubReaderController.userId = widget.userId;
    _epubReaderController.bookId = widget.bookId;

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
      // 1. Carregar bookmarks
      bookmarks = await getBookmarks(
          _epubReaderController.userId, _epubReaderController.bookId);

      // 2. Obter dados dos quizzes e iniciar attempts
      final resultQuizData =
          await getAllDesafio(_epubReaderController.bookId == 0
                            ? '224'
                            : _epubReaderController.bookId.toString() );
      if (resultQuizData != null) {
        for (var quiz in resultQuizData) {
          await _iniciarOuRecuperarAttempt(quiz.quizId.toString());
        }

        // 3. Popular _paginasComQuizzes
        setState(() {
          quizData = resultQuizData;
          for (var quiz in quizData!) {
            final pagina = int.tryParse(quiz.pagina);
            if (pagina != null) {
              _paginasComQuizzes.add(pagina);
            }
          }
        });
      }

      // 4. Carregar dados do quiz attempt (se necessário)
      final prefs = await SharedPreferences.getInstance();
      final attemptId = prefs.getInt('attemptId');
      if (attemptId != null) {
        final resultAttemptData = await getDesafio(attemptId.toString());
        setState(() {
          quizAttemptData = resultAttemptData;
          idAttemptId = attemptId;
        });
      } else {
        await prefs.setInt('attemptId', 9);
        final attemptId = prefs.getInt('attemptId');
        final resultAttemptData = await getDesafio(attemptId.toString());
        setState(() {
          quizAttemptData = resultAttemptData;
          idAttemptId = attemptId;
        });
      }

      debugPrint('>>> bookmarks $bookmarks');
      debugPrint('>>> _paginasComQuizzes: $_paginasComQuizzes');
    });

    super.initState();
  }

  Future<void> _iniciarOuRecuperarAttempt(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptIdSalvo = prefs.getInt('attemptId_$quizId');

    if (attemptIdSalvo != null) {
      print('ID do attempt recuperado: $attemptIdSalvo');
      return;
    }

    try {
      final attemptResponse = await getAttempt(quizId);
      if (attemptResponse != null && attemptResponse.attempt.id != null) {
        final attemptId = attemptResponse.attempt.id;
        print('Novo ID do attempt: $attemptId');

        await prefs.setInt('attemptId_$quizId', attemptId);
        await prefs.setInt('attemptId', attemptId);
      } else {
        _mostrarErro('Erro: Resposta da API inválida.');
      }
    } catch (e) {
      _mostrarErro('Erro ao iniciar attempt: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    print(mensagem);
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

  int? _pagAtual;
  DateTime? _horaAtual;
  ThemeMode? _themeMode = ThemeMode.system;
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
                // opacity: _epubReaderController.isPageNumberVisible.value ? 1 : 0,
                opacity: 1,
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
              _document != null
                  ? TextToSpeechButton(_extractTextFromEpubSync()
                      .replaceAll(RegExp(r'\s+'), ' ')
                      .trim())
                  : Container(),
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
                onPressed: () => showCustomModalBottomSheet(
                    context,
                    toggleTheme,
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
                  onQuizFinished: _finishQuiz,
                  questions: quizAttemptData,
                 )
              : EpubView(
                  builders: EpubViewBuilders(
                    options: _builderOptions,
                    chapterDividerBuilder: (_) => const Divider(),
                  ),
                  controller: _epubReaderController,
                  onChapterChanged: (value) async {
                    postLocationData(value?.position.index);
                    _currentChapter = value?.chapterNumber ?? 0;
                    _epubReaderController.updateCurrentPage();
                    // if (!kIsWeb) _showPageNumber();

                    if (
                        // _epubReaderController.bookId == 4 &&
                        _currentChapter != 0 &&
                            _paginasComQuizzes
                                .contains(value!.paragraphNumber.toInt()) &&
                            !_hasAnsweredQuestion(
                                quizAttemptData!.attempt.id)) {
                      setState(() {
                        _currentChapterValue = value;
                        _showQuiz = true;
                      });
                    }
                    if (_pagAtual == null ||
                        _pagAtual != _epubReaderController.currentPage.value) {
                      if (_horaAtual == null) {
                        _horaAtual = DateTime.now();
                      } else {
                        int tempoGasto =
                            DateTime.now().difference(_horaAtual!).inSeconds;
                        readingTime(tempoGasto);

                        _horaAtual = null;
                      }
                      _pagAtual = _epubReaderController.currentPage.value;
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
          onBookmarkTap: (index) {
            _handleBookmarkTap(index);
          },
        );
      default:
        return Container();
    }
  }

  void _finishQuiz(int attemptId) {
    setState(() {
      _showQuiz = false;
      final startIndex = _epubReaderController
          .chapterStartIndices[_currentChapterValue?.chapter?.Title];
      if (startIndex != null) {
        _epubReaderController.jumpTo(index: startIndex, alignment: 0);
      }
    });
    _saveAnswer(attemptId);
  }

  Future<void> _clearAnsweredQuestions() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.clear();
  }

  String _extractTextFromEpubSync() {
    if (_document == null) return '';

    return _document!.Chapters!.fold(StringBuffer(),
        (StringBuffer buffer, EpubChapter chapter) {
      _extractChapterText(chapter, buffer);
      return buffer;
    }).toString();
  }

  void _extractChapterText(EpubChapter chapter, StringBuffer buffer) {
    if (chapter.HtmlContent != null) {
      final textContent = _removeHtmlTags(chapter.HtmlContent!);
      buffer.writeln(textContent);
    }

    for (var subChapter in chapter.SubChapters!) {
      _extractChapterText(subChapter, buffer);
    }
  }

  String _removeHtmlTags(String html) {
    final document = parse(html);
    return document.body?.text ?? '';
  }

  Future<void> _saveAnswer(int attemptId) async {
    final answeredQuestions = _prefs.getStringList('answeredQuestions') ?? [];
    answeredQuestions.add(attemptId.toString());
    await _prefs.setStringList('answeredQuestions', answeredQuestions);
  }

  bool _hasAnsweredQuestion(int attemptId) {
    final answeredQuestions = _prefs.getStringList('answeredQuestions') ?? [];
    return answeredQuestions.contains(attemptId.toString());
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
      highlightsinfo.sort((a, b) {
        int chapterA = int.tryParse(a.chapter ?? '0') ?? 0;
        int chapterB = int.tryParse(b.chapter ?? '0') ?? 0;
        return chapterA.compareTo(chapterB);
      });
    });
  }

  void _updateBookmarks() {
    _getInfoPopular();
  }

  void _handleBookmarkTap(int index) {
    _epubReaderController.jumpTo(index: index, alignment: 0);
    setState(() {
      _showSearchField = false;
      _bottomSheetState = 0;
    });
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

  void readingTime(int tempoGasto) async {
    try {
      GenericPostResponse response = await postReadingTime(
        _epubReaderController.userId,
        _epubReaderController.bookId,
        _epubReaderController.currentPage.value,
        tempoGasto,
      );
      print('Success: ${response.success}, Message: ${response.message}');
    } catch (e) {
      print('Erro ao enviar o tempo de leitura: $e');
    }
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
