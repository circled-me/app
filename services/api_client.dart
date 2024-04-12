import 'dart:convert';
import 'dart:io';
import 'package:app/main.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

typedef JSONObject = Map<String, dynamic>;

class ApiResponse {
  final int status;
  final String body;
  final File? file;
  final Cookie? cookie;
  const ApiResponse(this.status, this.body, this.cookie, {this.file});
}

class ApiClient {
  static const statusException = 666;
  static const cookieName = "token";
  final String baseUrl;
  final _httpClient = http.Client();
  late CacheManager _cacheManager;
  String token;
  ApiClient(this.baseUrl, {this.token = ""}) {
    final key = "api_cache_"+sha1.convert(ascii.encode(baseUrl+"#"+token)).toString();
    _cacheManager = CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 100,
        fileService: HttpFileService(httpClient: _httpClient),
        repo: JsonCacheInfoRepository(databaseName: key),
      ),
    );
    // _cacheManager.emptyCache();
  }

  static final generic = ApiClient("");

  Future<void> emptyCache() async {
    await _cacheManager.emptyCache();
  }

  String fixURI(String uriString) {
    if (uriString.isNotEmpty && uriString[0] == '/') {
      return baseUrl + uriString;
    }
    return uriString;
  }

  String httpToWs(String url) {
    if (url.startsWith("http")) {
      return url.replaceFirst("http", "ws");
    }
    return url;
  }

  Future<WebSocket?> connectWebSocket(String uri) async {
    final url = httpToWs(fixURI(uri));
    try {
      return await WebSocket.connect(url, headers: importantHeaders).timeout(const Duration(seconds: 10));
    } catch (e) {
      print("connectWebSocket exception: $e");
      return null;
    }
  }

  get importantHeaders => {
    "Cookie": cookieName + "=" + token,
    "X-Version": MyApp.version,
  };

  // get requests are always cached
  Future<ApiResponse> get(String uriString, {Map<String,String>? params, bool asFile=false}) async {
    try {
      final uri = Uri.parse(fixURI(uriString)).replace(queryParameters: params);
      final response = await _cacheManager.getSingleFile(uri.toString(), headers: importantHeaders);
      final success = await response.exists();
      if (!success) {
        print("GET URL "+uri.toString()+" not successful?!");
        return const ApiResponse(404, "File does not exist?", null);
      }
      if (asFile) {
        return ApiResponse(200, "", null, file: response);
      }
      return ApiResponse(200, response.readAsStringSync(), null);
    }
    on HttpExceptionWithStatus catch (e) {
      print("HttpExceptionWithStatus:"+e.toString());
      return ApiResponse(e.statusCode, jsonEncode({"error": e.toString()}), null);
    }
    on Exception catch (e) {
      print("Exception:"+e.toString());
      return ApiResponse(statusException, jsonEncode({"error": e.toString()}), null);
    }
    catch (e) {
      print("ERROR:"+e.toString());
      return ApiResponse(statusException, jsonEncode({"error": e.toString()}), null);
    }
  }

  Cookie? _readCookieFrom(http.BaseResponse response) {
    Cookie? cookie;
    response.headers.forEach((key, value) {
      if (key.toLowerCase() != "set-cookie") {
        return;
      }
      cookie = Cookie.fromSetCookieValue(value);
      if (cookie?.name != cookieName) {
        // Ignore all other cookies
        cookie = null;
      }
    });
    return cookie;
  }

  Future<ApiResponse> post(String uriString, {Object? body, Map<String,String>? params}) async {
    return _exec(_httpClient.post, uriString, body: body, params: params);
  }

  Future<ApiResponse> put(String uriString, {Object? body, Map<String,String>? params, Map<String,String> headers = const {}}) async {
    return _exec(_httpClient.put, uriString, body: body, params: params, headers: headers);
  }

  Future<ApiResponse> _exec(Future<http.Response> Function(Uri, {Object? body, Encoding? encoding, Map<String, String>? headers}) httpMethod,
                      String uriString, {Object? body, Map<String,String>? params, Map<String,String>? headers}) async {
    try {
      final uri = Uri.parse(fixURI(uriString)).replace(queryParameters: params);
      final finalHeaders = importantHeaders;
      if (headers != null) {
        finalHeaders.addAll(headers);
      }
      final response = await httpMethod(uri, headers: finalHeaders, body: body);
      if (response.statusCode >= 400) {
        print("URL " + uri.toString() + " not successful, status and response: " + response.statusCode.toString() + "; " + response.body);
      }
      return ApiResponse(response.statusCode, response.body, _readCookieFrom(response));
    } on HttpExceptionWithStatus catch (e) {
      print("HttpExceptionWithStatus:"+e.toString());
      return ApiResponse(e.statusCode, jsonEncode({"error": e.toString()}), null);
    }
  }

  Future<http.StreamedResponse> streamedPut(String uriString, File file, {Map<String,String>? params, Map<String,String> headers = const{}}) async {
    final uri = Uri.parse(fixURI(uriString)).replace(queryParameters: params);
    final streamedRequest = http.StreamedRequest('PUT', uri);
    streamedRequest.headers.addAll(importantHeaders);
    streamedRequest.headers.addAll(headers);
    streamedRequest.contentLength = await file.length();
    file.openRead().listen((chunk) {
      streamedRequest.sink.add(chunk);
    }, onDone: () {
      streamedRequest.sink.close();
    });
    return streamedRequest.send();
  }
}