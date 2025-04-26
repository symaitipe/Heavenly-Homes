import 'package:cloud_firestore/cloud_firestore.dart';

class Designer {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String address;
  final String availability;
  final String about;
  final List<String> phoneNumbers;
  final String email;
  final String location;
  final String services;
  final List<Project> projects;

  Designer({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.availability,
    required this.about,
    required this.phoneNumbers,
    required this.email,
    required this.location,
    required this.services,
    required this.projects,
  });

  factory Designer.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> phoneNumbers = [];
    final phoneNumbersData = data['phoneNumbers'];
    if (phoneNumbersData is List) {
      phoneNumbers = List<String>.from(phoneNumbersData);
    } else if (phoneNumbersData is String && phoneNumbersData.isNotEmpty) {
      phoneNumbers = [phoneNumbersData];
    }

    String availability = 'Availability unknown';
    if (data.containsKey('isAvailable')) {
      availability = data['isAvailable'] == true ? 'Available Now' : 'Not Available';
    } else if (data['availability'] is String) {
      availability = data['availability'] as String;
    }

    return Designer(
      id: id,
      name: data['name'] is String ? data['name'] as String : 'Unknown Designer',
      imageUrl: data['imageUrl'] is String ? data['imageUrl'] as String : '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      address: data['address'] is String ? data['address'] as String : 'No address provided',
      availability: availability,
      about: data['about'] is String ? data['about'] as String : 'No information available',
      phoneNumbers: phoneNumbers,
      email: data['email'] is String ? data['email'] as String : 'No email provided',
      location: data['location'] is String ? data['location'] as String : 'No location provided',
      services: data['services'] is String ? data['services'] as String : 'No services listed',
      projects: (data['projects'] as List<dynamic>?)
          ?.map((project) => Project.fromFirestore(project as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'address': address,
      'availability': availability,
      'about': about,
      'phoneNumbers': phoneNumbers,
      'email': email,
      'location': location,
      'services': services,
      'projects': projects.map((project) => project.toFirestore()).toList(),
    };
  }
}

class Project {
  final String title;
  final String imageUrl;
  final String category;
  final String description;
  final String client;
  final int year;
  final String location;
  final double price;
  final List<Review> reviews;
  final List<Comment> comments;

  Project({
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.client,
    required this.year,
    required this.location,
    required this.price,
    required this.reviews,
    required this.comments,
  });

  factory Project.fromFirestore(Map<String, dynamic> data) {
    String imageUrl = '';
    final imageUrlData = data['imageUrl'];
    if (imageUrlData is String) {
      imageUrl = imageUrlData;
    } else if (imageUrlData is List && imageUrlData.isNotEmpty) {
      imageUrl = imageUrlData.first as String;
    }

    return Project(
      title: data['title'] is String ? data['title'] as String : 'Untitled Project',
      imageUrl: imageUrl,
      category: data['category'] is String ? data['category'] as String : 'Uncategorized',
      description: data['description'] is String ? data['description'] as String : 'No description available',
      client: data['client'] is String ? data['client'] as String : 'Unknown Client',
      year: (data['year'] as num?)?.toInt() ?? 0,
      location: data['location'] is String ? data['location'] as String : 'No location provided',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      reviews: [], // Will be fetched separately from a sub collection
      comments: [], // Will be fetched separately from a sub collection
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
      'description': description,
      'client': client,
      'year': year,
      'location': location,
      'price': price,
      // Reviews and comments are stored in sub collections, not in the main document
    };
  }
}

class Review {
  final String userId;
  final double rating;
  final String? comment;
  final Timestamp timestamp;

  Review({
    required this.userId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory Review.fromFirestore(Map<String, dynamic> data) {
    return Review(
      userId: data['userId'] as String? ?? 'Unknown',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'timestamp': timestamp,
    };
  }
}

class Comment {
  final String userId;
  final String text;
  final Timestamp timestamp;

  Comment({
    required this.userId,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromFirestore(Map<String, dynamic> data) {
    return Comment(
      userId: data['userId'] as String? ?? 'Unknown',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}