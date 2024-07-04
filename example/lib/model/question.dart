class Question {
  final int id;
  final int chapterNumber;
  final String text;
  final List<String>? options;
  final int? correctAnswerIndex;
  final String questionType;

  Question({
    required this.id,
    required this.chapterNumber,
    required this.text,
    this.options,
    this.correctAnswerIndex,
    required this.questionType,
  });
}
