import 'dart:convert';

import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/common.dart';
import 'package:epub_view_example/model/highlight_model.dart';
import 'package:epub_view_example/utils/constants.dart';
import 'package:http/http.dart' as http;
import '../model/locator.dart';
import 'network_utils.dart';

const baseUrl =
    'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php';

Future<List<HighlightModel>> getHighlights(int userId, int bookId) async {
  try {
    String wsfunction = 'local_wsgetbooks_get_highlights';
    Uri url = Uri.parse(baseUrl).replace(queryParameters: {
      'wstoken': WSTOKEN,
      'wsfunction': wsfunction,
      // 'bookid': bookId.toString(),
      // 'userid': userId.toString(),
      'bookid': '4',
      'userid': '2',
      'moodlewsrestformat': 'json'
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      List<HighlightModel> result = responseData
          .map((highlight) => HighlightModel.fromJson(highlight))
          .toList();
      return result;
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erro ao obter destaques: $e');
  }
}

Future<dynamic> postHighlight(
  int userId,
  int bookId, {
  required String chapter,
  required String paragraph,
  required String startindex,
  required String selectionlength,
}) async {
  try {
    String wsfunction = 'local_wsgetbooks_post_highlights';
    Uri url = Uri.parse(baseUrl).replace(queryParameters: {
      'wstoken': WSTOKEN,
      'wsfunction': wsfunction,
      // 'bookid': bookId.toString(),
      // 'userid': userId.toString(),
      'bookid': '4',
      'userid': '2',
      'moodlewsrestformat': 'json',
      'chapter': chapter,
      'paragraph': paragraph,
      'startindex': startindex,
      'selectionlength': selectionlength,
    });

    final response = await http.post(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Error creating highlight: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}

// Future<GenericPostResponse> postLocatorData(Map request) async {
//   return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
//       '$baseUrl?wsfunction=local_wsgetbooks_post_locator&params=${jsonEncode(request)}',
//       request: request,
//       method: HttpMethod.POST))));
// }
Future<GenericPostResponse> deleteHighlight(int highlightId) async {
  // Future<dynamic> deleteHighlight(int highlightId) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_delete_highlights&highlightid=$highlightId',
      method: HttpMethod.DELETE))));
}
//   try {
//     String wsfunction = 'local_wsgetbooks_delete_highlights';
//     Uri url = Uri.parse(baseUrl).replace(queryParameters: {
//       'wstoken': WSTOKEN,
//       'wsfunction': wsfunction,
//       'highlightid': highlightId.toString(),
//       'moodlewsrestformat': 'json',
//     });

//     final response = await http.delete(url);

//     if (response.statusCode == 200) {
//       return response.body;
//     } else {
//       throw Exception('Error deleting highlight: ${response.statusCode}');
//     }
//   } catch (e) {
//     throw Exception('Error: $e');
//   }
// }

Future<List<BookmarkModel>> getBookmarks(int userId, int bookId) async {
  String wsfunction = 'local_wsgetbooks_get_bookmarks';
  Uri url = Uri.parse(baseUrl).replace(queryParameters: {
    'wstoken': WSTOKEN,
    'wsfunction': wsfunction,
    'bookid': bookId.toString(),
    'userid': userId.toString(),
    'moodlewsrestformat': 'json'
  });

  // List<dynamic> response = await (handleResponse(await buildHttpResponse(
  //     '$baseUrl?wsfunction=local_wsgetbooks_get_bookmarks&userid=$userId&bookid=$bookId',
  //     method: HttpMethod.GET)));
  // List<BookmarkModel> result = List<BookmarkModel>.from(
  //     response.map((model) => BookmarkModel.fromJson(model)));

  final response = await http.get(url);
  final List<dynamic> responseData = jsonDecode(response.body);
  List<BookmarkModel> result =
      responseData.map((bookmark) => BookmarkModel.fromJson(bookmark)).toList();
  return result;
}

Future<dynamic> postBookmark(
    int bookId, int userId, int bookmarkedIndex) async {
  String wsfunction = 'local_wsgetbooks_post_bookmark';
  Uri url = Uri.parse(URLBOOK).replace(queryParameters: {
    'wstoken': WSTOKEN,
    'wsfunction': wsfunction,
    'bookid': bookId.toString(),
    'userid': userId.toString(),
    'bookmarkedindex': bookmarkedIndex.toString(),
    'moodlewsrestformat': 'json'
  });
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erro ao remover nota do marcador: $e');
  }
}

Future<dynamic> deleteBookmark(int id) async {
  String wsfunction = 'local_wsgetbooks_remove_bookmark';
  Uri url = Uri.parse(URLBOOK).replace(queryParameters: {
    'wstoken': WSTOKEN,
    'wsfunction': wsfunction,
    'id': id.toString(),
    'moodlewsrestformat': 'json'
  });
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erro ao remover nota do marcador: $e');
  }
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

Future<dynamic> postBookmarkNote(int bookmarkId, String noteText) async {
  String wsfunction = 'local_wsgetbooks_post_bookmarknotes';
  Uri url = Uri.parse(URLBOOK).replace(queryParameters: {
    'wstoken': WSTOKEN,
    'wsfunction': wsfunction,
    'bookmarkid': bookmarkId.toString(),
    'notetext': noteText,
    'moodlewsrestformat': 'json'
  });
  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erro ao remover nota do marcador: $e');
  }
}

Future<dynamic> deleteBookmarkNote(int id) async {
  String wsfunction = 'local_wsgetbooks_remove_bookmarknotes';
  Uri url = Uri.parse(URLBOOK).replace(queryParameters: {
    'wstoken': WSTOKEN,
    'wsfunction': wsfunction,
    'id': id.toString(),
    'moodlewsrestformat': 'json'
  });

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Erro na requisição: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erro ao remover nota do marcador: $e');
  }
}
