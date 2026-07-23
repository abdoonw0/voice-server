import 'dart:convert';
import 'dart:io';

// تخزين الغرف والأجهزة المتصلة بها
final Map<String, List<WebSocket>> rooms = {};

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('✅ خادم الغرف وإدارة الاتصالات يعمل على البورت: 8080');

  server.listen((HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      String? currentRoom;

      socket.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final String action = data['action'] ?? '';

            // 1. إنشاء غرفة جديدة
            if (action == 'create_room') {
              final String roomId = data['roomId'];
              currentRoom = roomId;
              rooms[roomId] = [socket];
              print('🏠 تم إنشاء غرفة جديدة برقم: $roomId');
              socket.add(jsonEncode({'type': 'room_created', 'roomId': roomId}));
            }

            // 2. الانضمام لغرفة قائمة (مع التحقق من الوجود)
            else if (action == 'join_room') {
              final String roomId = data['roomId'];
              
              if (rooms.containsKey(roomId) && rooms[roomId]!.isNotEmpty) {
                currentRoom = roomId;
                rooms[roomId]!.add(socket);
                print('📱 جهاز انضم للغرفة القائمة: $roomId');
                
                // إعلام المنضم بالنجاح
                socket.add(jsonEncode({'type': 'room_joined', 'roomId': roomId}));
                
                // إعلام المنشئ بأن هناك طرفاً ثانياً انضم لبدء التحدث
                for (var client in rooms[roomId]!) {
                  if (client != socket) {
                    client.add(jsonEncode({'type': 'peer_joined'}));
                  }
                }
              } else {
                // الغرفة غير موجودة!
                print('⚠️ محاولة انضمام لغرفة غير موجودة: $roomId');
                socket.add(jsonEncode({'type': 'error_room_not_found', 'message': 'الغرفة غير موجودة!'}));
              }
            }

            // 3. تمرير إشارات WebRTC الصوتية بين أطراف الغرفة
            else if (action == 'signal') {
              if (currentRoom != null && rooms.containsKey(currentRoom)) {
                for (var client in rooms[currentRoom]!) {
                  if (client != socket && client.readyState == WebSocket.open) {
                    client.add(jsonEncode(data['payload']));
                  }
                }
              }
            }
          } catch (e) {
            print("خطأ في معالجة الرسالة: $e");
          }
        },
        onDone: () => _cleanSocket(socket, currentRoom),
        onError: (_) => _cleanSocket(socket, currentRoom),
      );
    }
  });
}

void _cleanSocket(WebSocket socket, String? room) {
  if (room != null && rooms.containsKey(room)) {
    rooms[room]?.remove(socket);
    if (rooms[room]!.isEmpty) {
      rooms.remove(room);
      print('🗑️ تم إغلاق الغرفة الخالية: $room');
    }
  }
}