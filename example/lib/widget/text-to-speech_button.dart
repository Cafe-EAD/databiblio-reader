import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechButton extends StatefulWidget {
  final String texto;
  const TextToSpeechButton(this.texto, {Key? key}) : super(key: key);

  @override
  TextToSpeechButtonState createState() => TextToSpeechButtonState();
}

class TextToSpeechButtonState extends State<TextToSpeechButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool isPlaying = false;
  final int maxCar = 3900;
  final FlutterTts _flutterTts = FlutterTts();
  List<Map<String, String>> _voices = [];
  Map<String, String>? _currentVoice;

  int chunkAtual = 0;
  List<String>? textChunks;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    initTTS();
    loadText();
    _loadVoices();
  }

  void loadText() {
    var texto = widget.texto.replaceAll('\n', '');
    textChunks = _splitTextIntoChunks(texto, maxCar);
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
        _flutterTts.stop();
        _controller.reverse();
      } else {
        chunkAtual = 0;
        _flutterTts.speak(textChunks![chunkAtual]);
        _controller.forward();
      }
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero),
                ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        showMenu(
          context: context,
          position: position,
          items: <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'language',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Voz'), Icon(Icons.language)],
              ),
            ),
            PopupMenuItem<String>(
              value: 'stop',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isPlaying ? 'Parar' : 'Play'),
                  Icon(isPlaying ? Icons.stop : Icons.play_arrow)
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value != null) {
            switch (value) {
              case 'stop':
                _handleOnPressed();
                break;
              case 'language':
                _showVoiceSelector();
                break;
            }
          }
        });
      },
      child: IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _controller,
        ),
        onPressed: _handleOnPressed,
      ),
    );
  }

  void initTTS() {
    // posiçao no texto
    // _flutterTts.setProgressHandler((text, start, end, word) {
    //   setState(() {
    //     _currentWordStart = start;
    //     _currentWordEnd = end;
    //   });
    // });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        if (textChunks!.length == chunkAtual) {
          // print("Complete");
          _controller.reverse();
          isPlaying = false;
        } else {
          chunkAtual++;
          _flutterTts.speak(textChunks![chunkAtual]);
        }
      });
    });
  }

  void _setVoice(Map voice) {
    _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
  }

  void _showVoiceSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione uma voz'),
          content: DropdownButton<Map<String, String>>(
            value: _currentVoice,
            items: _voices
                .map(
                  (voice) => DropdownMenuItem<Map<String, String>>(
                    value: voice,
                    child: Text(
                      voice["name"]!,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _currentVoice = value;
              });
              if (value != null) {
                _setVoice(value);
              }
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _loadVoices() async {
    var data = await _flutterTts.getVoices;
    try {
      _voices = (data as List)
          .map((voice) => Map<String, String>.from(voice))
          .toList();
      setState(() {
        if (_voices.isNotEmpty) {
          _currentVoice =
              _voices.firstWhere((voice) => voice["name"]!.contains("en"));
          _setVoice(_currentVoice!);
        }
      });
    } catch (e) {

    }
  }
}

List<String> _splitTextIntoChunks(String text, int maxSize) {
  List<String> chunks = [];
  int start = 0;

  while (start < text.length) {
    int end = start + maxSize;

    if (end >= text.length) {
      chunks.add(text.substring(start).trim());
      break;
    }

    int lastSpace = text.lastIndexOf(' ', end);

    if (lastSpace == -1 || lastSpace < start) {
      lastSpace = end;
    }

    chunks.add(text.substring(start, lastSpace).trim());
    start = lastSpace + 1;
  }

  return chunks;
}
