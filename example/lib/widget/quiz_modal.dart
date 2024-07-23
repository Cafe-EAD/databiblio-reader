import 'package:epub_view_example/model/quiz_attempt_data.dart';
import 'package:epub_view_example/network/rest.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;

class QuizModal extends StatefulWidget {
  final QuizAttemptData? questions;
  final Function(int) onQuizFinished;

  const QuizModal({
    Key? key,
    this.questions,
    required this.onQuizFinished,
  }) : super(key: key);

  @override
  State<QuizModal> createState() => _QuizModalState();
}

class _QuizModalState extends State<QuizModal> {
  final GlobalKey _htmlKey = GlobalKey();
  String? _selectedOptionIndex;
  String? _openAnswerText;
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedOptionIndex = null;
    _openAnswerText = null;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        child: widget.questions == null
            ? const CircularProgressIndicator.adaptive()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionContent(_currentPage),
                  _buildAnswerOptions(_currentPage), // Passar o índice atual
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      height: 50,
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
                        onPressed: () {
                          if (widget.questions != null &&
                              (_selectedOptionIndex != null ||
                                  _openAnswerText != null)) {
                            if (_currentPage <
                                widget.questions!.questions.length - 1) {
                              // Avança para a próxima página
                              _enviarRespostaIndividual();
                              setState(() {
                                _currentPage++;
                              });
                              _pageController
                                  .animateToPage(
                                _currentPage,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                                  .then((_) {
                                // Limpa as seleções após a animação
                                setState(() {
                                  _selectedOptionIndex = null;
                                  _openAnswerText = null;
                                });
                              });
                            } else {
                              _enviarResposta();
                            }
                          }
                        },
                        child: Text(
                          'Responder',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionContent(int index) {
    if (widget.questions!.questions[index].html != null) {
      return SizedBox(
        child: SingleChildScrollView(
          child: Html(
            key: _htmlKey,
            data: widget.questions!.questions[index].html!,
          ),
        ),
      );
    } else {
      return const CircularProgressIndicator.adaptive();
    }
  }

  Widget _buildAnswerOptions(int index) {
    switch (widget.questions!.questions[index].type) {
      case 'truefalse':
        return Column(
          children: [
            RadioListTile<String>(
              title: const Text('Verdadeiro'),
              value: '1',
              groupValue: _selectedOptionIndex,
              onChanged: (value) {
                setState(() {
                  _selectedOptionIndex = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Falso'),
              value: '0',
              groupValue: _selectedOptionIndex,
              onChanged: (value) {
                setState(() {
                  _selectedOptionIndex = value;
                });
              },
            ),
          ],
        );
      case 'essay':
        return TextField(
          onChanged: (value) {
            setState(() {
              _openAnswerText = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Digite sua resposta',
            border: OutlineInputBorder(),
          ),
        );
      case 'multichoice':
        final document = parser.parse(widget.questions!.questions[index].html);
        final answerOptions =
            document.querySelectorAll('input[type="radio"][name*="_answer"]');
        // Filtrar as opções de resposta para excluir o "Limpar minha escolha"

        final filteredOptions = answerOptions.where((element) =>
            element.id != 'q${widget.questions!.attempt.id}:1_answer-1');
        return Column(
          children: List.generate(
            filteredOptions.length,
            (index) {
              final optionValue =
                  filteredOptions.elementAt(index).attributes['value'];
              final optionLabel = filteredOptions
                  .elementAt(index)
                  .nextElementSibling
                  ?.text
                  ?.trim();

              return RadioListTile<String>(
                title: Text(optionLabel ?? 'Opção ${index + 1}'),
                value: optionValue.toString(),
                groupValue: _selectedOptionIndex,
                onChanged: (value) {
                  setState(() {
                    _selectedOptionIndex = value;
                  });
                },
              );
            },
          ),
        );
      default:
        return Container();
    }
  }

  Future<void> _enviarResposta() async {
    final attemptId = widget.questions!.attempt.id;
    final data = <String, String>{};
    int dataIndex = 0;

    for (int i = 0; i < widget.questions!.questions.length; i++) {
      final question = widget.questions!.questions[i];
      final questionKey = 'q$attemptId:${i + 1}';

      data['data[$dataIndex][name]'] = 'slot';
      data['data[$dataIndex][value]'] = '1';
      dataIndex++;

      data['data[$dataIndex][name]'] = '$questionKey' + '_:sequencecheck';
      data['data[$dataIndex][value]'] = '1';
      dataIndex++;

      if (question.type == 'truefalse') {
        final resposta = _selectedOptionIndex == '1' ? 'true' : 'false';
        data['data[$dataIndex][name]'] = '$questionKey\_answer';
        data['data[$dataIndex][value]'] = '$questionKey\_answer$resposta';
      } else if (question.type == 'multichoice') {
        data['data[$dataIndex][name]'] = '$questionKey\_answer';
        data['data[$dataIndex][value]'] = _selectedOptionIndex ?? '';
      } else if (question.type == 'essay') {
        data['data[$dataIndex][name]'] = '$questionKey\_answer';
        data['data[$dataIndex][value]'] = _openAnswerText ?? '';
      }
      dataIndex++;
    }

    // Enviar a resposta para a API
    //  print('Dados enviados para a API: $data');

    try {
      final response = await saveAttempt(attemptId.toString(), data);
      if (response['status'] == true) {
        print('Resposta enviada com sucesso!');
        processAttempt(attemptId.toString());
        widget.onQuizFinished(attemptId);
      } else {
        widget.onQuizFinished(attemptId);
        print('Erro ao enviar resposta: ${response['warnings']}');
      }
    } catch (e) {
      print('Erro ao enviar resposta: $e');
    }
  }

  Future<void> _enviarRespostaIndividual() async {
    final attemptId = widget.questions!.attempt.id;
    final data = <String, String>{};
    int dataIndex = 0;

    final question = widget.questions!.questions[_currentPage];
    final questionKey = 'q$attemptId:${_currentPage + 1}';

    data['data[$dataIndex][name]'] = 'slot';
    data['data[$dataIndex][value]'] = question.slot.toString();
    dataIndex++;

    data['data[$dataIndex][name]'] = '$questionKey' + '_:sequencecheck';
    data['data[$dataIndex][value]'] = '1';
    dataIndex++;

    if (question.type == 'truefalse') {
      final resposta = _selectedOptionIndex == '1' ? 'true' : 'false';
      data['data[$dataIndex][name]'] = '$questionKey\_answer';
      data['data[$dataIndex][value]'] = '$questionKey\_answer$resposta';
    } else if (question.type == 'multichoice') {
      data['data[$dataIndex][name]'] = '$questionKey\_answer';
      data['data[$dataIndex][value]'] = _selectedOptionIndex ?? '';
    } else if (question.type == 'essay') {
      data['data[$dataIndex][name]'] = '$questionKey\_answer';
      data['data[$dataIndex][value]'] = _openAnswerText ?? '';
    }
    dataIndex++;
    try {
      final response = await saveAttempt(attemptId.toString(), data);
      if (response['status'] == true) {
        print('Resposta individual enviada com sucesso!');
      } else {
        print('Erro ao enviar resposta individual: ${response['warnings']}');
      }
    } catch (e) {
      print('Erro ao enviar resposta individual: $e');
    }
  }
}
