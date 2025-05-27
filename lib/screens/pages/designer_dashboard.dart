import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DesignerDashboard extends StatefulWidget {
  const DesignerDashboard({super.key});

  @override
  State<DesignerDashboard> createState() => _DesignerDashboardState();
}

class _DesignerDashboardState extends State<DesignerDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _projectDescController = TextEditingController();
  final TextEditingController _projectLocationController = TextEditingController();
  final TextEditingController _projectClientController = TextEditingController();
  final TextEditingController _projectPriceController = TextEditingController();
  final TextEditingController _projectYearController = TextEditingController();
  String _projectCategory = 'classic';
  final List<String> _categories = ['classic', 'modern', 'luxury', 'minimalist'];
  bool _isSending = false;
  final String _chatRoomId = '1UF5AOXpQsrRqt6awXIy_MY5K6oZ4sOUW98gk93PaVXVVaO23';

  @override
  void dispose() {
    _messageController.dispose();
    _projectTitleController.dispose();
    _projectDescController.dispose();
    _projectLocationController.dispose();
    _projectClientController.dispose();
    _projectPriceController.dispose();
    _projectYearController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatRoomId)
          .collection('messages')
          .add({
        'message': _messageController.text.trim(),
        'senderId': 'designer',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // Replace with your login route
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _addNewProject() async {
    if (_projectTitleController.text.isEmpty || _projectDescController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('projects').add({
        'title': _projectTitleController.text,
        'description': _projectDescController.text,
        'location': _projectLocationController.text,
        'client': _projectClientController.text,
        'category': _projectCategory,
        'price': int.tryParse(_projectPriceController.text) ?? 0,
        'year': int.tryParse(_projectYearController.text) ?? DateTime.now().year,
        'rating': 0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'designerId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'imageUrl': 'assets/interior-designs/default.jpg',
      });

      _projectTitleController.clear();
      _projectDescController.clear();
      _projectLocationController.clear();
      _projectClientController.clear();
      _projectPriceController.clear();
      _projectYearController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding project: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM d, y hh:mm a').format(timestamp.toDate());
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isDesigner) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isDesigner ? 64 : 8,
        right: isDesigner ? 8 : 64,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDesigner ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message['type'] == 'image')
            Image.network(
              message['message'],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Text('Failed to load image'),
            )
          else
            Text(message['message'] ?? ''),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(message['timestamp']),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(_chatRoomId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No messages yet'));
              }

              final messages = snapshot.data!.docs;
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index].data() as Map<String, dynamic>;
                  final isDesigner = message['senderId'] == 'designer';
                  return _buildMessageBubble(message, isDesigner);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: _isSending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add New Project',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _projectTitleController,
            decoration: const InputDecoration(
              labelText: 'Project Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectDescController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _projectCategory,
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.capitalize()),
              );
            }).toList(),
            onChanged: (value) => setState(() => _projectCategory = value!),
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectLocationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectClientController,
            decoration: const InputDecoration(
              labelText: 'Client Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price (LKR)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _projectYearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addNewProject,
            child: const Text('Add Project'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Designer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMessagesTab(),
          _buildProjectsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Project',
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}