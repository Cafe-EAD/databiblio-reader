class QuizAttemptData {
  final Attempt attempt;
  final List<dynamic> messages;
  final int nextpage;
  final List<QuestionData> questions;
  final List<dynamic> warnings;

  QuizAttemptData({
    required this.attempt,
    required this.messages,
    required this.nextpage,
    required this.questions,
    required this.warnings,
  });

  factory QuizAttemptData.fromJson(Map<String, dynamic> json) {
    return QuizAttemptData(
      attempt: Attempt.fromJson(json['attempt']),
      messages: json['messages'],
      nextpage: json['nextpage'],
      questions: List<QuestionData>.from(
        json['questions'].map((question) => QuestionData.fromJson(question)),
      ),
      warnings: json['warnings'],
    );
  }
}

class Attempt {
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

  Attempt({
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

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
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

class QuestionData {
  final int slot;
  final String type;
  final int page;
  final String questionnumber;
  final int number;
  final String html;
  final List<dynamic> responsefileareas;
  final int sequencecheck;
  final int lastactiontime;
  final bool hasautosavedstep;
  final bool flagged;
  final String status;
  final bool blockedbyprevious;
  final int maxmark;
  final String? settings;

  QuestionData({
    required this.slot,
    required this.type,
    required this.page,
    required this.questionnumber,
    required this.number,
    required this.html,
    required this.responsefileareas,
    required this.sequencecheck,
    required this.lastactiontime,
    required this.hasautosavedstep,
    required this.flagged,
    required this.status,
    required this.blockedbyprevious,
    required this.maxmark,
    this.settings,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      slot: json['slot'],
      type: json['type'],
      page: json['page'],
      questionnumber: json['questionnumber'],
      number: json['number'],
      html: json['html'],
      responsefileareas: json['responsefileareas'],
      sequencecheck: json['sequencecheck'],
      lastactiontime: json['lastactiontime'],
      hasautosavedstep: json['hasautosavedstep'],
      flagged: json['flagged'],
      status: json['status'],
      blockedbyprevious: json['blockedbyprevious'],
      maxmark: json['maxmark'],
      settings: json['settings'],
    );
  }
}