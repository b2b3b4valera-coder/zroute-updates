import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'sound_helper.dart';



class LocalNotifications {

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;



  static Future<void> init() async {

    if (_isInitialized) return;



    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(android: androidInit);



    await _plugin.initialize(

      settings: initSettings,

    );



    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();



    _isInitialized = true;

  }



  static Future<void> showNotification({required int id, required String title, required String body}) async {

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(

      'vpv_chat_channel_v2',

      'Уведомления чата [vPv] v2',

      importance: Importance.max,

      priority: Priority.high,

      playSound: false,

    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);



    await _plugin.show(

      id: id,

      title: title,

      body: body,

      notificationDetails: platformDetails,

    );

  }



  static void startListening(String currentNickname) {

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;



    final Timestamp now = Timestamp.now();



    // 1. Слушаем сообщения общего чата

    FirebaseFirestore.instance

        .collection('messages')

        .where('timestamp', isGreaterThan: now)

        .snapshots()

        .listen((snapshot) async {

      for (var change in snapshot.docChanges) {

        if (change.type == DocumentChangeType.added) {

          final msg = change.doc.data();

          if (msg != null && msg['senderId'] != currentUserId && msg['senderId'] != 'system') {

            final prefs = await SharedPreferences.getInstance();

            final muteAll = prefs.getString('muteAll') ?? 'Не отключать';

            final muteGlobal = prefs.getString('muteGlobal') ?? 'Не отключать';



            if (muteAll == 'Не отключать' && muteGlobal == 'Не отключать') {

              SoundHelper.playSound(false);



              final List mentions = msg['mentions'] ?? [];

              final bool isAll = mentions.contains('all') || mentions.contains('@all');

              final bool isMentioned = mentions.contains(currentNickname) || mentions.contains('@$currentNickname');



              if (isAll || isMentioned) {

                final sender = msg['sender'] ?? 'Кто-то';

                final title = isAll ? '📢 Общий сбор альянса!' : 'Упоминание в чате';

                final body = isAll ? '$sender призвал(а) всех в чат!' : '$sender упомянул(а) вас!';

                showNotification(id: change.doc.id.hashCode, title: title, body: body);

              }

            }

          }

        }

      }

    });



    // 2. Слушаем личные сообщения

    bool isInitialMetaLoad = true;

    FirebaseFirestore.instance

        .collection('chats_meta')

        .where('recipientId', isEqualTo: currentUserId)

        .snapshots()

        .listen((snapshot) async {

      if (isInitialMetaLoad) {

        isInitialMetaLoad = false;

        return;

      }



      for (var change in snapshot.docChanges) {

        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {

          final data = change.doc.data() as Map<String, dynamic>;



          if (data['isRead'] == false) {

            final prefs = await SharedPreferences.getInstance();

            final muteAll = prefs.getString('muteAll') ?? 'Не отключать';



            if (muteAll == 'Не отключать') {

              SoundHelper.playSound(true);

              showNotification(id: change.doc.id.hashCode, title: 'Новое сообщение', body: 'Вам прислали личное сообщение');

            }

          }

        }

      }

    });

  }

}



