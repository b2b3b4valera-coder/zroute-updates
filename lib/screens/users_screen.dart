import 'package:flutter/material.dart';



import 'package:cloud_firestore/cloud_firestore.dart';



import 'package:firebase_auth/firebase_auth.dart';







import '../widgets/user_avatar.dart';



import 'private_chat_screen.dart';







// ==========================================



// --- СПИСОК ПОЛЬЗОВАТЕЛЕЙ (КОНТАКТЫ) ---



// ==========================================



class UsersScreen extends StatelessWidget {



  const UsersScreen({super.key});







  @override



  Widget build(BuildContext context) {



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    final theme = Theme.of(context);







    return Scaffold(



      appBar: AppBar(title: const Text('Контакты (ЛС)'), centerTitle: true),



      body: StreamBuilder<QuerySnapshot>(



        stream: FirebaseFirestore.instance.collection('users').snapshots(),



        builder: (context, snapshot) {



          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());



          final users = snapshot.data!.docs;







          return StreamBuilder<QuerySnapshot>(



            stream: FirebaseFirestore.instance



                .collection('chats_meta')



                .where('recipientId', isEqualTo: currentUserId)



                .snapshots(),



            builder: (context, metaListSnapshot) {



              final Map<String, dynamic> lastActivityMap = {};



              final Map<String, dynamic> isReadMap = {};







              if (metaListSnapshot.hasData) {



                for (var doc in metaListSnapshot.data!.docs) {



                  final data = doc.data() as Map<String, dynamic>;



                  final docId = doc.id;



                  // docId имеет формат chatRoomId_recipientId



                  for (var uDoc in users) {



                    final peerId = uDoc.id;



                    if (currentUserId == null) continue;



                    final chatRoomId = currentUserId.compareTo(peerId) > 0



                        ? '${currentUserId}_$peerId'



                        : '${peerId}_$currentUserId';







                    if (docId.startsWith(chatRoomId)) {



                      lastActivityMap[peerId] = data['lastActivity'] ?? data['timestamp'];



                      isReadMap[peerId] = data['isRead'] ?? true;



                    }



                  }



                }



              }







              final sortedUsers = List.from(users);



              sortedUsers.sort((a, b) {



                final idA = a.id;



                final idB = b.id;



                if (idA == currentUserId) return 1;



                if (idB == currentUserId) return -1;







                final timeA = lastActivityMap[idA];



                final timeB = lastActivityMap[idB];







                if (timeA == null && timeB == null) return 0;



                if (timeA == null) return 1;



                if (timeB == null) return -1;







                if (timeA is Timestamp && timeB is Timestamp) {



                  return timeB.compareTo(timeA);



                }



                return 0;



              });







              return ListView.builder(



                itemCount: sortedUsers.length,



                itemBuilder: (context, index) {



                  final userDoc = sortedUsers[index];



                  final userId = userDoc.id;



                  final userData = userDoc.data() as Map<String, dynamic>;



                  final nickname = userData['nickname'] ?? 'Без имени';



                  final prefix = userData['prefix'] ?? '';



                  final avatarUrl = userData['avatarUrl'] as String?;



                  final bool isOnline = userData['isOnline'] ?? false;







                  if (userId == currentUserId) return const SizedBox.shrink();







                  final chatRoomId = currentUserId!.compareTo(userId) > 0



                      ? '${currentUserId}_$userId'



                      : '${userId}_$currentUserId';







                  return StreamBuilder<DocumentSnapshot>(



                    stream: FirebaseFirestore.instance



                        .collection('chats_meta')



                        .doc('${chatRoomId}_$currentUserId')



                        .snapshots(),



                    builder: (context, metaSnapshot) {



                      bool isRead = true;



                      if (metaSnapshot.hasData && metaSnapshot.data!.exists) {



                        final metaData = metaSnapshot.data!.data() as Map<String, dynamic>;



                        isRead = metaData['isRead'] ?? true;



                      }







                      return ListTile(



                        leading: Stack(



                          children: [



                            UserAvatar(



                              userId: userId,



                              directUrl: avatarUrl,



                              radius: 22,



                            ),



                            Positioned(



                              bottom: 0,



                              right: 0,



                              child: Container(



                                width: 12,



                                height: 12,



                                decoration: BoxDecoration(



                                  shape: BoxShape.circle,



                                  color: isOnline ? Colors.green : Colors.grey,



                                  border: Border.all(color: Colors.white, width: 2),



                                ),



                              ),



                            ),



                          ],



                        ),



                        title: Text('$prefix $nickname', style: const TextStyle(fontWeight: FontWeight.bold)),



                        subtitle: Text(isOnline ? 'В сети' : 'Не в сети', style: TextStyle(color: isOnline ? Colors.green : Colors.grey)),



                        trailing: Row(



                          mainAxisSize: MainAxisSize.min,



                          children: [



                            if (!isRead)



                              Container(



                                margin: const EdgeInsets.only(right: 8),



                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),



                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),



                                child: const Text('Новое', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),



                              ),



                            Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),



                          ],



                        ),



                        onTap: () {



                          Navigator.push(



                            context,



                            MaterialPageRoute(



                              builder: (context) => PrivateChatScreen(



                                peerUserId: userId,



                                peerNickname: '$prefix $nickname',



                              ),



                            ),



                          );



                        },



                      );



                    },



                  );



                },



              );



            },



          );



        },



      ),



    );



  }



}



