import 'dart:convert';

import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/common.dart';
import 'package:epub_view_example/model/highlight_model.dart';
import 'package:epub_view_example/model/quiz_attempt_data.dart';
import 'package:epub_view_example/model/quiz_attempt_response.dart';
import 'package:epub_view_example/model/quiz_data.dart';
import '../model/locator.dart';
import 'network_utils.dart';
import 'package:http/http.dart' as http;

const baseUrl =
    'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php';

Future<List<HighlightModel>> getHighlights(int userId, int bookId) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_get_highlights&userid=$userId&bookid=$bookId',
      method: HttpMethod.GET)));
  List<HighlightModel> result = List<HighlightModel>.from(
      response.map((model) => HighlightModel.fromJson(model)));
  return result;
}

Future<GenericPostResponse> postHighlight(
    int userId,
    int bookId,
    String chapter,
    String paragraph,
    String startindex,
    String selectionlength,
    String highlightedText) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_highlights&bookid=$bookId&userid=$userId&chapter=$chapter&paragraph=$paragraph&startindex=$startindex&selectionlength=$selectionlength&highlighted_text=$highlightedText',
      method: HttpMethod.POST))));
}

Future<GenericPostResponse> deleteHighlight(int highlightId) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_delete_highlights&highlightid=$highlightId',
      method: HttpMethod.DELETE))));
}

Future<List<BookmarkModel>> getBookmarks(int userId, int bookId) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_get_bookmarks&userid=$userId&bookid=$bookId',
      method: HttpMethod.GET)));
  List<BookmarkModel> result = List<BookmarkModel>.from(
      response.map((model) => BookmarkModel.fromJson(model)));
  return result;
}

Future<GenericPostResponse> postBookmark(
    int bookId, int userId, int bookmarkedIndex, String title) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_bookmark&userid=$userId&bookid=$bookId&bookmarkedindex=$bookmarkedIndex&title=$title',
      method: HttpMethod.POST))));
}

Future<GenericPostResponse> deleteBookmark(int id) async {
  return GenericPostResponse.fromJson(await (handleResponse(
      await buildHttpResponse(
          '$baseUrl?wsfunction=local_wsgetbooks_remove_bookmark&id=$id',
          method: HttpMethod.DELETE))));
}

Future<GenericPostResponse> postLocatorData(Map request) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_locator&params=${jsonEncode(request)}',
      request: request,
      method: HttpMethod.POST))));
}

Future<List<LocatorModel>> getLocatorData(int userId, int bookId) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_get_locator&userid=$userId&bookid=$bookId',
      method: HttpMethod.GET)));
  List<LocatorModel> result = List<LocatorModel>.from(
      response.map((model) => LocatorModel.fromJson(model)));
  return result;
}

Future<GenericPostResponse> postBookmarkNote(
    int bookmarkId, String noteText) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_bookmarknotes&bookmarkid=$bookmarkId&notetext=$noteText',
      method: HttpMethod.POST))));
}

Future<GenericPostResponse> deleteBookmarkNote(int id) async {
  return GenericPostResponse.fromJson(await (handleResponse(
      await buildHttpResponse(
          '$baseUrl?wsfunction=local_wsgetbooks_remove_bookmarknotes&id=$id',
          method: HttpMethod.DELETE))));
}

Future<List<QuizData>?> getAllDesafio(String bookid) async {
  final response = await (handleResponse(await buildHttpResponse(
    '$baseUrl?wsfunction=local_wsgetbooks_get_bookquiz&bookid=$bookid',
    method: HttpMethod.GET,
  )));
  List<QuizData> result =
      List<QuizData>.from(response.map((model) => QuizData.fromJson(model)));
  return result;
}

Future<QuizAttemptData?> getDesafio(String attemptid) async {
  Map<String, dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=mod_quiz_get_attempt_data&attemptid=$attemptid&page=0',
      method: HttpMethod.GET,
      wsTokenBoll: true)));
  return QuizAttemptData.fromJson(response);
}

Future<QuizAttemptResponse?> getAttempt(String quizid) async {
  Map<String, dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=mod_quiz_start_attempt&quizid=$quizid',
      method: HttpMethod.GET,
      wsTokenBoll: true)));
  return QuizAttemptResponse.fromJson(response);
}

Future<Map<String, dynamic>> saveAttempt(
  String attemptid,
  Map<String, String> data,
) async {
    final url =
        '$baseUrl?wsfunction=mod_quiz_save_attempt&attemptid=$attemptid&moodlewsrestformat=json';

    final queryString = data.entries.map((entry) {
      final encodedName = Uri.encodeQueryComponent(entry.key);
      final encodedValue = Uri.encodeQueryComponent(entry.value);
      return '$encodedName=$encodedValue';
    }).join('&');

    final fullUrl = '$url&$queryString';
    // print('URL da requisição: $fullUrl');
    final response = await (handleResponse(await buildHttpResponse(
      fullUrl,
      method: HttpMethod.GET,
      wsTokenBoll: true,
    )));

    return response;
}

Future<Map<String, dynamic>> processAttempt(String attemptId) async {
  Map<String, dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=mod_quiz_process_attempt&attemptid=$attemptId&finishattempt=1',
      method: HttpMethod.GET,
      wsTokenBoll: true)));
      return response;
}

Future<GenericPostResponse> postReadingTime(
    int userId, int bookId, int page, int timeSpent) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_readingtime&userid=$userId&bookid=$bookId&page=$page&timespent=$timeSpent',
      method: HttpMethod.POST))));
}
