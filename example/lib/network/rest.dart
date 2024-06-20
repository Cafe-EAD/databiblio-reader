import 'dart:convert';
import 'package:epub_view_example/model/bookmark.dart';

import '../model/locator.dart';
import 'package:http/http.dart' as http;

import 'network_utils.dart';

Future<PostLocatorResponse> postLocatorData(Map request) async {
  return PostLocatorResponse.fromJson(await (handleResponse(await buildHttpResponse(
      'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php?wstoken=2ab3f1e2a757c5bc5e1d3a32c7680395'
          '&wsfunction=local_wsgetbooks_post_locator'
          '&moodlewsrestformat=json'
          '&params='+jsonEncode(request),
      request: request, method: HttpMethod.POST))));
}

Future<List<LocatorModel>> getLocatorData(int userId, int bookId) async {
  List<dynamic> response = await (handleResponse(await buildHttpResponse(
      'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php?wstoken=2ab3f1e2a757c5bc5e1d3a32c7680395'
          '&wsfunction=local_wsgetbooks_get_locator'
          '&moodlewsrestformat=json'
          '&userid=$userId&bookid=$bookId',
      method: HttpMethod.GET)));
  List<LocatorModel> result = List<LocatorModel>.from(response.map((model) => LocatorModel.fromJson(model)));

  return result;
}

Future<PostBookmarkResponse> postBookmark(Map request) async {
  return PostBookmarkResponse.fromJson(await (handleResponse(await buildHttpResponse(
      'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php?wstoken=2ab3f1e2a757c5bc5e1d3a32c7680395'
          '&wsfunction=local_wsgetbooks_post_locator'
          '&moodlewsrestformat=json'
          '&params='+jsonEncode(request),
      request: request, method: HttpMethod.POST))));
}

