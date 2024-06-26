// ignore_for_file: avoid_print


import 'package:epub_view/epub_view.dart';
import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/utils/model_keys.dart';
import 'package:epub_view_example/widget/bookmark_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:anim_search_bar/anim_search_bar.dart';

//import 'package:epub_view_example/utils/tts_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_tts/flutter_tts.dart';

import 'model/highlight_model.dart';
import 'model/locator.dart';
import 'network/rest.dart';
import 'widget/bottom_Sheet.dart';
import 'widget/search_match.dart';


void main() => runApp(const MyApp());

enum TtsState { playing, stopped, paused, continued }

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _setSystemUIOverlayStyle();
  }

  Brightness get platformBrightness =>
      MediaQueryData.fromView(WidgetsBinding.instance.window)
          .platformBrightness;


  void _setSystemUIOverlayStyle() {
    if (platformBrightness == Brightness.light) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.grey[50],
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.grey[850],
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Epub demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
        ),
        themeMode: _themeMode,
        debugShowCheckedModeBanner: false,
        home: MyHomePage(onToggleTheme: _toggleTheme),
      );
}

class MyHomePage extends StatefulWidget {
  final Function(bool) onToggleTheme;
  MyHomePage({super.key, required this.onToggleTheme});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
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

  bool _showSearchField = false;
  final TextEditingController _searchController = TextEditingController();
  int _bottomSheetState = 0; // 0: nenhum, 1: bookmarks/highlights
  bool _isBookmarkMarked = false;

  late bool hasEditButton;
  late bool hasDeleteButton;
  //dados ficticios para bookmark
  final List<Map<String, dynamic>> bookmarkFake = [
    {
      "local": "Chapter I. - Parágrafo 1",
      "conteudo":
          "BILLY BYRNE was a product of the streets and alleys of Chicago's great West Side. From Halsted to Robey, and from Grand Avenue to Lake Street there was scarce a bartender whom Billy knew not by his first name. And, in proportion to their number which was considerably less, he knew the patrolmen and plain clothes men equally as well, but not so pleasantly.",
    },
    {
      "local": "Chapter II. - Parágrafo 1",
      "conteudo":
          "WHEN Billy opened his eyes again he could not recall, for the instant, very much of his recent past. At last he remembered with painful regret the drunken sailor it had been his intention to roll. He felt deeply chagrined that his rightful prey should have escaped him. He couldn't understand how it had happened.",
    },
    {
      "local": "Chapter II. - Parágrafo 3",
      "conteudo":
          "His head ached frightfully and he was very sick. So sick that the room in which he lay seemed to be rising and falling in a horribly realistic manner. Every time it dropped it brought Billy's stomach nearly to his mouth.",
    },
    {
      "local": "Chapter IV. - Parágrafo 4",
      "conteudo":
          "Ward was pleased that he had not been forced to prolong the galling masquerade of valet to his inferior officer. He was hopeful, too,",
    },
    {
      "local": "Chapter V. - Parágrafo 14",
      "conteudo":
          "The girl made no comment, but Divine saw the contempt in her face.",
    },
  ];

  @override
  void initState() {

    if (kIsWeb) preventContextMenu();
    _tabController = TabController(length: 2, vsync: this);
    var bookName = Uri.base.queryParameters['bookname'] ?? "";
    var contextId = Uri.base.queryParameters['contextid'] ?? "";
    var revision = Uri.base.queryParameters['revision'] ?? "";
    userId = int.parse(Uri.base.queryParameters['userid'] ?? "0");
    bookId = int.parse(Uri.base.queryParameters['bookid'] ?? "0");

    _epubReaderController = EpubController(

      document: EpubDocument.openAsset(
        kDebugMode ? 'assets/burroughs-mucker.epub' : '$contextId/$revision/$bookName',
      ),
    );
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
            builder: (chapterValue) => Text(
              chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? '',
              textAlign: TextAlign.start,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
                _showSearchDialog(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark),
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
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
                  _changeFontFamily),
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
                if (_epubReaderController.selectedText != null &&
                    _epubReaderController.generateEpubCfi() != null &&
                    _epubReaderController.currentValueListenable.value !=
                        null) {
                  HighlightModel(
                      value: _epubReaderController.currentValueListenable.value,
                      selectedText: _epubReaderController.selectedText,
                      cfi: _epubReaderController.generateEpubCfi()).printar();
                }
              },

            ),
          ],
        ),
        drawer: Drawer(
          child: EpubViewTableOfContents(controller: _epubReaderController),
        ),
        body: EpubView(
          onChapterChanged: (value) {
            postLocationData(value?.position.index);

          },
          /*
          onTextToSpeech: (value) {
            _speak(value);
          },

           */
          builders: EpubViewBuilders(
            options: _builderOptions,
            chapterDividerBuilder: (_) => const Divider(),
          ),
          controller: _epubReaderController,
        ),

        bottomSheet: _showSearchField ? _getShowContainer() : const SizedBox.shrink(),
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
          bookmarkFake: bookmarkFake,
        );
      default:
        return Container();
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Pesquisar',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar',
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.1),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            onEditingComplete: () {
              Navigator.of(context).pop();
              setState(() {
                _showSearchField = false;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showSearchField = false;
                });
              },
              child: Text(
                'Pesquisar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  void _showCurrentEpubCfi(context) {
    final cfi = _epubReaderController.generateEpubCfi();
    print(cfi);
    if (cfi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cfi),
          action: SnackBarAction(
            label: 'GO',
            onPressed: () {
              _epubReaderController.gotoEpubCfi(cfi);
            },
          ),
        ),
      );
    }
  }
}
