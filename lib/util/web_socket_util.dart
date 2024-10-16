import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketUtil {
  late IO.Socket socket;

  // Singleton 패턴으로 웹 소켓을 공유 가능하도록 설정
  static final WebSocketUtil _instance = WebSocketUtil._internal();

  factory WebSocketUtil() {
    return _instance;
  }

  WebSocketUtil._internal();

  // 웹 소켓 초기화 함수
  void initializeSocketConnection(String serverUrl) {
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // websocket 전송만 허용
          .enableAutoConnect() // 자동 연결 활성화
          .build(),
    );

    socket.onConnect((_) {
      print('Connected to Socket.IO server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
    });

    socket.onError((error) {
      print('Socket error: $error');
    });
  }

  // 메시지 수신 이벤트 처리
  void on(String eventName, Function(dynamic) callback) {
    socket.on(eventName, (data) {
      callback(data);
    });
  }

  // 메시지 송신 함수
  void emit(String eventName, dynamic data) {
    socket.emit(eventName, data);
  }

  // 소켓 자원 해제
  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}
