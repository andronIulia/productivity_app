import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskManager {
  late final String? uid;
  late final CollectionReference userDailyTasksRef;
  late final CollectionReference userOtherTasksRef;

  TaskManager() {
    uid = FirebaseAuth.instance.currentUser?.uid;
    userDailyTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
    userOtherTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('other_tasks');
  }

  Future<void> addDailyTask(String taskName) async {
    if (taskName.isNotEmpty) {
      final taskData = {'title': taskName, 'isDone': false};
      await userDailyTasksRef.add(taskData);
    }
  }

  Future<void> addOtherTask(String taskName) async {
    if (taskName.isNotEmpty) {
      final taskData = {'title': taskName, 'isDone': false};
      await userOtherTasksRef.add(taskData);
    }
  }

  Future<void> deleteDailyTask(String docId) async {
    await userDailyTasksRef.doc(docId).delete();
  }

  Future<void> deleteOtherTask(String docId) async {
    await userOtherTasksRef.doc(docId).delete();
  }

  Future<void> updateDailyTask(String docId, bool isDone) async {
    await userDailyTasksRef.doc(docId).update({'isDone': isDone});
  }

  Future<void> updateOtherTask(String docId, bool isDone) async {
    await userOtherTasksRef.doc(docId).update({'isDone': isDone});
  }

  Future<void> resetDailyTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayString = "${now.year}-${now.month}-${now.day}";
    final lastReset = prefs.getString('lastTaskReset') ?? '';
    if (lastReset != todayString) {
      final snapshot = await userDailyTasksRef.get();
      for (var doc in snapshot.docs) {
        await userDailyTasksRef.doc(doc.id).update({'isDone': false});
      }
      await prefs.setString('lastTaskReset', todayString);
    }
  }

  Future<bool> hasTasksForToday() async {
    if (uid == null) return false;
    final remainingTasks =
        await userDailyTasksRef.where('isDone', isEqualTo: false).get();
    return remainingTasks.docs.isNotEmpty;
  }
}
