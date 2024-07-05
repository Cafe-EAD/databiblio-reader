import 'package:epub_view_example/model/question.dart';
import 'package:flutter/material.dart';

class QuizModal extends StatefulWidget {
  final Question question;
  final VoidCallback onCorrectAnswer;

  const QuizModal(
      {Key? key, required this.question, required this.onCorrectAnswer})
      : super(key: key);

  @override
  State<QuizModal> createState() => _QuizModalState();
}

class _QuizModalState extends State<QuizModal> {
  int? _selectedOptionIndex;
  String? _openAnswerText;

  @override
  void initState() {
    super.initState();
    _selectedOptionIndex = null;
    _openAnswerText = null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 9.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(1),
              blurRadius: 400,
              offset: const Offset(0, 5),
              spreadRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Icon(
                    Icons.flash_on,
                    color: Colors.blue,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Center(
                      child: Text(
                    widget.question.text,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  )),
                ),
              ],
            ),
            _getQuestionModal(widget.question.questionType),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                height: 50, // Set the desired height
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1872F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 24.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed:
                      _selectedOptionIndex != null || _openAnswerText != null
                          ? () {
                              _selectedOptionIndex = null;
                              _openAnswerText = null;
                              widget.onCorrectAnswer();
                            }
                          : null,
                  child: Text(
                    'Responder',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _getQuestionModal(String type) {
    switch (type) {
      case 'Verdadeiro ou Falso':
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedOptionIndex = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedOptionIndex == 0
                        ? Colors.grey[500]
                        : Colors.white,
                    foregroundColor: _selectedOptionIndex == 0
                        ? Colors.black
                        : Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 24.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                    side: _selectedOptionIndex == 0
                        ? const BorderSide(color: Colors.blue, width: 2.0)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Verdadeiro'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedOptionIndex = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedOptionIndex == 1
                        ? Colors.grey[500]
                        : Colors.white,
                    foregroundColor: _selectedOptionIndex == 1
                        ? Colors.black
                        : Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 24.0),
                    textStyle: const TextStyle(fontSize: 16.0),
                    side: _selectedOptionIndex == 1
                        ? const BorderSide(color: Colors.blue, width: 2.0)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Falso'),
                ),
              ),
            ),
          ],
        );
      case 'Resposta Aberta':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            minLines: 3,
            maxLines: null,
            onChanged: (value) {
              setState(() {
                _openAnswerText = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Digite sua resposta',
              border: OutlineInputBorder(),
            ),
          ),
        );
      case 'Múltipla Escolha':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            widget.question.options!.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedOptionIndex = index;
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: _selectedOptionIndex == index
                        ? Colors.grey[500]
                        : Colors.white,
                    border: _selectedOptionIndex == index
                        ? Border.all(color: Colors.blue, width: 2.0)
                        : null,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _selectedOptionIndex == index
                          ? '${widget.question.options![index]} selecionada'
                          : widget.question.options![index],
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      default:
        return Container();
    }
  }
}
