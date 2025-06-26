class NotificationIds {
  static const dailyTaskReminderId = 0;
  static const screenTime30MinId = 1;
  static const screenTime1HourId = 2;
  static const screenTime2HoursId = 3;
  static const screenTime4HoursId = 4;
  static const screenTime5HoursId = 5;
  static const screenTime6HoursId = 6;
  static const screenTime7HoursId = 7;
  static const screenTime8HoursId = 8;

  static const hourlyUpdateId = 5;
  static int getScreenTimeId(Duration threshold) {
    return thresholds.indexOf(threshold) + 1;
  }

  static const thresholds = [
    Duration(minutes: 1),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 5),
    Duration(hours: 6),
    Duration(hours: 7),
    Duration(hours: 8),
  ];
}
