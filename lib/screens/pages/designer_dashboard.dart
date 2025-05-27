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
  bool _isLoading = true;
  int _totalProjects = 0;
  List<Map<String, dynamic>> _chatPreviews = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final designerDoc = await FirebaseFirestore.instance
          .collection('designers')
          .doc('1UF5AOXpQsrRqt6awXIy')
          .get();

      final chatRooms = {
        _chatRoomId: 'Sahan Yasas',
        'chatRoom2': 'Aritha de Silva',
        'chatRoom3': 'Senara Nimni',
      };
      List<Map<String, dynamic>> previews = [];
      for (var entry in chatRooms.entries) {
        final messagesQuery = await FirebaseFirestore.instance
            .collection('chats')
            .doc(entry.key)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (messagesQuery.docs.isNotEmpty) {
          previews.add({
            'userName': entry.value,
            'message': messagesQuery.docs.first.data(),
            'chatRoomId': entry.key,
          });
        } else {
          previews.add({
            'userName': entry.value,
            'message': {
              'message': entry.value == 'Sahan Yasas'
                  ? 'Can we discuss the project timeline?'
                  : entry.value == 'Aritha de Silva'
                  ? 'Hi, can you share the latest design draft?'
                  : 'I love the minimalist vibe! Any updates?',
              'senderId': 'client',
              'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(days: entry.value == 'Sahan Yasas' ? 4 : entry.value == 'Aritha de Silva' ? 2 : 3))),
              'type': 'text',
            },
            'chatRoomId': entry.key,
          });
        }
      }

      setState(() {
        _totalProjects = (designerDoc.data()?['projects'] as List?)?.length ?? 0;
        _totalProjects = 1; // Faking total projects as 1
        _chatPreviews = previews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dashboard data: $e')),
      );
    }
  }

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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
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
      await FirebaseFirestore.instance
          .collection('designers')
          .doc('1UF5AOXpQsrRqt6awXIy')
          .update({
        'projects': FieldValue.arrayUnion([
          {
            'title': _projectTitleController.text,
            'description': _projectDescController.text,
            'location': _projectLocationController.text,
            'client': _projectClientController.text,
            'category': _projectCategory,
            'price': int.tryParse(_projectPriceController.text) ?? 0,
            'year': int.tryParse(_projectYearController.text) ?? DateTime.now().year,
            'imageUrl': 'assets/interior-designs/default.jpg',
          }
        ])
      });

      _projectTitleController.clear();
      _projectDescController.clear();
      _projectLocationController.clear();
      _projectClientController.clear();
      _projectPriceController.clear();
      _projectYearController.clear();

      await _fetchDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding project: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Sending...'; // Display a placeholder while the timestamp is pending
    }
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

  Widget _buildChatPreview(String userName, Map<String, dynamic> message, String chatRoomId) {
    return ListTile(
      leading: CircleAvatar(child: Text(userName[0])),
      title: Text(userName),
      subtitle: Text(message['message'] ?? 'No messages yet'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(chatRoomId: chatRoomId),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Designer Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard('Total Projects', _totalProjects.toString(), Icons.work),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Latest Messages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._chatPreviews.map((preview) => _buildChatPreview(
                    preview['userName'],
                    preview['message'],
                    preview['chatRoomId'],
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _selectedIndex = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Manage Projects',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFakeChatPreviewsForMessagesTab() {
    return [
      {
        'userName': 'Aritha de Silva',
        'message': {
          'message': 'Hi, can you share the latest design draft?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'type': 'text',
        },
        'chatRoomId': 'chatRoom2',
      },
      {
        'userName': 'Senara Nimni',
        'message': {
          'message': 'I love the minimalist vibe! Any updates?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          'type': 'text',
        },
        'chatRoomId': 'chatRoom3',
      },
      {
        'userName': 'Kamal Perera',
        'message': {
          'message': 'Can we discuss the budget for the project?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          'type': 'text',
        },
        'chatRoomId': 'chatRoom4',
      },
    ];
  }

  Widget _buildMessagesTab() {
    final fakeChatPreviews = _getFakeChatPreviewsForMessagesTab();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Messages',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...fakeChatPreviews.map((preview) => _buildChatPreview(
            preview['userName'],
            preview['message'],
            preview['chatRoomId'],
          )),
        ],
      ),
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
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
            tooltip: 'Refresh',
          ),
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
          _buildHomeTab(),
          _buildMessagesTab(),
          _buildProjectsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Projects',
          ),
        ],
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String chatRoomId;

  const ChatDetailPage({super.key, required this.chatRoomId});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  List<Map<String, dynamic>> _getFakeChatHistory() {
    if (widget.chatRoomId == 'chatRoom2') { // Aritha de Silva
      return [
        {
          'message': 'Hi, can you share the latest design draft?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'type': 'text',
        },
        {
          'message': 'Sure, I’ll send it by tomorrow!',
          'senderId': 'designer',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'type': 'text',
        },
      ];
    } else if (widget.chatRoomId == 'chatRoom3') { // Senara Nimni
      return [
        {
          'message': 'I love the minimalist vibe! Any updates?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          'type': 'text',
        },
        {
          'message': 'Thanks! I’ve added a new layout, check it out.',
          'senderId': 'designer',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'type': 'text',
        },
        {


          'message': 'Great work! Let’s discuss pricing next.',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'type': 'text',
        },
      ];
    } else if (widget.chatRoomId == 'chatRoom4') { // Kamal Perera
      return [
        {
          'message': 'Can we discuss the budget for the project?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          'type': 'text',
        },
        {
          'message': 'Of course, let’s schedule a meeting.',
          'senderId': 'designer',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
          'type': 'text',
        },
      ];
    } else if (widget.chatRoomId == '1UF5AOXpQsrRqt6awXIy_MY5K6oZ4sOUW98gk93PaVXVVaO23') { // Sahan Yasas
      return [
        {
          'message': 'Can we discuss the project timeline?',
          'senderId': 'client',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
          'type': 'text',
        },
        {
          'message': 'Yes, let’s set a meeting for next week.',
          'senderId': 'designer',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          'type': 'text',
        },
      ];
    }
    return [];
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'message': _messageController.text.trim(),
        'senderId': 'designer',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'read': false,
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Sending...'; // Display a placeholder while the timestamp is pending
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomId == '1UF5AOXpQsrRqt6awXIy_MY5K6oZ4sOUW98gk93PaVXVVaO23'
            ? 'Sahan Yasas'
            : widget.chatRoomId == 'chatRoom2'
            ? 'Aritha de Silva'
            : widget.chatRoomId == 'chatRoom3'
            ? 'Senara Nimni'
            : 'Kamal Perera'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<Map<String, dynamic>> messages = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  messages = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                }
                messages.addAll(_getFakeChatHistory());
                messages.sort((a, b) {
                  final aTimestamp = a['timestamp'] as Timestamp?;
                  final bTimestamp = b['timestamp'] as Timestamp?;
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  return bTimestamp.compareTo(aTimestamp);
                });

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
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