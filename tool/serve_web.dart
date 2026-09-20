// Servidor local simple para previsualizar la app web (solo usa dart:io).
// Uso:  dart tool/serve_web.dart --port 8080
import 'dart:io';

Future<void> main(List<String> args) async {
  final portArg = args.length > 1 ? args[1] : null;
  final port = int.tryParse(portArg ?? '') ?? 8080;
  final root = Directory('build/web');

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Servidor activo: http://localhost:$port  (carpeta: ${root.path})');

  await for (final request in server) {
    try {
      var path = request.uri.path == '/' ? '/index.html' : request.uri.path;
      final file = File('${root.path}${path}');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        request.response.headers.contentType = _contentType(path);
        request.response.add(bytes);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not found');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Error: $e');
    } finally {
      await request.response.close();
    }
  }
}

ContentType _contentType(String path) {
  final dot = path.lastIndexOf('.');
  final ext = dot >= 0 ? path.substring(dot + 1).toLowerCase() : '';
  switch (ext) {
    case 'html':
      return ContentType.html;
    case 'js':
    case 'mjs':
      return ContentType('application', 'javascript');
    case 'css':
      return ContentType('text', 'css');
    case 'json':
      return ContentType.json;
    case 'png':
      return ContentType('image', 'png');
    case 'jpg':
    case 'jpeg':
      return ContentType('image', 'jpeg');
    case 'svg':
      return ContentType('image', 'svg+xml');
    case 'ico':
      return ContentType('image', 'x-icon');
    case 'wasm':
      return ContentType('application', 'wasm');
    case 'ttf':
      return ContentType('font', 'ttf');
    case 'otf':
      return ContentType('font', 'otf');
    case 'map':
      return ContentType('application', 'json');
    default:
      return ContentType('application', 'octet-stream');
  }
}