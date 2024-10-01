import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:learning_app/model/shape_model.dart';
import 'dart:developer' as devtools;

class DatabaseService {
  final CollectionReference shapesCollection =
      FirebaseFirestore.instance.collection('shapes');

  // Save the shape to the database
  Future<void> saveShape(String shapeName, String imageUrl) async {
    try {
      await shapesCollection.add({
        'shapeName': shapeName,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving shape: $e");
    }
  }

  // Update the shape in the database
  Future<void> updateShape(String shapeId, String shapeName) async {
    try {
      await shapesCollection.doc(shapeId).update({
        'shapeName': shapeName,
        'timestamp':
            FieldValue.serverTimestamp(), // Optionally update timestamp
      });
    } catch (e) {
      print("Error updating shape: $e");
    }
  }

  // Delete the shape from the database
  Future<void> deleteShape(String shapeID, String imageUrl) async {
    try {
      // Delete image from Firebase Storage
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      await shapesCollection.doc(shapeID).delete();
    } catch (e) {
      print("Error deleting shape: $e");
    }
  }

  // Convert Firestore snapshot to a list of ShapeModel objects
  List<ShapeModel> _shapeListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return ShapeModel(
        shapeId: doc.id,
        shapeName: doc['shapeName'] ?? '',
        imageUrl: doc['imageUrl'] ?? '', // Get imageUrl from Firestore data
        // Ensure the timestamp is handled properly, and default to DateTime.now() if null
        timestamp: doc['timestamp'] != null
            ? Timestamp.fromDate((doc['timestamp'] as Timestamp).toDate())
            : Timestamp.fromDate(DateTime.now()),
      );
    }).toList();
  }

  // Stream to get shapes from Firestore
  Stream<List<ShapeModel>> get shapes {
    return shapesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(_shapeListFromSnapshot);
  }

  //Image Uploaded
  Future<void> saveDetectedShape(File? filePath, String label) async {
    if (filePath != null && label.isNotEmpty) {
      try {
        // Upload image to Firebase Storage
        final fileName = filePath.path.split('/').last;
        final storageRef =
            FirebaseStorage.instance.ref().child('shapes/$fileName');
        UploadTask uploadTask = storageRef.putFile(filePath);
        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();

        // Save shape with image URL to Firestore
        //_databaseService.saveShape(label, imageUrl);
        await saveShape(label, imageUrl);
        devtools.log("Shape saved with image URL: $imageUrl");
      } catch (e) {
        devtools.log("Error saving shape: $e");
      }
    } else {
      devtools.log("No image or label detected to save");
    }
  }
}
