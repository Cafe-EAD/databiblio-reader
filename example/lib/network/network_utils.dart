// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

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
      response = await put(url, body: jsonEncode(request));
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

//region Common
enum HttpMethod { GET, POST, DELETE, PUT }
//endregion