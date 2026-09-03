import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';



import '../screens/profile_screen.dart';

import '../screens/private_chat_screen.dart';

import 'photo_gallery_dialog.dart';



class UserAvatar extends StatelessWidget {

  final String userId;

  final String? directUrl;

  final double radius;



  static final Map<String, String> avatarCache = {};



  const UserAvatar({

    super.key,

    required this.userId,

    this.directUrl,

    this.radius = 20,

  });



  @override

  Widget build(BuildContext context) {

    if (directUrl != null && directUrl!.isNotEmpty) {

      avatarCache[userId] = directUrl!;

      return _buildCircle(directUrl!);

    }



    if (avatarCache.containsKey(userId)) {

      return _buildCircle(avatarCache[userId]!);

    }



    return StreamBuilder<DocumentSnapshot>(

      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasData && snapshot.data!.exists) {

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final avatarUrl = data?['avatarUrl'] as String?;

          if (avatarUrl != null && avatarUrl.isNotEmpty) {

            avatarCache[userId] = avatarUrl;

            return _buildCircle(avatarUrl);

          }

        }

        return CircleAvatar(

          radius: radius,

          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),

          child: Icon(Icons.person, size: radius * 1.1, color: Theme.of(context).colorScheme.primary),

        );

      },

    );

  }



  Widget _buildCircle(String url) {

    return CircleAvatar(

      radius: radius,

      backgroundImage: NetworkImage(url),

      backgroundColor: Colors.grey.shade300,

    );

  }

}



// Мини-профиль при нажатии на аватарку в чате

class AvatarDetailDialog extends StatelessWidget {

  final String userId;

  final String nickname;



  const AvatarDetailDialog({

    super.key,

    required this.userId,

    required this.nickname,

  });



  @override

  Widget build(BuildContext context) {

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final isMe = currentUid == userId;



    return StreamBuilder<DocumentSnapshot>(

      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),

      builder: (context, snapshot) {

        Map<String, dynamic> userData = {};

        if (snapshot.hasData && snapshot.data!.exists) {

          userData = snapshot.data!.data() as Map<String, dynamic>;

        }



        final nick = userData['nickname'] ?? nickname;

        final realName = userData['name'] ?? 'Не указано';

        final prefix = userData['prefix'] ?? '';

        final prefixColor = userData['prefixColor'] ?? 0xFFFFD700;

        final isOnline = userData['isOnline'] ?? false;

        final role = userData['role'] ?? 'member';

        final int profileLikes = userData['profileLikesCount'] ?? 0;

        final avatarUrl = userData['avatarUrl'] as String?;



        String roleTitle = 'Боец альянса';

        if (role == 'admin') roleTitle = 'Администратор';

        if (role == 'moderator') roleTitle = 'Модератор';

        if (role == 'creator') roleTitle = 'Основатель [vPv]';



        return Dialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

          child: Padding(

            padding: const EdgeInsets.all(20.0),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                // Аватарка (при тапе открывает альбом фото)

                GestureDetector(

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) => PhotoGalleryDialog(

                          userId: userId,

                          nickname: nick,

                          initialAvatarUrl: avatarUrl,

                        ),

                      ),

                    );

                  },

                  child: Stack(

                    alignment: Alignment.bottomRight,

                    children: [

                      Tooltip(

                        message: 'Нажмите, чтобы открыть альбом',

                        child: UserAvatar(userId: userId, directUrl: avatarUrl, radius: 48),

                      ),

                      Container(

                        width: 18,

                        height: 18,

                        decoration: BoxDecoration(

                          color: isOnline ? Colors.green : Colors.grey,

                          shape: BoxShape.circle,

                          border: Border.all(color: Colors.white, width: 2.5),

                        ),

                      ),

                    ],

                  ),

                ),

                const SizedBox(height: 14),



                if (prefix.toString().isNotEmpty)

                  Container(

                    margin: const EdgeInsets.only(bottom: 6),

                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),

                    decoration: BoxDecoration(

                      color: Color(prefixColor).withOpacity(0.2),

                      borderRadius: BorderRadius.circular(8),

                      border: Border.all(color: Color(prefixColor), width: 1.2),

                    ),

                    child: Text(

                      prefix,

                      style: TextStyle(

                        color: Color(prefixColor),

                        fontWeight: FontWeight.bold,

                        fontSize: 12,

                      ),

                    ),

                  ),



                Text(

                  nick,

                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),

                ),

                const SizedBox(height: 2),

                Text(

                  '$realName • $roleTitle',

                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),

                ),

                const SizedBox(height: 8),



                // Бейдж рейтинга / респекта профиля

                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),

                  decoration: BoxDecoration(

                    color: Colors.redAccent.withOpacity(0.12),

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: Colors.redAccent.withOpacity(0.4)),

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const Icon(Icons.favorite, color: Colors.redAccent, size: 14),

                      const SizedBox(width: 5),

                      Text(

                        'Респект: $profileLikes',

                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent),

                      ),

                    ],

                  ),

                ),



                const SizedBox(height: 18),



                // Кнопка суточного лайка (если это чужой профиль)

                if (!isMe) ...[

                  SizedBox(

                    width: double.infinity,

                    child: ElevatedButton.icon(

                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.redAccent,

                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                      ),

                      onPressed: () => ProfileDailyLikeHelper.giveDailyLike(context, userId),

                      icon: const Icon(Icons.favorite, size: 18),

                      label: const Text('Мне нравится (+1)', style: TextStyle(fontWeight: FontWeight.bold)),

                    ),

                  ),

                  const SizedBox(height: 10),

                ],



                // Кнопки перехода: ЛС и Полный профиль

                Row(

                  children: [

                    if (!isMe) ...[

                      Expanded(

                        child: OutlinedButton.icon(

                          onPressed: () {

                            Navigator.pop(context);

                            Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) => PrivateChatScreen(

                                  peerUserId: userId,

                                  peerNickname: nick,

                                ),

                              ),

                            );

                          },

                          icon: const Icon(Icons.chat_bubble_outline, size: 18),

                          label: const Text('ЛС'),

                        ),

                      ),

                      const SizedBox(width: 8),

                    ],

                    Expanded(

                      child: ElevatedButton.icon(

                        style: ElevatedButton.styleFrom(

                          backgroundColor: Theme.of(context).colorScheme.primary,

                          foregroundColor: Colors.white,

                        ),

                        onPressed: () {

                          Navigator.pop(context);

                          Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (_) => ProfileScreen(userId: userId),

                            ),

                          );

                        },

                        icon: const Icon(Icons.person_pin, size: 18),

                        label: const Text('Полный профиль'),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

        );

      },

    );

  }

}



