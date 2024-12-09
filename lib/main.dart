import 'package:flutter/material.dart';
import 'chatscreen.dart';
import 'service/chatservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final chatService = await ChatService.initialize();
  runApp(MultiUserChatApp(chatService: chatService));
}

class MultiUserChatApp extends StatelessWidget {
  final ChatService chatService;

  const MultiUserChatApp({super.key, required this.chatService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const UserSelectionScreen(),
    );
  }
}

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _openChat(context, 'user123', 'recipient456'),
              child: const Text('Login as User 1'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openChat(context, 'recipient456', 'user123'),
              child: const Text('Login as User 2'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(
      BuildContext context, String currentUserId, String recipientId) {
    final chatService =
        context.findAncestorWidgetOfExactType<MultiUserChatApp>()?.chatService;
    if (chatService != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatService: chatService,
            currentUserId: currentUserId,
            recipientId: recipientId,
          ),
        ),
      );
    }
  }
}
