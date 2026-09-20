import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final execUrl = Uri.parse(
      'https://script.google.com/macros/s/AKfycbyV2gqsOom2T_XV2TNqS63m3TcaLqUa7iDjddqS3Cbw3b6__aEWmCKN0Ki5KW52MGPhRA/exec');
  final client = HttpClient();

  final req = await client.postUrl(execUrl);
  req.followRedirects = false;
  req.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
  req.write(jsonEncode({'accion': 'ping', 'hola': 'mundo'}));
  final res = await req.close();
  await res.drain();
  final loc = res.headers.value(HttpHeaders.locationHeader);
  print('POST->exec status=${res.statusCode} loc=$loc');

  if (loc != null) {
    final echo = execUrl.resolve(loc);
    final req2 = await client.getUrl(echo);
    final res2 = await req2.close();
    final body = await res2.transform(utf8.decoder).join();
    print('GET->echo status=${res2.statusCode} body=$body');
  }
  client.close();
}