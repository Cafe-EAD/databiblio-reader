// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:epub_view_example/utils/notifications.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

//import 'package:granth_flutter/main.dart';
import '../configs.dart';
import '../utils/constants.dart';

//import '../utils/common.dart';

Map<String, String> buildHeaderTokens() {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.acceptHeader: 'application/json; charset=utf-8',
    HttpHeaders.accessControlAllowOriginHeader: '*',
    HttpHeaders.accessControlAllowHeadersHeader: '*',
  };
/*
  if (appStore.isLoggedIn) {
    header.putIfAbsent(HttpHeaders.authorizationHeader, () => 'Bearer ${appStore.token}');
  }

 */
  log(jsonEncode(header));
  return header;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('$BASE_URL$endPoint');
  return url;
}

Future<Response> buildHttpResponse(String endPoint,
    {HttpMethod method = HttpMethod.GET,
    Map? request,
    bool isStripePayment = false}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    const wsToken = '2ab3f1e2a757c5bc5e1d3a32c7680395';
    Uri url =
        buildBaseUrl('$endPoint&wstoken=$wsToken&moodlewsrestformat=json');
    log(url);

    Response response;

    if (method == HttpMethod.POST) {
      log('Request: $request');
      response = await http.post(
        url,
        body: jsonEncode(request),
        headers: headers,
        encoding: isStripePayment ? Encoding.getByName("utf-8") : null,
      );
    } else if (method == HttpMethod.DELETE) {
      response = await delete(url, headers: headers);
    } else if (method == HttpMethod.PUT) {
      response = await put(url, body: jsonEncode(request), headers: headers);
    } else {
      response = await get(url, headers: headers);
    }

    log('Response (${method.name}) ${response.statusCode}: ${response.body}');

    return response;
  } else {
    throw errorInternetNotAvailable;
  }
}

Future handleResponse(Response response, [bool? avoidTokenError]) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }
  if (response.statusCode == 401) {
    if (!avoidTokenError.validate()) LiveStream().emit(LIVESTREAM_TOKEN, true);
    throw 'Token Expired';
  }

  if (response.statusCode.isSuccessful()) {
    return jsonDecode(response.body);
  } else {
    try {
      var body = jsonDecode(response.body);
      throw parseHtmlString(body['message']);
    } on Exception catch (e) {
      log(e);
      throw errorSomethingWentWrong;
    }
  }
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

Future<MultipartRequest> getMultiPartRequest(String endPoint,
    {String? baseUrl}) async {
  String url = baseUrl ?? buildBaseUrl(endPoint).toString();
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future<void> sendMultiPartRequest(MultipartRequest multiPartRequest,
    {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  http.Response response =
      await http.Response.fromStream(await multiPartRequest.send());
  print("Result: ${response.statusCode}");

  if (response.statusCode.isSuccessful()) {
    onSuccess?.call(response.body);
  } else {
    onError?.call(errorSomethingWentWrong);
  }
}

Future<dynamic> getBookmarksInfo(int bookId, int userId) async {
  if (await isNetworkAvailable()) {
    String wsfunction = 'local_wsgetbooks_get_bookmarks';
    Uri url = Uri.parse(URLBOOK).replace(queryParameters: {
      'wstoken': WSTOKEN,
      'wsfunction': wsfunction,
      'bookid': bookId.toString(),
      'userid': userId.toString(),
      'moodlewsrestformat': 'json'
    });
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('object');
        print(response.body);
        print('object --');
        return response;
      } else {
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar marcadores: $e');
    }
  } else {
    throw Exception('Sem conexão com a internet.');
  }
}

Future<dynamic> postBookmarkInfo(
    int bookId, int userId, int bookmarkedIndex) async {
  if (await isNetworkAvailable()) {
    String wsfunction = 'local_wsgetbooks_post_bookmark';
    Uri url = Uri.parse(URLBOOK).replace(queryParameters: {
      'wstoken': WSTOKEN,
      'wsfunction': wsfunction,
      'bookid': bookId.toString(),
      'userid': userId.toString(),
      'bookmarkedindex': bookmarkedIndex.toString(),
      'moodlewsrestformat': 'json'
    });

    print(url);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Notifications.success(
          title: "Ok",
          message: "Seu marcador foi salvo com sucesso",
          duration: const Duration(seconds: 10),
        );
        print(url);
        return response.body;
      } else {
        print(response);
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Erro ao adicionar marcador: $e');
    }
  } else {
    throw Exception('Sem conexão com a internet.');
  }
}

Future<dynamic> removeBookmarkInfo(int id) async {
  if (await isNetworkAvailable()) {
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
        Notifications.success(
          title: "Ok",
          message: "Removido com sucesso",
          duration: const Duration(seconds: 10),
        );
        return response;
      } else {
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao remover marcador: $e');
    }
  } else {
    throw Exception('Sem conexão com a internet.');
  }
}

Future<dynamic> postBookmarkNotesInfo(int bookmarkId, String noteText) async {
  if (await isNetworkAvailable()) {
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
        print('object');
        print(response.body);
        print('object');
        Notifications.success(
          title: "Ok",
          message: "Sua nota foi salva com sucesso",
          duration: const Duration(seconds: 10),
        );
        return response.body;
      } else {
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao adicionar nota: $e');
    }
  } else {
    throw Exception('Sem conexão com a internet.');
  }
}

Future<dynamic> removeBookmarkNotesInfo(int id) async {
  if (await isNetworkAvailable()) {
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
        Notifications.success(
          title: "Ok",
          message: "Removido com sucesso",
          duration: const Duration(seconds: 10),
        );
        print(response);
        return response;
      } else {
        throw Exception('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao remover nota do marcador: $e');
    }
  } else {
    throw Exception('Sem conexão com a internet.');
  }
}

//region Common
enum HttpMethod { GET, POST, DELETE, PUT }
//endregion