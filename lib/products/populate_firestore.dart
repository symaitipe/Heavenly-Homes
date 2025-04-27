import 'package:cloud_firestore/cloud_firestore.dart';

// Call this function once to populate Firestore
Future<void> populateFirestore() async {
  final firestore = FirebaseFirestore.instance;

  // Add interior designs
  await firestore.collection('interior_designs').add({
    'type': 'Classical',
    'designer':'Kumar Pradeep',
    'budget': 'Rs.50,200',
    'imageUrl': 'https://example.com/classical.jpg',
  });
  await firestore.collection('interior_designs').add({
    'type': 'Luxury',
    'designer':'Sachin Sachin',
    'budget': 'Rs.150,000',
    'imageUrl': 'assets/interior_designs/tv-lobby.jpg',
  });
  await firestore.collection('interior_designs').add({
    'type': 'Modern',
    'designer':'Kumar Kumar',
    'budget': 'Rs.100,000',
    'imageUrl': 'https://example.com/classical.jpg',
  });

  // Add decoration items
  await firestore.collection('decoration_items').add({
    'name': 'U Shape Sofa Set',
    'price': 95000,
    'imageUrl': 'https://example.com/sofa.jpg',
    'isDiscounted': false,
    'category': 'Living Area',
  });
  await firestore.collection('decoration_items').add({
    'name': 'Ceiling Lamp',
    'price': 5000,
    'imageUrl': 'https://example.com/lamp.jpg',
    'isDiscounted': true,
    'category': 'Living Area',
  });
  await firestore.collection('decoration_items').add({
    'name': 'Spring Bed',
    'price': 195000,
    'imageUrl': 'https://example.com/bed.jpg',
    'isDiscounted': false,
    'category': 'Bedroom',
  });
  // Add more items as needed (at least 9 for random selection)
}