class QuizData {
  final int quizId;
  final String quizName;
  final String pagina;

  QuizData({
    required this.quizId,
    required this.quizName,
    required this.pagina,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      quizId: json['quizid'],
      quizName: json['quizname'],
      pagina: json['pagina'],
    );
  }
}