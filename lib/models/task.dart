import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String title;
  bool isDone;

  Task({this.id = '', required this.title, this.isDone = false});

  factory Task.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'isDone': isDone};
  }
}
