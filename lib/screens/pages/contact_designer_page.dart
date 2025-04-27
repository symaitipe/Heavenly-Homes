import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/designer.dart';
import 'designer_detail_page.dart';
import 'chat_page.dart';

class ContactDesignerPage extends StatefulWidget {
  const ContactDesignerPage({super.key});

  @override
  State<ContactDesignerPage> createState() => _ContactDesignerPageState();
}

class _ContactDesignerPageState extends State<ContactDesignerPage> {
  bool _isDesignerTab = true; // Track the selected tab
  String _searchQuery = ''; // Track the search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet Your Interior Designer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Tabs (I Need Interior Designer / I Will Select My Designs)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isDesignerTab = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isDesignerTab ? Colors.black : Colors.white,
                      foregroundColor:
                          _isDesignerTab ? Colors.white : Colors.black,
                      side: BorderSide(
                        color: _isDesignerTab ? Colors.black : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'I Need Interior Designer',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isDesignerTab = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !_isDesignerTab ? Colors.black : Colors.white,
                      foregroundColor:
                          !_isDesignerTab ? Colors.white : Colors.black,
                      side: BorderSide(
                        color: !_isDesignerTab ? Colors.black : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'I Will Select My Designs',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Bar (only visible in "I Need Interior Designer" tab)
          if (_isDesignerTab)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search Designers',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          // Content based on selected tab
          Expanded(
            child:
                _isDesignerTab
                    ? _buildDesignerList()
                    : const Center(
                      child: Text(
                        'Browse Interior Designs feature coming soon!',
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('designers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading designers'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No designers available'));
        }

        final designers =
            snapshot.data!.docs
                .map(
                  (doc) => Designer.fromFirestore(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

        // Filter designers based on search query
        final filteredDesigners =
            _searchQuery.isEmpty
                ? designers
                : designers
                    .where(
                      (designer) => designer.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

        if (filteredDesigners.isEmpty) {
          return const Center(child: Text('No designers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredDesigners.length,
          itemBuilder: (context, index) {
            final designer = filteredDesigners[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Profile Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        designer.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Designer Details
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to DesignerDetailPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      DesignerDetailPage(designer: designer),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              designer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < designer.rating.floor()
                                          ? Icons.star
                                          : (index < designer.rating
                                              ? Icons.star_half
                                              : Icons.star_border),
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${designer.reviewCount} Reviews)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              designer.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                designer.availability,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Send Message Button
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        // Navigate to ChatPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(designer: designer),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
