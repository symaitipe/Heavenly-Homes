import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/designer.dart';
import '../../model/chat_message.dart';

class ChatPage extends StatefulWidget {
  final Designer designer;

  const ChatPage({super.key, required this.designer});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _showImagePicker = false; // Toggle image picker visibility

  //--------------------- Predefined list of image paths ------------------------------
  final List<String> _imagePaths = ['assets/chat_images/my_house_plan.jpg'];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Generate a unique chat room ID using userId and designerId
  String _getChatRoomId() {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }
    return '${_currentUserId}_${widget.designer.id}';
  }

  // Send a text message to Firestore
  Future<void> _sendTextMessage() async {
    if (_currentUserId == null) return;
    if (_messageController.text.trim().isEmpty) return;

    final chatRoomId = _getChatRoomId();
    final message = ChatMessage(
      senderId: _currentUserId,
      type: 'text',
      message: _messageController.text.trim(),
      timestamp: Timestamp.now(),
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toFirestore());

    _messageController.clear();
    _scrollToBottom();
  }

  // Send an image message to Firestore
  Future<void> _sendImageMessage(String imagePath) async {
    if (_currentUserId == null) return;

    final chatRoomId = _getChatRoomId();
    final message = ChatMessage(
      senderId: _currentUserId,
      type: 'image',
      imagePath: imagePath,
      timestamp: Timestamp.now(),
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toFirestore());

    _scrollToBottom();
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chatRoomId = _getChatRoomId();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.designer.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages =
                    snapshot.data!.docs
                        .map(
                          (doc) => ChatMessage.fromFirestore(
                            doc.data() as Map<String, dynamic>,
                          ),
                        )
                        .toList();

                // Scroll to the bottom when messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding:
                            message.type == 'text'
                                ? const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 10.0,
                                )
                                : const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            if (message.type == 'text' &&
                                message.message != null)
                              Text(
                                message.message!,
                                style: const TextStyle(fontSize: 16),
                              )
                            else if (message.type == 'image' &&
                                message.imagePath != null)
                              Image.asset(
                                message.imagePath!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Image Picker (shown when the attachment icon is pressed)
          if (_showImagePicker)
            Container(
              height: 100,
              color: Colors.grey[100],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8.0),
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) {
                  final imagePath = _imagePaths[index];
                  return GestureDetector(
                    onTap: () {
                      _sendImageMessage(imagePath);
                      setState(() {
                        _showImagePicker = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Image.asset(
                        imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Message Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: _showImagePicker ? Colors.grey : Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _showImagePicker = !_showImagePicker;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onSubmitted: (value) {
                      _sendTextMessage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendTextMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Format timestamp to a readable string
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }
}
