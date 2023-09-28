import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(const MainApp());
}

class Task {
  final String name;
  final int interval;

  Task(this.name, this.interval);
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Task> tasks = [];
  final _prefsKey = 'tasks'; // Key for storing tasks in SharedPreferences
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initNotifications(); // Initialize notifications
    _loadTasks(); // Load tasks when the app starts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Reminder App'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskCreationScreen(
                    onSave: (task) {
                      setState(() {
                        tasks.add(task);
                        _saveTasks(); // Save tasks when a new task is added
                      });
                      scheduleNotification(
                          task); // Schedule notifications for the new task
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Tasks:',
              style: TextStyle(fontSize: 20),
            ),
            Expanded(
              child: TaskList(
                  tasks: tasks,
                  onDelete: (task) {
                    _showDeleteConfirmationDialog(context, task);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Do you want to delete the task: ${task.name}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tasks.remove(task);
                  _saveTasks(); // Save tasks after deletion
                });
                // You may want to cancel the scheduled notifications for this task here
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Initialize the notification plugin
  Future<void> initNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Schedule notifications for a task
  Future<void> scheduleNotification(Task task) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',

      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Play the default notification sound
      sound: RawResourceAndroidNotificationSound(
          'notification_sound'), // Custom sound file
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    int notificationId = tasks.indexOf(task);
    String notificationMessage = 'Time to do ${task.name}!';
    int intervalMinutes = task.interval;

    for (int i = 1; i <= 10; i++) {
      // Calculate the time for the next notification
      DateTime now = DateTime.now();
      DateTime nextNotificationTime =
          now.add(Duration(minutes: intervalMinutes * i));
      String timeZoneName = 'Asia/Kolkata';
      tz.TZDateTime tzDateTime = tz.TZDateTime.from(
          nextNotificationTime, tz.getLocation(timeZoneName));
      // Schedule the next notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId + i,
        'Task Reminder',
        notificationMessage,
        tzDateTime,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: task.name,
      );
    }
    // You can refer to the previous code snippet for scheduling notifications
    // Include custom notification sounds, stop button, and full-screen alarms
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getStringList(_prefsKey) ?? [];

    setState(() {
      tasks = taskList.map((taskString) {
        final taskData = taskString.split(';');
        return Task(taskData[0], int.parse(taskData[1]));
      }).toList();
    });
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList =
        tasks.map((task) => '${task.name};${task.interval}').toList();
    prefs.setStringList(_prefsKey, taskList);
  }
}

class TaskCreationScreen extends StatefulWidget {
  final Function(Task) onSave;

  const TaskCreationScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  _TaskCreationScreenState createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Task'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            TextField(
              controller: _intervalController,
              decoration: InputDecoration(labelText: 'Interval (minutes)'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text;
                final interval = int.tryParse(_intervalController.text);
                if (name.isNotEmpty && interval != null) {
                  final task = Task(name, interval);
                  widget.onSave(task);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onDelete;

  TaskList({required this.tasks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task.name),
          subtitle: Text('Interval: ${task.interval} minutes'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              onDelete(task);
            },
          ),
        );
      },
    );
  }
}
