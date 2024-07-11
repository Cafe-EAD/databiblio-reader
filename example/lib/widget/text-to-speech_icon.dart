import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechButton extends StatefulWidget {
  final EpubController epubReaderController;
  const TextToSpeechButton(this.epubReaderController, {Key? key}) : super(key: key);

  @override
  _TextToSpeechButtonState createState() => _TextToSpeechButtonState();
}

class _TextToSpeechButtonState extends State<TextToSpeechButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  bool isPlaying = false;
  late FlutterTts _flutterTts;
  TtsState ttsState = TtsState.stopped;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _initTts();
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _handleOnPressed() async {
    setState(() {
      if (isPlaying) {
        _controller.reverse();
        _pauseTextToSpeech();
      } else {
        _controller.forward();
        extractTextFromEpub(widget.epubReaderController).then((text) {
          _onTextToSpeech(text);
        });
      }
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
      ),
      onPressed: _handleOnPressed,
    );
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
        isPlaying = false;
        _controller.reverse();
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
        isPlaying = false;
        _controller.reverse();
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
        isPlaying = false;
        _controller.reverse();
      });
    });

    _flutterTts.setVolume(volume);
    _flutterTts.setSpeechRate(rate);
    _flutterTts.setPitch(pitch);
  }

  void _onTextToSpeech(String text) {
    if (text.isNotEmpty) {
      _flutterTts.speak(text);
    }
  }

  void _pauseTextToSpeech() {
    _flutterTts.pause();
  }
}

enum TtsState { playing, stopped, paused, continued }

Future<String> extractTextFromEpub(EpubController epubReaderController) async {
  EpubBook? document = await epubReaderController.document;
  if (document == null) return '';

  final StringBuffer buffer = StringBuffer();

  for (var chapter in document.Chapters!) {
    _extractChapterText(chapter, buffer);
  }

  return buffer.toString();
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
