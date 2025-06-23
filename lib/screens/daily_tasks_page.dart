import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:productivity_app/services/task_manger.dart';

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
  final TextEditingController _controller = TextEditingController();
  final _taskManager = TaskManager();
  late final Stream<QuerySnapshot> dailyTasksStream;

  @override
  void initState() {
    super.initState();
    dailyTasksStream = _taskManager.userDailyTasksRef.snapshots();
    _taskManager.resetDailyTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                            _taskManager.updateDailyTask(
                              doc.id,
                              value ?? false,
                            );
                          },
                        ),
                        title: Text(taskTile),
                        trailing: IconButton(
                          onPressed: () {
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
                                          _taskManager.deleteDailyTask(doc.id);
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
                        ),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                        _taskManager.addDailyTask(_controller.text);
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
