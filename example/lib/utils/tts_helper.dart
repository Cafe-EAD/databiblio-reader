import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

late FlutterTts flutterTts;
dynamic languages;
late String language;
double volume = 1.0;
double pitch = 1.0;
double rate = 0.5;

TtsState ttsState = TtsState.stopped;

get isPlaying => ttsState == TtsState.playing;
get isStopped => ttsState == TtsState.stopped;

initTts() {
  print('Initializing TTS');
  flutterTts = FlutterTts();

  flutterTts.getVoices.then((data) {
    try {
      List<Map> _voices = List<Map>.from(data);
      print(_voices);
      //setState(() {});
    } catch (e) {
      print(e);
    }
  });
  getLanguages();

  flutterTts.setStartHandler(() {
    print("playing");
    ttsState = TtsState.playing;
  });
  //flutterTts.setStartHandler;

  flutterTts.setCompletionHandler(() {
    print("Complete");
    ttsState = TtsState.stopped;
  });
  //flutterTts.setCompletionHandler;

  flutterTts.setErrorHandler((msg) {
    print("error: $msg");
    ttsState = TtsState.stopped;
  });
}

Future getLanguages() async {
  languages = await flutterTts.getLanguages;
  print("pritty print ${languages}");
  //  if (languages != null) setState(() => languages);
}

Future speak(String text) async {
  print('Volume: ' + volume.toString());
  flutterTts.setLanguage('en-US');
  flutterTts.setVolume(volume);
  flutterTts.setSpeechRate(rate);
  flutterTts.setPitch(pitch);

  if (text != null) {
    if (text.isNotEmpty) {
      flutterTts.setLanguage('en-US');
      var result = await flutterTts.speak(text);
      if (result == 1) ttsState = TtsState.playing;
    }
  }
}

Future stop() async {
  var result = await flutterTts.stop();
  if (result == 1) ttsState = TtsState.stopped;
}

@override
void dispose() {
  // super.dispose();
  flutterTts.stop();
}

void changedLanguageDropDownItem(String selectedType) {
  language = selectedType;
  flutterTts.setLanguage('en-US');
}

@override
Widget build(BuildContext context) {
  // TODO: implement build
  throw UnimplementedError();
}
