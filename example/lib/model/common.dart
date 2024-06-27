import '../utils/model_keys.dart';

class GenericPostResponse {
  bool success;
  String message;

  GenericPostResponse({ required this.success, required this.message });

  factory GenericPostResponse.fromJson(Map<String, dynamic> json) {
    return GenericPostResponse(
        success: json[CommonModelKeys.success],
        message: json[CommonModelKeys.message]
    );
  }
}