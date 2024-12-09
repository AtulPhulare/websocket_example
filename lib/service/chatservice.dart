import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../model/message.dart';

const String WEBSOCKET_URL = 'wss://echo.websocket.events';

class ChatService {
  final SharedPreferences _prefs;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final _messageController = StreamController<Message>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  Timer? _reconnectionTimer;
  final Set<String> _messagesSentToServer = {};

  ChatService._({required SharedPreferences prefs}) : _prefs = prefs;

  static Future<ChatService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final service = ChatService._(prefs: prefs);
    await service._connectToServer();
    return service;
  }

  Stream<Message> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<void> _connectToServer() async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(WEBSOCKET_URL));
      _isConnected = true;
      _connectionController.add(true);
      _reconnectionTimer?.cancel();

      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: (_) => _handleDisconnection(),
        onDone: _handleDisconnection,
      );

      await sendUndeliveredMessages();
    } catch (_) {
      _handleDisconnection();
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final message = Message.fromMap(json.decode(data));
      _messageController.add(message);
      _markMessageAsDelivered(message.id);
    } catch (_) {}
  }

  void _handleDisconnection() {
    _isConnected = false;
    _connectionController.add(false);
    _channel?.sink.close();
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(const Duration(seconds: 5), _connectToServer);
  }

  Future<void> sendMessage(
      String content, String senderId, String receiverId) async {
    final message = Message(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    await _saveMessage(message);
    _messageController.add(message);

    if (_isConnected && !_messagesSentToServer.contains(message.id)) {
      _sendToServer(message);
    }
  }

  Future<void> _saveMessage(Message message) async {
    final messages = await _getAllMessages();
    messages.add(message.toMap());
    await _prefs.setString('messages', json.encode(messages));
  }

  Future<List<Map<String, dynamic>>> _getAllMessages() async {
    final messagesString = _prefs.getString('messages') ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(messagesString));
  }

  void _sendToServer(Message message) {
    try {
      _channel?.sink.add(json.encode(message.toMap()));
      _messagesSentToServer.add(message.id);
    } catch (_) {}
  }

  Future<void> _markMessageAsDelivered(String messageId) async {
    final messages = await _getAllMessages();
    final updatedMessages = messages.map((map) {
      if (map['id'] == messageId) {
        map['delivered'] = 1;
      }
      return map;
    }).toList();
    await _prefs.setString('messages', json.encode(updatedMessages));
  }

  Future<List<Message>> loadMessages(
      String currentUserId, String recipientId) async {
    final messages = await _getAllMessages();
    return messages
        .where((map) =>
            (map['senderId'] == currentUserId &&
                map['receiverId'] == recipientId) ||
            (map['senderId'] == recipientId &&
                map['receiverId'] == currentUserId))
        .map((map) => Message.fromMap(map))
        .toList();
  }

  Future<void> sendUndeliveredMessages() async {
    if (!_isConnected) return;

    final undeliveredMessages = (await _getAllMessages())
        .where((map) => map['delivered'] == 0)
        .map((map) => Message.fromMap(map))
        .toList();

    for (final message in undeliveredMessages) {
      if (!_messagesSentToServer.contains(message.id)) {
        _sendToServer(message);
      }
    }
  }

  Future<void> dispose() async {
    _reconnectionTimer?.cancel();
    await _messageController.close();
    await _connectionController.close();
    _channel?.sink.close();
  }
}
