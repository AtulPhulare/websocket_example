import 'dart:async';

import 'package:flutter/material.dart';

import 'model/message.dart';
import 'service/chatservice.dart';
import 'utils/ui_helper.dart';

class ChatScreen extends StatefulWidget {
  final ChatService chatService;
  final String currentUserId;
  final String recipientId;

  const ChatScreen({
    super.key,
    required this.chatService,
    required this.currentUserId,
    required this.recipientId,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  late StreamSubscription<Message> _messageSubscription;
  late StreamSubscription<bool> _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load existing messages
    final messages = await widget.chatService.loadMessages(
      widget.currentUserId,
      widget.recipientId,
    );

    setState(() {
      _messages.addAll(messages);
    });

    _messageSubscription =
        widget.chatService.messageStream.listen(_handleNewMessage);
    _connectionSubscription =
        widget.chatService.connectionStream.listen(_handleConnectionChange);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleNewMessage(Message message) {
    if (message.senderId == widget.recipientId ||
        message.senderId == widget.currentUserId) {
      if (!_messages.any((m) => m.id == message.id)) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    }
  }

  void _handleConnectionChange(bool connected) {
    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    await widget.chatService.sendMessage(
      text.trim(),
      widget.currentUserId,
      widget.recipientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UserInfoWidget(
          userId: widget.recipientId,
          isOnline: widget.chatService.isConnected,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: Icon(
              widget.chatService.isConnected
                  ? Icons.cloud_done
                  : Icons.cloud_off,
              color: widget.chatService.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMe = message.senderId == widget.currentUserId;
                  final showDate = index == 0 ||
                      !_isSameDay(
                          _messages[index - 1].timestamp, message.timestamp);

                  return Column(
                    children: [
                      if (showDate) DateDivider(date: message.timestamp),
                      ChatMessageWidget(
                        message: message,
                        isMe: isMe,
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1.0),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: _handleSubmitted,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_messageController.text),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _connectionSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
