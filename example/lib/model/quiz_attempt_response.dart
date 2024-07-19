class QuizAttemptResponse {
  final AttemptData attempt;
  final List<dynamic> warnings;

  QuizAttemptResponse({
    required this.attempt,
    required this.warnings,
  });

  factory QuizAttemptResponse.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResponse(
      attempt: AttemptData.fromJson(json['attempt']),
      warnings: json['warnings'],
    );
  }
}

class AttemptData {
  final int id;
  final int quiz;
  final int userid;
  final int attempt;
  final int uniqueid;
  final String layout;
  final int currentpage;
  final int preview;
  final String state;
  final int timestart;
  final int timefinish;
  final int timemodified;
  final int timemodifiedoffline;
  final dynamic timecheckstate;
  final dynamic sumgrades;
  final dynamic gradednotificationsenttime;

  AttemptData({
    required this.id,
    required this.quiz,
    required this.userid,
    required this.attempt,
    required this.uniqueid,
    required this.layout,
    required this.currentpage,
    required this.preview,
    required this.state,
    required this.timestart,
    required this.timefinish,
    required this.timemodified,
    required this.timemodifiedoffline,
    required this.timecheckstate,
    required this.sumgrades,
    required this.gradednotificationsenttime,
  });

  factory AttemptData.fromJson(Map<String, dynamic> json) {
    return AttemptData(
      id: json['id'],
      quiz: json['quiz'],
      userid: json['userid'],
      attempt: json['attempt'],
      uniqueid: json['uniqueid'],
      layout: json['layout'],
      currentpage: json['currentpage'],
      preview: json['preview'],
      state: json['state'],
      timestart: json['timestart'],
      timefinish: json['timefinish'],
      timemodified: json['timemodified'],
      timemodifiedoffline: json['timemodifiedoffline'],
      timecheckstate: json['timecheckstate'],
      sumgrades: json['sumgrades'],
      gradednotificationsenttime: json['gradednotificationsenttime'],
    );
  }
}