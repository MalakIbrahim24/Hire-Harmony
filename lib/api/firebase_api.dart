import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
/*import 'package:flutter_local_notifications/flutter_local_notifications.dart';*/

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}



class FirebaseApi {
  /*
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final AndroidNotificationChannel androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState?.pushNamed(
      NotificationScreen.route,
      arguments: message,
    );
  }

  Future<void> initLocalNotifications() async {
    const DarwinInitializationSettings iOS = DarwinInitializationSettings();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@drawable/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final RemoteMessage message =
              RemoteMessage.fromMap(jsonDecode(response.payload!));
          handleMessage(message);
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? platform =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(androidChannel);
  }

  Future<void> initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  Future<void> initNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
      return; // إذا لم يتم منح الإذن، لا تكمل باقي التهيئة.
    }

    final String? fcmToken = await _firebaseMessaging.getToken();
    print('Token: $fcmToken');

    await initPushNotifications();
    await initLocalNotifications();
  }*/
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// حفظ إحداثيات الموقع الخاصة بالمستخدم في Firestore
  Future<void> saveUserLocation(String userId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      }, SetOptions(merge: true)); // يدمج البيانات إذا كان المستخدم موجوداً
    } catch (e) {
      throw Exception("Failed to save user location: $e");
    }
  }
   Future<bool> isUserLocationSaved(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['location'] != null;
    }
    return false;
  }


}
