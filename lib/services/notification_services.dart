// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tzdata;
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     tzdata.initializeTimeZones();

//     const AndroidInitializationSettings androidInitSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     await _notificationsPlugin.initialize(
//       const InitializationSettings(android: androidInitSettings),
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         print("🔔 Notification Clicked: ${response.payload}");
//       },
//     );

//     await _configureTimeZone();
//   }

//   static Future<void> _configureTimeZone() async {
//     final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
//     tz.setLocalLocation(tz.getLocation(timeZoneName));
//   }

//   static Future<void> scheduleTaskReminder(
//     int id,
//     String title,
//     String body,
//     DateTime scheduledTime,
//   ) async {
//     if (scheduledTime.isBefore(DateTime.now())) {
//       print("❌ Cannot schedule past notifications.");
//       return;
//     }

//     await _notificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'task_reminder_channel',
//           'Task Reminders',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );

//     print("✅ Notification Scheduled for: $scheduledTime");
//   }
// }
