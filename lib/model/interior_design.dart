// lib/models/interior_design.dart
class InteriorDesign {
  final String type;
  final String designer;
  final String budget;
  final String imageUrl;

  InteriorDesign({
    required this.type,
    required this.designer,
    required this.budget,
    required this.imageUrl,
  });

  factory InteriorDesign.fromFirestore(Map<String, dynamic> data) {
    return InteriorDesign(
      type: data['type'] ?? 'Unknown',
      designer: data['designer'] ?? 'Unknown',
      budget: data['budget'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}