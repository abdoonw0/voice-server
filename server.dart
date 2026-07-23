import 'dart:io';

void main() async {
  // Render يحدد البورت تلقائياً عبر متغيّر البيئة PORT
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('خادم الغرف وإدارة الاتصالات يعمل على البورت: ${server.port}');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      // التعامل مع اتصالات الـ WebSocket للتطبيق
      final socket = await WebSocketTransformer.upgrade(request);
      handleWebSocket(socket); // افترضنا أن هذه دالتك للتعامل مع السوكيت
    } else {
      // استجابة طلبات الـ HTTP من Render (Health Check)
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Server is running!')
        ..close();
    }
  }
}

void handleWebSocket(WebSocket socket) {
  // الكود الخاص بك لإدارة الاتصالات والشبكة هنا...
}
