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

void main() => runApp(const MyApp());

enum TtsState { playing, stopped, paused, continued }

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ),
        debugShowCheckedModeBanner: false,
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late EpubController _epubReaderController;
  late FlutterTts _flutterTts;
  late int userId;
  late int bookId;
  TtsState ttsState = TtsState.stopped;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    var bookName = Uri.base.queryParameters['bookname'] ?? "";
    var contextId = Uri.base.queryParameters['contextid'] ?? "";
    var revision = Uri.base.queryParameters['revision'] ?? "";
    userId = int.parse(Uri.base.queryParameters['userid'] ?? "0");
    bookId = int.parse(Uri.base.queryParameters['bookid'] ?? "0");

    /*
    VocsyEpub.setConfig(
      themeColor: Theme.of(context).primaryColor,
      identifier: "iosBook",
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: true,
    );

    // get current locator
    VocsyEpub.locatorStream.listen((locator) {
      print('LOCATOR: $locator');
    });

    VocsyEpub.openAsset('${contextId}/${revision}/${bookName}');

     */

    _epubReaderController = EpubController(
        document: EpubDocument.openAsset('${contextId}/${revision}/${bookName}'),
    );

    getLocationData().then((value) => {
      setState(() {
        var controllerAttached = _epubReaderController.getIsItemScrollControllerAttached();
        print("controllerAttached = $controllerAttached");
        _epubReaderController.jumpTo(index: value ?? 0);
        //_epubReaderController.scrollTo(index: value ?? 0);
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
      Map<String, dynamic> locatorMap = Map();
      locatorMap[LocatorModelKeys.bookId] = bookId;
      locatorMap[LocatorModelKeys.userId] = userId;
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
              color: Colors.white,
              onPressed: () => _speak(_epubReaderController.selectedText ?? ""),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              color: Colors.white,
              onPressed: () => _getLocatorAndJumpTo(),
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
          builders: EpubViewBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
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

  void _getLocatorAndJumpTo() {
    getLocationData().then((value) =>
    {
      setState(() {
        _epubReaderController.jumpTo(index: value ?? 0);
        //_epubReaderController.scrollTo(index: value ?? 0);
      })
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
