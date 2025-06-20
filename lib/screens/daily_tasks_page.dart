import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});
}

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});
  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  //List<Task> tasks = [];
  final TextEditingController _controller = TextEditingController();

  String? uid;
  late final CollectionReference userDailyTasksRef;

  late final Stream<QuerySnapshot> dailyTasksStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    uid = user!.uid;

    userDailyTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');

    dailyTasksStream = userDailyTasksRef.snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void addTask() {
    //setState(() {
    final title = _controller.text;
    if (title.isNotEmpty) {
      final taskData = {'title': title, 'isDone': false};
      userDailyTasksRef.add(taskData);
      _controller.clear();
    }
    //});
  }

  /*void updateTask(String title, bool isDone) {
    setState(() {
      userDailyTasksRef.doc(title).update({isDone: !isDone});
    });
  }*/

  void deleteTask(String docId) {
    userDailyTasksRef.doc(docId).delete();
  }

  /*Future<bool> hasTasksForToday() async {
    final tasksRemaining =
        await userDailyTasksRef.where('isDone', isEqualTo: false).get();
    return tasksRemaining.docs.isNotEmpty;
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: StreamBuilder<QuerySnapshot>(
                stream: dailyTasksStream,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading");
                  }
                  final taskDocs = snapshot.data!.docs;
                  if (taskDocs.isEmpty) {
                    return const Text("No tasks yet");
                  }
                  return ListView.builder(
                    itemCount: taskDocs.length,
                    itemBuilder: (context, index) {
                      final doc = taskDocs[index];
                      final taskTile = doc['title'];
                      final isDone = doc['isDone'];
                      return ListTile(
                        leading: Checkbox(
                          value: isDone,
                          onChanged: (bool? value) {
                            userDailyTasksRef.doc(doc.id).update({
                              'isDone': value ?? false,
                            });
                          },
                        ),
                        title: Text(taskTile),
                        trailing:
                            isDone
                                ? IconButton(
                                  onPressed: () {
                                    //deleteTask(taskTile);
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                            'Do you want to delete the task?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  deleteTask(doc.id);
                                                  Navigator.of(context).pop();
                                                });
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.delete),
                                )
                                : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Add New Task'),
                content: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter task title',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        addTask();
                        Navigator.of(context).pop();
                      });
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}
