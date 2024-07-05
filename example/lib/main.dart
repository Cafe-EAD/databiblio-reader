// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:epub_view/epub_view.dart';
import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/question.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epub_view_example/widget/quiz_modal.dart';
import 'package:fl_toast/fl_toast.dart';
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
import 'reader.dart';
import 'widget/bottom_Sheet.dart';
import 'widget/search_match.dart';

import 'package:epub_view/src/data/models/chapter_view_value.dart';

void main() => runApp(const MyApp());

enum TtsState { playing, stopped, paused, continued }

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

ThemeMode _themeMode = ThemeMode.system;

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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

  final book = EpubDocument.openAsset(
    kDebugMode
        ? 'assets/burroughs-mucker.epub'
        : '${Uri.base.queryParameters['contextid'] ?? ""}/${
          Uri.base.queryParameters['revision'] ?? ""}/${
            Uri.base.queryParameters['bookname'] ?? ""}',
  );
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
        home: ReaderScreen(onToggleTheme: _toggleTheme, book: book),
        builder: (context, widget) {
          widget = _getMenu(widget);
          return widget!;
        },
      );
}

_getMenu(widget) {
  return Overlay(
    initialEntries: [
      OverlayEntry(
        builder: (context) {
          return ToastProvider(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: widget!,
            ),
          );
        },
      ),
    ],
  );
}
