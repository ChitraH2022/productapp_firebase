import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

  final CollectionReference notes =
  FirebaseFirestore.instance.collection('products');

  Future<void> addProduct(String name, String description, double price) {
    return notes.add({
      'name': name,
      'description': description,
      'price': price,
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getNotesStream() {
    return notes.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> updateProduct(String docID, String name, String description, double price) {
    return notes.doc(docID).update({
      'name': name,
      'description': description,
      'price': price,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> deleteProduct(String docID) {
    return notes.doc(docID).delete();
  }
}
