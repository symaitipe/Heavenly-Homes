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

    // Map isAvailable (bool) to availability (String)
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
      'projects': projects.map((project) => project.toFirestore()).toList(),
    };
  }
}

class Project {
  final String title;
  final String imageUrl;
  final String category;

  Project({
    required this.title,
    required this.imageUrl,
    required this.category,
  });

  factory Project.fromFirestore(Map<String, dynamic> data) {
    // Handle imageUrl: it might be a String or a List<String>
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}