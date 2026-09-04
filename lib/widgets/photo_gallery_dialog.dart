import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



// Утилита суточной оценки профиля (1 раз в сутки)

class ProfileDailyLikeHelper {

  static Future<void> giveDailyLike(BuildContext context, String targetUserId) async {

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;



    if (currentUserId == targetUserId) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Нельзя оценивать собственный профиль!')),

      );

      return;

    }



    final now = DateTime.now();

    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final dailyVoteDocRef = FirebaseFirestore.instance

        .collection('users')

        .doc(targetUserId)

        .collection('daily_likes')

        .doc(currentUserId);



    try {

      final snapshot = await dailyVoteDocRef.get();

      if (snapshot.exists && snapshot.data()?['date'] == todayKey) {

        if (context.mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(

              backgroundColor: Colors.orange,

              content: Text('Вы сегодня уже оценили этот профиль. Приходите завтра!'),

            ),

          );

        }

        return;

      }



      await dailyVoteDocRef.set({

        'date': todayKey,

        'timestamp': FieldValue.serverTimestamp(),

        'likerId': currentUserId,

      });



      await FirebaseFirestore.instance.collection('users').doc(targetUserId).set({

        'profileLikesCount': FieldValue.increment(1),

      }, SetOptions(merge: true));



      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            backgroundColor: Colors.green,

            content: Text('Вы успешно выразили респект бойцу! (+1 к рейтингу)'),

          ),

        );

      }

    } catch (e) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Ошибка оценки: $e')),

        );

      }

    }

  }

}



// Полноэкранный альбом с лайками и комментариями к каждому фото

class PhotoGalleryDialog extends StatefulWidget {

  final String userId;

  final String nickname;

  final String? initialAvatarUrl;



  const PhotoGalleryDialog({

    super.key,

    required this.userId,

    required this.nickname,

    this.initialAvatarUrl,

  });



  @override

  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();

}



class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {

  final PageController _pageController = PageController();

  int _currentIndex = 0;

  bool _isUploading = false;



  StreamSubscription<QuerySnapshot>? _albumSubscription;

  List<Map<String, dynamic>> _photos = [];

  bool _isLoading = true;



  @override

  void initState() {

    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initAlbumStream();

  }



  @override

  void dispose() {

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _albumSubscription?.cancel();

    _pageController.dispose();

    super.dispose();

  }



  void _initAlbumStream() {

    _albumSubscription = FirebaseFirestore.instance

        .collection('users')

        .doc(widget.userId)

        .collection('album')

        .orderBy('createdAt', descending: true)

        .snapshots()

        .listen((snapshot) {

      if (!mounted) return;



      List<Map<String, dynamic>> loadedPhotos = [];

      if (snapshot.docs.isNotEmpty) {

        loadedPhotos = snapshot.docs.map((doc) {

          final data = doc.data();

          data['docId'] = doc.id;

          data['ref'] = doc.reference;

          return data;

        }).toList();

      }



      setState(() {

        _photos = loadedPhotos;

        _isLoading = false;

        if (_currentIndex >= _photos.length && _photos.isNotEmpty) {

          _currentIndex = _photos.length - 1;

        }

      });

    });

  }



  Future<void> _uploadNewPhoto() async {

    if (_photos.length >= 10) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('В альбоме может быть максимум 10 фотографий!')),

        );

      }

      return;

    }



    final picker = ImagePicker();

    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (file == null) return;



    setState(() => _isUploading = true);



    try {

      final bytes = await file.readAsBytes();

      final ext = file.name.split('.').last;

      final path = 'album/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';



      final storage = Supabase.instance.client.storage.from('chat-media');

      await storage.uploadBinary(

        path,

        bytes,

        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),

      );

      final downloadUrl = storage.getPublicUrl(path);



      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);



      // Новое фото сразу становится аватаркой

      await userDocRef.update({

        'avatarUrl': downloadUrl,

      });



      // Добавляем в альбом (оно первое в списке благодаря descending: true)

      await userDocRef.collection('album').add({

        'url': downloadUrl,

        'createdAt': FieldValue.serverTimestamp(),

        'likes': [],

        'likesCount': 0,

      });



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Фото загружено и установлено как аватарка!')),

        );

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Ошибка загрузки фото: $e')),

        );

      }

    } finally {

      if (mounted) setState(() => _isUploading = false);

    }

  }



  Future<void> _deletePhoto(String photoDocId) async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Удаление фото'),

        content: const Text('Удалить эту фотографию из вашего альбома?'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),

          ElevatedButton(

            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: () => Navigator.pop(ctx, true),

            child: const Text('Удалить', style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );



    if (confirm == true) {

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      await userDocRef.collection('album').doc(photoDocId).delete();



      // Обновляем аватарку на следующее доступное фото в альбоме

      final remaining = await userDocRef.collection('album').orderBy('createdAt', descending: true).get();

      if (remaining.docs.isNotEmpty) {

        final nextAvatarUrl = remaining.docs.first.data()['url'] ?? '';

        await userDocRef.update({'avatarUrl': nextAvatarUrl});

      } else {

        await userDocRef.update({'avatarUrl': ''});

      }



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Фотография удалена')),

        );

      }

    }

  }



  Future<void> _togglePhotoLike(DocumentReference photoRef, List<String> likes) async {

    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (myUid == null) return;



    if (likes.contains(myUid)) {

      await photoRef.update({

        'likes': FieldValue.arrayRemove([myUid]),

        'likesCount': FieldValue.increment(-1),

      });

    } else {

      await photoRef.update({

        'likes': FieldValue.arrayUnion([myUid]),

        'likesCount': FieldValue.increment(1),

      });

    }

  }



  void _openCommentsSheet(String photoDocId) {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (_) => PhotoCommentsSheet(

        userId: widget.userId,

        photoDocId: photoDocId,

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final isMe = currentUserId == widget.userId;



    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        backgroundColor: Colors.black,

        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(

          'Альбом ${widget.nickname}',

          style: const TextStyle(color: Colors.white, fontSize: 16),

        ),

        actions: [

          if (isMe)

            IconButton(

              icon: _isUploading

                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))

                  : const Icon(Icons.add_a_photo, color: Colors.white),

              tooltip: 'Добавить фото (макс. 10)',

              onPressed: _isUploading ? null : _uploadNewPhoto,

            ),

        ],

      ),

      body: _isLoading

          ? const Center(child: CircularProgressIndicator(color: Colors.white))

          : _photos.isEmpty

          ? Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(Icons.photo_library_outlined, size: 64, color: Colors.white38),

            const SizedBox(height: 12),

            const Text('В альбоме пока нет фотографий', style: TextStyle(color: Colors.white70)),

            if (isMe) ...[

              const SizedBox(height: 16),

              ElevatedButton.icon(

                onPressed: _uploadNewPhoto,

                icon: const Icon(Icons.add_photo_alternate),

                label: const Text('Загрузить первое фото'),

              ),

            ],

          ],

        ),

      )

          : Stack(

        children: [

          PageView.builder(

            controller: _pageController,

            itemCount: _photos.length,

            onPageChanged: (index) => setState(() => _currentIndex = index),

            itemBuilder: (context, index) {

              final photo = _photos[index];

              final url = photo['url'] as String;



              return InteractiveViewer(

                minScale: 0.8,

                maxScale: 3.5,

                child: Center(

                  child: Image.network(

                    url,

                    fit: BoxFit.contain,

                    loadingBuilder: (_, child, progress) {

                      if (progress == null) return child;

                      return const Center(child: CircularProgressIndicator(color: Colors.white70));

                    },

                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.white38),

                  ),

                ),

              );

            },

          ),



          Positioned(

            bottom: 24,

            left: 16,

            right: 16,

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(

                color: Colors.black.withOpacity(0.75),

                borderRadius: BorderRadius.circular(30),

                border: Border.all(color: Colors.white24),

              ),

              child: Builder(

                builder: (context) {

                  final safeIndex = _currentIndex.clamp(0, _photos.length - 1);

                  final currentPhoto = _photos[safeIndex];

                  final List<String> likes = List<String>.from(currentPhoto['likes'] ?? []);

                  final int likesCount = currentPhoto['likesCount'] ?? likes.length;

                  final bool isLikedByMe = currentUserId != null && likes.contains(currentUserId);

                  final String docId = currentPhoto['docId'] ?? '';

                  final DocumentReference? ref = currentPhoto['ref'];



                  return Row(

                    children: [

                      Text(

                        '${safeIndex + 1}/${_photos.length}',

                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),

                      ),

                      const Spacer(),



                      IconButton(

                        icon: Icon(

                          isLikedByMe ? Icons.favorite : Icons.favorite_border,

                          color: isLikedByMe ? Colors.redAccent : Colors.white,

                          size: 26,

                        ),

                        onPressed: () {

                          if (ref != null) _togglePhotoLike(ref, likes);

                        },

                      ),

                      Text(

                        '$likesCount',

                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),

                      ),

                      const SizedBox(width: 14),



                      IconButton(

                        icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 24),

                        onPressed: () => _openCommentsSheet(docId),

                      ),



                      if (isMe) ...[

                        const SizedBox(width: 6),

                        IconButton(

                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),

                          onPressed: () => _deletePhoto(docId),

                        ),

                      ],

                    ],

                  );

                },

              ),

            ),

          ),

        ],

      ),

    );

  }

}



// Выдвижная шторка комментариев под конкретным фото

class PhotoCommentsSheet extends StatefulWidget {

  final String userId;

  final String photoDocId;



  const PhotoCommentsSheet({

    super.key,

    required this.userId,

    required this.photoDocId,

  });



  @override

  State<PhotoCommentsSheet> createState() => _PhotoCommentsSheetState();

}



class _PhotoCommentsSheetState extends State<PhotoCommentsSheet> {

  final TextEditingController _commentController = TextEditingController();

  bool _isSending = false;



  Future<void> _sendComment() async {

    final text = _commentController.text.trim();

    if (text.isEmpty) return;



    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;



    setState(() => _isSending = true);



    try {

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final nickname = userDoc.data()?['nickname'] ?? 'Боец';

      final avatarUrl = userDoc.data()?['avatarUrl'] ?? '';



      await FirebaseFirestore.instance

          .collection('users')

          .doc(widget.userId)

          .collection('album')

          .doc(widget.photoDocId)

          .collection('comments')

          .add({

        'userId': user.uid,

        'nickname': nickname,

        'avatarUrl': avatarUrl,

        'text': text,

        'timestamp': FieldValue.serverTimestamp(),

      });



      _commentController.clear();

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));

      }

    } finally {

      if (mounted) setState(() => _isSending = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: EdgeInsets.only(

        bottom: MediaQuery.of(context).viewInsets.bottom,

      ),

      child: Container(

        height: 480,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        child: Column(

          children: [

            Container(

              width: 40,

              height: 4,

              margin: const EdgeInsets.only(bottom: 12),

              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),

            ),

            const Text('Комментарии к фото', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            const Divider(),



            Expanded(

              child: StreamBuilder<QuerySnapshot>(

                stream: FirebaseFirestore.instance

                    .collection('users')

                    .doc(widget.userId)

                    .collection('album')

                    .doc(widget.photoDocId)

                    .collection('comments')

                    .orderBy('timestamp', descending: false)

                    .snapshots(),

                builder: (context, snapshot) {

                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final comments = snapshot.data!.docs;



                  if (comments.isEmpty) {

                    return const Center(child: Text('Комментариев пока нет. Будьте первым!'));

                  }



                  return ListView.builder(

                    itemCount: comments.length,

                    itemBuilder: (context, index) {

                      final c = comments[index].data() as Map<String, dynamic>;

                      return ListTile(

                        dense: true,

                        leading: CircleAvatar(

                          radius: 16,

                          backgroundImage: (c['avatarUrl'] != null && c['avatarUrl'].toString().isNotEmpty)

                              ? NetworkImage(c['avatarUrl'])

                              : null,

                          child: (c['avatarUrl'] == null || c['avatarUrl'].toString().isEmpty)

                              ? const Icon(Icons.person, size: 18)

                              : null,

                        ),

                        title: Text(c['nickname'] ?? 'Боец', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),

                        subtitle: Text(c['text'] ?? '', style: const TextStyle(fontSize: 14)),

                      );

                    },

                  );

                },

              ),

            ),



            Row(

              children: [

                Expanded(

                  child: TextField(

                    controller: _commentController,

                    decoration: const InputDecoration(

                      hintText: 'Оставить комментарий...',

                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),

                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                    ),

                  ),

                ),

                const SizedBox(width: 8),

                IconButton(

                  icon: _isSending

                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))

                      : const Icon(Icons.send, color: Colors.blueAccent),

                  onPressed: _isSending ? null : _sendComment,

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}



