import 'package:epub_view/src/data/models/common.dart';
import 'package:epub_view/src/network/network_utils.dart';

const baseUrl = 'https://databiblion.cafeeadhost.com.br/webservice/rest/server.php';

Future<GenericPostResponse> postHighlight(int userId, int bookId, String chapter, String paragraph,
    String startindex, String selectionlength, String highlightedText) async {
  return GenericPostResponse.fromJson(await (handleResponse(await buildHttpResponse(
      '$baseUrl?wsfunction=local_wsgetbooks_post_highlights&bookid=$bookId&userid=$userId&chapter=$chapter&paragraph=$paragraph&startindex=$startindex&selectionlength=$selectionlength&highlighted_text=$highlightedText',
      method: HttpMethod.POST))));
}
