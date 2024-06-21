import 'dart:developer';
import 'dart:typed_data';

import 'package:epub_view/epub_view.dart';
import 'package:epub_view_example/utils/model_keys.dart';
//import 'package:epub_view_example/utils/tts_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_tts/flutter_tts.dart';
//import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import 'model/locator.dart';
import 'network/rest.dart';
import 'widget/bottom_Sheet.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  late EpubController _epubReaderController;
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

  @override
  void initState() {
    var bookName = Uri.base.queryParameters['bookname'] ?? "";
    var contextId = Uri.base.queryParameters['contextid'] ?? "";
    var revision = Uri.base.queryParameters['revision'] ?? "";
    userId = int.parse(Uri.base.queryParameters['userid'] ?? "0");
    bookId = int.parse(Uri.base.queryParameters['bookid'] ?? "0");

    _epubReaderController = EpubController(
        // document: EpubDocument.openAsset('${contextId}/${revision}/${bookName}'),
        document: EpubDocument.openAsset('assets/burroughs-mucker.epub'),
    );

    _builderOptions = CustomBuilderOptions();

    getLocationData().then((value) => {
      setState(() {
        var controllerAttached = _epubReaderController.getIsItemScrollControllerAttached();
        _epubReaderController.jumpTo(index: value ?? 0);
      })
    });

    /*
    _epubReaderController = EpubController(
        document: EpubDocument.openAsset('${contextId}/${revision}/${bookName}'),
        epubCfi: cfi
        //EpubDocument.openData(await InternetFile.get('https://media.iqonic.design/apps-server/granth/53/GiveandTake.epub'))
    );

     */

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
    if (text != null) {
      if (text!.isNotEmpty) {
        await _flutterTts.speak(text!);
      }
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
              onPressed: () => showCustomModalBottomSheet(context, widget.onToggleTheme, _changeFontSize, _builderOptions, _changeFontFamily),
            ),
          ],
        ),
        drawer: Drawer(
          child: EpubViewTableOfContents(controller: _epubReaderController),
        ),
        body: EpubView(
          onChapterChanged: (value) {
            postLocationData(value?.position?.index);
          },
          builders: EpubViewBuilders(
            options: _builderOptions,
            chapterDividerBuilder: (_) => const Divider(),
          ),
          controller: _epubReaderController,
        ),
      );

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
          fontFamily: _builderOptions.textStyle.fontFamily
      );
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
          package: "epub_view"
      );
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
