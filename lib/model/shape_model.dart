import 'package:cloud_firestore/cloud_firestore.dart';

class ShapeModel {
  final String shapeId;
  final String shapeName;
  final String imageUrl; // Add imageUrl field
  final Timestamp timestamp;

  ShapeModel({
    required this.shapeId,
    required this.shapeName,
    required this.imageUrl, // Initialize imageUrl
    required this.timestamp,
  });

  // Factory method to create a ShapeModel from Firestore data
  factory ShapeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShapeModel(
      shapeId: doc.id,
      shapeName: data['shapeName'] ?? '',
      imageUrl: data['imageUrl'] ?? '', // Get imageUrl from Firestore data
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
