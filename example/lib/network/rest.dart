import 'dart:convert';

import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/common.dart';

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

Future<GenericPostResponse> postBookmark(int userId, int bookId, int bookMarkedIndex) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_bookmark&bookid=$bookId'
      '&userid=$userId&bookmarkedindex=$bookMarkedIndex',
      method: HttpMethod.GET))));
}

Future<GenericPostResponse> deleteBookmark(int id) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
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
  List<LocatorModel> result =
      List<LocatorModel>.from(response.map((model) => LocatorModel.fromJson(model)));
  return result;
}

Future<GenericPostResponse> postBookmarkNote(int bookmarkId, String noteText) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_bookmarknotes&bookmarkid=$bookmarkId&notetext=$noteText',
      method: HttpMethod.POST))));
}

Future<GenericPostResponse> deleteBookmarkNote(int id) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_remove_bookmarknotes&id=$id',
      method: HttpMethod.DELETE))));
}