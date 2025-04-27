import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/designer.dart';
import '../../constants/app_constants.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final String projectId;

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

  // Track which section is currently active
  int _currentSectionIndex = 0; // 0: details, 1: reviews, 2: comments

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

  Future<void> _submitReview() async {
    if (_currentUserId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (_rating == 0.0) return;

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
      backgroundColor: AppConstants.primaryWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.primaryBlack,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.project.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50, color: Colors.white),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Text(
                      widget.project.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab-like buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSectionButton(
                        label: 'Details',
                        isActive: _currentSectionIndex == 0,
                        onTap: () => setState(() => _currentSectionIndex = 0),
                      ),
                      _buildSectionButton(
                        label: 'Reviews',
                        isActive: _currentSectionIndex == 1,
                        onTap: () => setState(() => _currentSectionIndex = 1),
                      ),
                      _buildSectionButton(
                        label: 'Comments',
                        isActive: _currentSectionIndex == 2,
                        onTap: () => setState(() => _currentSectionIndex = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Content based on selected section
                  _buildCurrentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_currentSectionIndex) {
      case 0: // Details
        return _buildDetailsSection();
      case 1: // Reviews
        return _buildReviewsSection();
      case 2: // Comments
        return _buildCommentsSection();
      default:
        return _buildDetailsSection();
    }
  }

  Widget _buildDetailsSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Category'),
          const SizedBox(height: 8),
          Text(
            widget.project.category,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Description'),
          const SizedBox(height: 8),
          Text(
            widget.project.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Client'),
          const SizedBox(height: 8),
          Text(
            widget.project.client,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Year'),
          const SizedBox(height: 8),
          Text(
            widget.project.year.toString(),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Location'),
          const SizedBox(height: 8),
          Text(
            widget.project.location,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Price'),
          const SizedBox(height: 8),
          Text(
            'LKR ${widget.project.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Reviews'),
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
                              color: AppConstants.primaryGold,
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
          if (!_hasReviewed) ...[
            _buildSectionHeader('Add Your Review'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppConstants.primaryGold,
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
              decoration: InputDecoration(
                hintText: 'Add an optional comment (part of your review)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppConstants.primaryWhite,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGold,
                foregroundColor: AppConstants.primaryBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Submit Review'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Comments'),
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
          _buildSectionHeader('Add a Comment'),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppConstants.primaryWhite,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryGold,
              foregroundColor: AppConstants.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit Comment'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryGold : AppConstants.primaryWhite,
          border: Border.all(
            color: isActive ? AppConstants.primaryGold : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? AppConstants.primaryBlack : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppConstants.primaryBlack,
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}