// ignore_for_file: file_names

import 'package:http/http.dart' as http;

class GoogleAuthClientService extends http.BaseClient{

  late final Map<String,String> _headers; 
  final http.Client _client = new http.Client();

  GoogleAuthClientService(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

}
