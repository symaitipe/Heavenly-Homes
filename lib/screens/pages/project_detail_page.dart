import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/designer.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final String projectId; // Add projectId to fetch reviews/comments

  const ProjectDetailPage({super.key, required this.project, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final TextEditingController _reviewCommentController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0;
  bool _hasReviewed = false;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  @override
  void dispose() {
    _reviewCommentController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Check if the current user has already reviewed this project
  Future<void> _checkIfReviewed() async {
    if (_currentUserId == null) return;

    final reviewDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('reviews')
        .doc(_currentUserId)
        .get();

    if (reviewDoc.exists) {
      setState(() {
        _hasReviewed = true;
      });
    }
  }

  // Submit a review
  Future<void> _submitReview() async {
    if (_currentUserId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (_rating == 0.0) return; // Ensure a rating is selected

    final review = Review(
      userId: _currentUserId,
      rating: _rating,
      comment: _reviewCommentController.text.trim().isNotEmpty
          ? _reviewCommentController.text.trim()
          : null,
      timestamp: Timestamp.now(),
    );

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('reviews')
        .doc(_currentUserId)
        .set(review.toFirestore());

    setState(() {
      _hasReviewed = true;
      _rating = 0.0;
      _reviewCommentController.clear();
    });
  }

  // Submit a comment
  Future<void> _submitComment() async {
    if (_currentUserId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (_commentController.text.trim().isEmpty) return;

    final comment = Comment(
      userId: _currentUserId,
      text: _commentController.text.trim(),
      timestamp: Timestamp.now(),
    );

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('comments')
        .add(comment.toFirestore());

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.project.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50),
                ),
              ),
              const SizedBox(height: 16),
              // Project Title
              Text(
                widget.project.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Category
              Text(
                'Category: ${widget.project.category}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Client
              const Text(
                'Client',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.client,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Year
              const Text(
                'Year',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.year.toString(),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Location
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.location,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Price
              const Text(
                'Price',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'LKR ${widget.project.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Reviews Section
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('reviews')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading reviews');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No reviews yet.');
                  }

                  final reviews = snapshot.data!.docs
                      .map((doc) => Review.fromFirestore(doc.data() as Map<String, dynamic>))
                      .toList();

                  return Column(
                    children: reviews.map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < review.rating.floor()
                                      ? Icons.star
                                      : (index < review.rating
                                      ? Icons.star_half
                                      : Icons.star_border),
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            if (review.comment != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                review.comment!,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'By User ${review.userId.substring(0, 8)}... on ${_formatTimestamp(review.timestamp)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Add Review Section
              if (!_hasReviewed) ...[
                const Text(
                  'Add Your Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                TextField(
                  controller: _reviewCommentController,
                  decoration: const InputDecoration(
                    hintText: 'Add an optional comment (part of your review)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text('Submit Review'),
                ),
                const SizedBox(height: 16),
              ],
              // Comments Section
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading comments');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No comments yet.');
                  }

                  final comments = snapshot.data!.docs
                      .map((doc) => Comment.fromFirestore(doc.data() as Map<String, dynamic>))
                      .toList();

                  return Column(
                    children: comments.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.text,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By User ${comment.userId.substring(0, 8)}... on ${_formatTimestamp(comment.timestamp)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Add Comment Section
              const Text(
                'Add a Comment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitComment,
                child: const Text('Submit Comment'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}