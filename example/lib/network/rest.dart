import 'dart:convert';

import 'package:epub_view_example/model/bookmark.dart';

import '../model/locator.dart';
import 'network_utils.dart';

const baseUrl = 'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php';

Future<List<BookmarkModel>> getBookmarks(int userId, int bookId) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_get_bookmarks&bookid=$bookId&userid=$userId',
      method: HttpMethod.GET)));

  List<BookmarkModel> result =
      List<BookmarkModel>.from(response.map((model) => BookmarkModel.fromJson(model)));
  return result;
}

Future<List<BookmarkModel>> sendBookmarks(int userId, int bookId, int bookmarkedindex) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_bookmark&bookid=$bookId&userid=$userId&bookmarkedindex=$bookmarkedindex',
      method: HttpMethod.GET)));

  List<BookmarkModel> result =
      List<BookmarkModel>.from(response.map((model) => BookmarkModel.fromJson(model)));
  return result;
}

Future<void> deleteBookmark(int id) async {
  await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_remove_bookmark&id=$id&moodlewsrestformat=json',
      method: HttpMethod.DELETE)));
}

Future<PostLocatorResponse> postLocatorData(Map request) async {
  return PostLocatorResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_locator&params=${jsonEncode(request)}',
      request: request,
      method: HttpMethod.POST))));
}

Future<List<LocatorModel>> getLocatorData(int userId, int bookId) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_get_locator&userid=$userId&bookid=$bookId',
      method: HttpMethod.GET)));
  List<LocatorModel> result =
      List<LocatorModel>.from(response.map((model) => LocatorModel.fromJson(model)));
  return result;
}

Future<PostBookmarkResponse> postBookmark(Map request) async {
  return PostBookmarkResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_locator&params=${jsonEncode(request)}',
      request: request,
      method: HttpMethod.POST))));
}
