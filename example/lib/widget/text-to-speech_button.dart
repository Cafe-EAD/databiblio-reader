import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechButton extends StatefulWidget {
  final String texto;
  const TextToSpeechButton(this.texto, {Key? key})
      : super(key: key);

  @override
  TextToSpeechButtonState createState() => TextToSpeechButtonState();
}


class TextToSpeechButtonState extends State<TextToSpeechButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool isPlaying = false;
  final int maxCar = 3900;
  final FlutterTts _flutterTts = FlutterTts();
  List<Map> _voices = [];
  Map? _currentVoice;

 int chunkAtual=0;
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
  }

void loadText()  {
  var texto = widget.texto.replaceAll('\n', '');
 textChunks =  _splitTextIntoChunks(texto, maxCar);
  
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
        chunkAtual=0;
        _flutterTts.speak(textChunks![chunkAtual]);
        _controller.forward();
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

  void initTTS() {
    // posiçao no texto 
    // _flutterTts.setProgressHandler((text, start, end, word) {
    //   setState(() {
    //     _currentWordStart = start;
    //     _currentWordEnd = end;
    //   });
    // });
    _flutterTts.getVoices.then((data) {
      try {
        List<Map> voices = List<Map>.from(data);
        setState(() {
          _voices =
              voices.where((voice) => voice["name"].contains("en")).toList();
          _currentVoice = _voices.first;
          _setVoice(_currentVoice!);
        });
      } 
      catch (e) {
        SnackBar(content: Text('$e'),);
      }
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        if(textChunks!.length==chunkAtual){
        // print("Complete");
        _controller.reverse();
        isPlaying=false;
        }else{
          chunkAtual++;
          _flutterTts.speak(textChunks![chunkAtual]);
        }
      });
    });

  }

    void _setVoice(Map voice) {
    _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
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
