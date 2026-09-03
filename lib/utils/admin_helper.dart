import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';



class AdminHelper {

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // Получение метаданных текущего пользователя

  static Future<Map<String, dynamic>> getCurrentUserMeta() async {

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return {'role': 'member', 'prefix': '', 'prefixColor': 0xFF9E9E9E, 'nickname': 'Боец'};



    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return {'role': 'member', 'prefix': '', 'prefixColor': 0xFF9E9E9E, 'nickname': 'Боец'};



    final data = doc.data()!;

    return {

      'role': data['role'] ?? 'member',

      'prefix': data['prefix'] ?? '',

      'prefixColor': data['prefixColor'] ?? 0xFF9E9E9E,

      'nickname': data['nickname'] ?? 'Боец',

      'isBanned': data['isBanned'] ?? false,

      'bannedUntil': data['bannedUntil'],

      'banReason': data['banReason'] ?? '',

      'isMuted': data['isMuted'] ?? false,

      'mutedUntil': data['mutedUntil'],

    };

  }



  static bool hasAdminRights(String role) {

    return role == 'admin' || role == 'creator';

  }



  static bool hasModerRights(String role) {

    return role == 'moderator' || role == 'admin' || role == 'creator';

  }



  static Future<void> setRole(String targetUid, String newRole) async {

    await _firestore.collection('users').doc(targetUid).update({'role': newRole});

  }



  static Future<void> setPrefix({

    required String targetUid,

    required String prefix,

    required int colorValue,

  }) async {

    await _firestore.collection('users').doc(targetUid).update({

      'prefix': prefix.trim(),

      'prefixColor': colorValue,

    });

  }



  // Блокировка (Бан) — одно сообщение, автоисчезающее через 1 минуту

  static Future<void> banUser({

    required String targetUid,

    required String targetNick,

    required String durationText,

    required Duration duration,

    required String reason,

  }) async {

    final now = DateTime.now();

    final bannedUntil = duration.inDays > 36500 ? null : now.add(duration);

    final cleanReason = reason.trim().isEmpty ? 'Нарушение правил' : reason.trim();



    await _firestore.collection('users').doc(targetUid).update({

      'isBanned': true,

      'bannedUntil': bannedUntil != null ? Timestamp.fromDate(bannedUntil) : null,

      'banReason': cleanReason,

    });



    await _firestore.collection('messages').add({

      'type': 'system',

      'subType': 'punishment',

      'text': '$targetNick забанен на $durationText по причине: $cleanReason. Ну, получается, сам виноват!',

      'sender': 'Система',

      'senderId': 'system',

      'timestamp': FieldValue.serverTimestamp(),

      'reactions': {},

    });

  }



  static Future<void> unbanUser(String targetUid) async {

    await _firestore.collection('users').doc(targetUid).update({

      'isBanned': false,

      'bannedUntil': null,

      'banReason': null,

    });

  }



  // Заглушка (Мут) — официальное объявление, исчезающее через 1 минуту

  static Future<void> muteUser({

    required String targetUid,

    required String targetNick,

    required String durationText,

    required Duration duration,

    required String actorNick,

  }) async {

    final now = DateTime.now();

    final mutedUntil = now.add(duration);



    await _firestore.collection('users').doc(targetUid).update({

      'isMuted': true,

      'mutedUntil': Timestamp.fromDate(mutedUntil),

    });



    await _firestore.collection('messages').add({

      'type': 'system',

      'subType': 'punishment',

      'text': '$actorNick воткнул кляп $targetNick на $durationText. Не пытайся его выплюнуть!',

      'sender': 'Система',

      'senderId': 'system',

      'timestamp': FieldValue.serverTimestamp(),

      'reactions': {},

    });

  }



  static Future<void> unmuteUser(String targetUid) async {

    await _firestore.collection('users').doc(targetUid).update({

      'isMuted': false,

      'mutedUntil': null,

    });

  }



  // Закрепление сообщений

  static Future<void> pinMessage({

    required String messageId,

    required String text,

    required String sender,

    required String type,

    required String pinnedBy,

  }) async {

    await _firestore.collection('chats_meta').doc('global_pin').set({

      'messageId': messageId,

      'text': text,

      'sender': sender,

      'type': type,

      'pinnedBy': pinnedBy,

      'pinnedAt': FieldValue.serverTimestamp(),

    });

  }



  static Future<void> unpinMessage() async {

    await _firestore.collection('chats_meta').doc('global_pin').delete();

  }

}



