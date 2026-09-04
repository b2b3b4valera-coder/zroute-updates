import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



import '../utils/helpers.dart';

import '../widgets/user_avatar.dart';

import '../widgets/photo_gallery_dialog.dart';

import 'private_chat_screen.dart';

import 'settings_screen.dart';

import 'auth_screen.dart';



class ProfileScreen extends StatefulWidget {

  final String userId;



  const ProfileScreen({super.key, required this.userId});



  @override

  State<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends State<ProfileScreen> {

  bool _isUploadingAvatar = false;



  Future<void> _pickAndUploadAvatar() async {

    try {

      final albumSnapshot = await FirebaseFirestore.instance

          .collection('users')

          .doc(widget.userId)

          .collection('album')

          .get();



      if (albumSnapshot.docs.length >= 10) {

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(content: Text('Максимум можно загрузить 10 фотографий в альбом!')),

          );

        }

        return;

      }

    } catch (_) {}



    final picker = ImagePicker();

    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (file == null) return;



    setState(() => _isUploadingAvatar = true);



    try {

      final bytes = await file.readAsBytes();

      final ext = file.name.split('.').last;

      final path = 'avatars/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';



      final storage = Supabase.instance.client.storage.from('chat-media');

      await storage.uploadBinary(

        path,

        bytes,

        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),

      );

      final downloadUrl = storage.getPublicUrl(path);



      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);



      // Обновляем текущую аватарку профиля

      await userDocRef.update({

        'avatarUrl': downloadUrl,

      });



      // Также обязательно добавляем новую аватарку в подколлекцию альбома, чтобы она отображалась в галерее

      await userDocRef.collection('album').add({

        'url': downloadUrl,

        'createdAt': FieldValue.serverTimestamp(),

        'likes': [],

        'likesCount': 0,

        'isMainAvatar': false,

      });



      UserAvatar.avatarCache[widget.userId] = downloadUrl;



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Фотография успешно добавлена в альбом и установлена как аватарка!')),

        );

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Ошибка загрузки: $e')),

        );

      }

    } finally {

      if (mounted) setState(() => _isUploadingAvatar = false);

    }

  }



  Future<void> _deleteCurrentAvatar() async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Удаление фотографии'),

        content: const Text('Вы действительно хотите удалить эту аватарку?'),

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



    if (confirm != true) return;



    setState(() => _isUploadingAvatar = true);



    try {

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      final docSnapshot = await userDocRef.get();

      final currentData = docSnapshot.data() as Map<String, dynamic>? ?? {};

      String currentAvatar = currentData['avatarUrl'] ?? '';



      // Находим и удаляем соответствующее фото из подколлекции альбома

      final albumQuery = await userDocRef

          .collection('album')

          .where('url', isEqualTo: currentAvatar)

          .get();



      for (var doc in albumQuery.docs) {

        await doc.reference.delete();

      }



      // Получаем оставшиеся фото в альбоме, чтобы назначить следующее как аватарку

      final remainingAlbum = await userDocRef

          .collection('album')

          .orderBy('createdAt', descending: true)

          .get();



      String newAvatar = '';

      if (remainingAlbum.docs.isNotEmpty) {

        newAvatar = remainingAlbum.docs.first.data()['url'] ?? '';

      }



      await userDocRef.update({

        'avatarUrl': newAvatar,

      });



      if (newAvatar.isNotEmpty) {

        UserAvatar.avatarCache[widget.userId] = newAvatar;

      } else {

        UserAvatar.avatarCache.remove(widget.userId);

      }



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Аватарка удалена!')),

        );

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Ошибка удаления: $e')),

        );

      }

    } finally {

      if (mounted) setState(() => _isUploadingAvatar = false);

    }

  }



  Future<void> _logout(BuildContext context) async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: const Text('Выход из аккаунта'),

        content: const Text('Вы действительно хотите покинуть расположение альянса?'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),

          ElevatedButton(

            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: () => Navigator.pop(ctx, true),

            child: const Text('Выйти', style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );



    if (confirm != true) return;



    try {

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({

          'isOnline': false,

        });

      }

      await FirebaseAuth.instance.signOut();

      if (context.mounted) {

        Navigator.pushAndRemoveUntil(

          context,

          MaterialPageRoute(builder: (_) => const AuthScreen()),

              (route) => false,

        );

      }

    } catch (e) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка выхода: $e')));

      }

    }

  }



  void _showBlacklistDialog(BuildContext context, List<String> blockedIds) {

    showDialog(

      context: context,

      builder: (dialogCtx) => StatefulBuilder(

        builder: (ctx, setDialogState) => AlertDialog(

          title: const Row(

            children: [

              Icon(Icons.block, color: Colors.red),

              SizedBox(width: 8),

              Text('Чёрный список (ЛС)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            ],

          ),

          content: SizedBox(

            width: double.maxFinite,

            height: 320,

            child: blockedIds.isEmpty

                ? const Center(child: Text('Чёрный список пуст'))

                : ListView.builder(

              itemCount: blockedIds.length,

              itemBuilder: (context, index) {

                final blockedUid = blockedIds[index];

                return FutureBuilder<DocumentSnapshot>(

                  future: FirebaseFirestore.instance.collection('users').doc(blockedUid).get(),

                  builder: (context, snapshot) {

                    final nickname = snapshot.data?.exists == true

                        ? ((snapshot.data!.data() as Map<String, dynamic>?)?['nickname'] ?? 'Боец')

                        : 'Загрузка...';



                    return ListTile(

                      leading: const Icon(Icons.person_off, color: Colors.redAccent),

                      title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.w600)),

                      trailing: TextButton(

                        child: const Text('Разблокировать', style: TextStyle(color: Colors.blueAccent)),

                        onPressed: () async {

                          blockedIds.remove(blockedUid);

                          await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({

                            'blockedUsers': blockedIds,

                          });

                          setDialogState(() {});

                          if (context.mounted) {

                            ScaffoldMessenger.of(context).showSnackBar(

                              SnackBar(content: Text('$nickname удалён из чёрного списка')),

                            );

                          }

                        },

                      ),

                    );

                  },

                );

              },

            ),

          ),

          actions: [

            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Закрыть')),

          ],

        ),

      ),

    );

  }



  void _showEditProfileDialog(BuildContext context, Map<String, dynamic> data) {

    final nameCtrl = TextEditingController(text: data['name'] ?? '');

    final nickCtrl = TextEditingController(text: data['nickname'] ?? '');

    final ageCtrl = TextEditingController(text: data['age']?.toString() ?? '');

    String selectedGender = data['gender'] ?? 'Мужской';

    bool isSaving = false;



    showDialog(

      context: context,

      builder: (dialogCtx) => StatefulBuilder(

        builder: (ctx, setDialogState) => AlertDialog(

          title: const Text('Редактировать данные', style: TextStyle(fontWeight: FontWeight.bold)),

          content: SingleChildScrollView(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                TextField(

                  controller: nameCtrl,

                  decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder()),

                ),

                const SizedBox(height: 12),

                TextField(

                  controller: nickCtrl,

                  decoration: const InputDecoration(labelText: 'Позывной (Никнейм)', border: OutlineInputBorder()),

                ),

                const SizedBox(height: 12),

                TextField(

                  controller: ageCtrl,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(labelText: 'Возраст', border: OutlineInputBorder()),

                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(

                  value: selectedGender,

                  decoration: const InputDecoration(labelText: 'Пол', border: OutlineInputBorder()),

                  items: const [

                    DropdownMenuItem(value: 'Мужской', child: Text('Мужской')),

                    DropdownMenuItem(value: 'Женский', child: Text('Женский')),

                  ],

                  onChanged: (val) {

                    if (val != null) setDialogState(() => selectedGender = val);

                  },

                ),

              ],

            ),

          ),

          actions: [

            TextButton(

              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),

              child: const Text('Отмена'),

            ),

            ElevatedButton(

              onPressed: isSaving

                  ? null

                  : () async {

                final newNick = nickCtrl.text.trim();

                final newName = nameCtrl.text.trim();

                final newAge = ageCtrl.text.trim();



                if (newNick.isEmpty || newName.isEmpty) {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(content: Text('Имя и позывной не могут быть пустыми!')),

                  );

                  return;

                }



                setDialogState(() => isSaving = true);



                try {

                  if (newNick != data['nickname']) {

                    final check = await FirebaseFirestore.instance

                        .collection('users')

                        .where('nickname', isEqualTo: newNick)

                        .get();



                    if (check.docs.isNotEmpty) {

                      if (context.mounted) {

                        ScaffoldMessenger.of(context).showSnackBar(

                          const SnackBar(content: Text('Этот позывной уже занят другим бойцом!')),

                        );

                      }

                      setDialogState(() => isSaving = false);

                      return;

                    }

                  }



                  await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({

                    'name': newName,

                    'nickname': newNick,

                    'age': newAge,

                    'gender': selectedGender,

                  });



                  if (dialogCtx.mounted) {

                    Navigator.pop(dialogCtx);

                    ScaffoldMessenger.of(context).showSnackBar(

                      const SnackBar(content: Text('Данные профиля сохранены!')),

                    );

                  }

                } catch (e) {

                  if (context.mounted) {

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));

                  }

                } finally {

                  setDialogState(() => isSaving = false);

                }

              },

              child: isSaving

                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))

                  : const Text('Сохранить'),

            ),

          ],

        ),

      ),

    );

  }



  List<Map<String, dynamic>> _calculateAwards(Map<String, dynamic> data) {

    final role = data['role'] ?? 'member';

    final createdAt = data['createdAt'] as Timestamp?;

    final now = DateTime.now();

    int daysInAlliance = 0;

    if (createdAt != null) {

      daysInAlliance = now.difference(createdAt.toDate()).inDays;

    }



    final List<dynamic> customAwards = data['assignedAwards'] ?? [];



    return [

      {

        'id': 'pack_vow',

        'title': 'Клятва Стаи',

        'desc': 'Полноправный член альянса [vPv]',

        'icon': Icons.security,

        'color': Colors.amber,

        'unlocked': true,

      },

      {

        'id': 'order_guardian',

        'title': 'Страж Порядка',

        'desc': 'Служба модератором или администратором',

        'icon': Icons.shield,

        'color': Colors.blueAccent,

        'unlocked': role == 'admin' || role == 'moderator' || role == 'creator' || customAwards.contains('order_guardian'),

      },

      {

        'id': 'pack_veteran',

        'title': 'Ветеран Волков',

        'desc': 'Более 30 дней в составе альянса',

        'icon': Icons.military_tech,

        'color': Colors.deepOrange,

        'unlocked': daysInAlliance >= 30 || customAwards.contains('pack_veteran'),

      },

      {

        'id': 'voice_pack',

        'title': 'Голос Стаи',

        'desc': 'Активный боец радиоэфира',

        'icon': Icons.record_voice_over,

        'color': Colors.tealAccent,

        'unlocked': true,

      },

      {

        'id': 'gunsmith',

        'title': 'Оружейник',

        'desc': 'Особый персональный статус и префикс',

        'icon': Icons.auto_awesome,

        'color': Colors.purpleAccent,

        'unlocked': (data['prefix'] ?? '').toString().isNotEmpty || customAwards.contains('gunsmith'),

      },

      {

        'id': 'legend_protocol',

        'title': 'Легенда Протокола',

        'desc': 'Высшее командование альянса',

        'icon': Icons.workspace_premium,

        'color': Colors.redAccent,

        'unlocked': role == 'admin' || role == 'creator' || customAwards.contains('legend_protocol'),

      },

      {

        'id': 'hero_alliance',

        'title': 'Герой Альянса',

        'desc': 'Высшая боевая награда за особые заслуги',

        'icon': Icons.star_rate_rounded,

        'color': Colors.amberAccent,

        'unlocked': customAwards.contains('hero_alliance'),

      },

      {

        'id': 'scout_master',

        'title': 'Мастер Разведки',

        'desc': 'Безупречная служба и сбор данных',

        'icon': Icons.radar,

        'color': Colors.cyanAccent,

        'unlocked': customAwards.contains('scout_master'),

      },

    ];

  }



  @override

  Widget build(BuildContext context) {

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final isMe = currentUid == widget.userId;



    return Scaffold(

      appBar: AppBar(

        title: const Text('Профиль бойца'),

        centerTitle: true,

        actions: [

          IconButton(

            icon: const Icon(Icons.settings, size: 26),

            tooltip: 'Настройки приложения',

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (_) => const SettingsScreen()),

              );

            },

          ),

          if (isMe)

            IconButton(

              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 26),

              tooltip: 'Выйти из аккаунта',

              onPressed: () => _logout(context),

            ),

        ],

      ),

      body: StreamBuilder<DocumentSnapshot>(

        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {

            return const Center(child: CircularProgressIndicator());

          }



          if (!snapshot.data!.exists) {

            return const Center(child: Text('Пользователь не найден'));

          }



          final data = snapshot.data!.data() as Map<String, dynamic>;

          final nickname = data['nickname'] ?? 'Боец';

          final name = data['name'] ?? 'Не указано';

          final age = data['age'] ?? 'Не указан';

          final gender = data['gender'] ?? 'Не указан';

          final role = data['role'] ?? 'member';

          final prefix = data['prefix'] ?? '';

          final prefixColor = data['prefixColor'] ?? 0xFFFFD700;

          final isOnline = data['isOnline'] ?? false;

          final createdAt = data['createdAt'] as Timestamp?;

          final avatarUrl = data['avatarUrl'] as String?;

          final List<String> blockedUsers = List<String>.from(data['blockedUsers'] ?? []);

          final int profileLikes = data['profileLikesCount'] ?? 0;



          final awards = _calculateAwards(data);



          String roleName = 'Рядовой боец';

          if (role == 'admin') roleName = 'Администратор альянса';

          if (role == 'moderator') roleName = 'Модератор чата';

          if (role == 'creator') roleName = 'Глава альянса';



          return ListView(

            padding: const EdgeInsets.all(16.0),

            children: [

              Center(

                child: Stack(

                  alignment: Alignment.bottomRight,

                  children: [

                    GestureDetector(

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) => PhotoGalleryDialog(

                              userId: widget.userId,

                              nickname: nickname,

                              initialAvatarUrl: avatarUrl,

                            ),

                          ),

                        );

                      },

                      child: Container(

                        decoration: BoxDecoration(

                          shape: BoxShape.circle,

                          border: Border.all(

                            color: prefix.isNotEmpty ? Color(prefixColor) : Theme.of(context).colorScheme.primary,

                            width: 3.5,

                          ),

                          boxShadow: [

                            BoxShadow(

                              color: (prefix.isNotEmpty ? Color(prefixColor) : Theme.of(context).colorScheme.primary).withOpacity(0.3),

                              blurRadius: 16,

                              spreadRadius: 2,

                            ),

                          ],

                        ),

                        child: Tooltip(

                          message: 'Нажмите, чтобы открыть альбом',

                          child: UserAvatar(userId: widget.userId, directUrl: avatarUrl, radius: 56),

                        ),

                      ),

                    ),

                    if (isMe)

                      Positioned(

                        bottom: 0,

                        right: 0,

                        child: Row(

                          mainAxisSize: MainAxisSize.min,

                          children: [

                            if (avatarUrl != null && avatarUrl.isNotEmpty)

                              Container(

                                margin: const EdgeInsets.only(right: 4),

                                child: CircleAvatar(

                                  radius: 18,

                                  backgroundColor: Colors.red,

                                  child: IconButton(

                                    icon: const Icon(Icons.delete, size: 16, color: Colors.white),

                                    tooltip: 'Удалить аватарку',

                                    onPressed: _isUploadingAvatar ? null : _deleteCurrentAvatar,

                                  ),

                                ),

                              ),

                            CircleAvatar(

                              radius: 18,

                              backgroundColor: Theme.of(context).colorScheme.primary,

                              child: IconButton(

                                icon: _isUploadingAvatar

                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))

                                    : const Icon(Icons.camera_alt, size: 16, color: Colors.white),

                                tooltip: 'Загрузить фото',

                                onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,

                              ),

                            ),

                          ],

                        ),

                      ),

                  ],

                ),

              ),

              const SizedBox(height: 14),



              Center(

                child: Column(

                  children: [

                    if (prefix.toString().isNotEmpty)

                      Container(

                        margin: const EdgeInsets.only(bottom: 6),

                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                        decoration: BoxDecoration(

                          color: Color(prefixColor).withOpacity(0.2),

                          borderRadius: BorderRadius.circular(8),

                          border: Border.all(color: Color(prefixColor), width: 1.5),

                          boxShadow: [

                            BoxShadow(

                              color: Color(prefixColor).withOpacity(0.3),

                              blurRadius: 6,

                            )

                          ],

                        ),

                        child: Text(

                          prefix,

                          style: TextStyle(

                            color: Color(prefixColor),

                            fontWeight: FontWeight.bold,

                            fontSize: 13,

                          ),

                        ),

                      ),

                    Text(

                      nickname,

                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

                    ),

                    const SizedBox(height: 4),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Container(

                          width: 9,

                          height: 9,

                          decoration: BoxDecoration(

                            color: isOnline ? Colors.green : Colors.grey,

                            shape: BoxShape.circle,

                          ),

                        ),

                        const SizedBox(width: 6),

                        Text(

                          isOnline ? 'В сети' : 'Не в сети',

                          style: TextStyle(

                            fontSize: 13,

                            color: isOnline ? Colors.green : Colors.grey,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                        const Text(' • ', style: TextStyle(color: Colors.grey)),

                        Text(

                          roleName,

                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),

                        ),

                      ],

                    ),

                    const SizedBox(height: 8),



                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                      decoration: BoxDecoration(

                        color: Colors.redAccent.withOpacity(0.12),

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          const Icon(Icons.favorite, color: Colors.redAccent, size: 16),

                          const SizedBox(width: 6),

                          Text(

                            'Респект бойцу: $profileLikes',

                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 16),



              if (isMe) ...[

                Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    OutlinedButton.icon(

                      onPressed: () => _showEditProfileDialog(context, data),

                      icon: const Icon(Icons.edit_note, size: 20),

                      label: const Text('Редактировать'),

                    ),

                    const SizedBox(width: 10),

                    OutlinedButton.icon(

                      onPressed: () => _showBlacklistDialog(context, blockedUsers),

                      icon: const Icon(Icons.block, color: Colors.redAccent, size: 18),

                      label: Text('Чёрный список (${blockedUsers.length})', style: const TextStyle(color: Colors.redAccent)),

                    ),

                  ],

                ),

                const SizedBox(height: 16),

              ],



              if (!isMe) ...[

                Row(

                  children: [

                    Expanded(

                      child: ElevatedButton.icon(

                        style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.redAccent,

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 12),

                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                        ),

                        onPressed: () => ProfileDailyLikeHelper.giveDailyLike(context, widget.userId),

                        icon: const Icon(Icons.favorite, size: 20),

                        label: const Text('Мне нравится (+1)', style: TextStyle(fontWeight: FontWeight.bold)),

                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      child: ElevatedButton.icon(

                        style: ElevatedButton.styleFrom(

                          padding: const EdgeInsets.symmetric(vertical: 12),

                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                        ),

                        onPressed: () {

                          Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (_) => PrivateChatScreen(

                                peerUserId: widget.userId,

                                peerNickname: nickname,

                              ),

                            ),

                          );

                        },

                        icon: const Icon(Icons.send_rounded),

                        label: const Text('Написать в ЛС', style: TextStyle(fontWeight: FontWeight.bold)),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 20),

              ],



              Card(

                elevation: 2,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

                child: Padding(

                  padding: const EdgeInsets.all(16.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Row(

                        children: [

                          Icon(Icons.badge, size: 20, color: Colors.orange),

                          SizedBox(width: 8),

                          Text('Личное дело бойца', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                        ],

                      ),

                      const Divider(height: 20),

                      _buildInfoRow(Icons.person_outline, 'Имя', name),

                      _buildInfoRow(Icons.cake_outlined, 'Возраст', age.toString()),

                      _buildInfoRow(Icons.wc_outlined, 'Пол', gender),

                      _buildInfoRow(

                        Icons.calendar_month_outlined,

                        'В альянсе с',

                        createdAt != null ? formatMessageTime(createdAt) : 'Недавно',

                      ),

                      _buildInfoRow(Icons.shield_outlined, 'Альянс', '[vPv] Волчий Протокол'),

                    ],

                  ),

                ),

              ),

              const SizedBox(height: 20),



              Card(

                elevation: 2,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

                child: Padding(

                  padding: const EdgeInsets.all(16.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Row(

                        children: [

                          Icon(Icons.military_tech, size: 22, color: Colors.amber),

                          SizedBox(width: 8),

                          Text('Награды и достижения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                        ],

                      ),

                      const SizedBox(height: 12),

                      GridView.builder(

                        shrinkWrap: true,

                        physics: const NeverScrollableScrollPhysics(),

                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

                          crossAxisCount: 2,

                          crossAxisSpacing: 10,

                          mainAxisSpacing: 10,

                          childAspectRatio: 1.45,

                        ),

                        itemCount: awards.length,

                        itemBuilder: (context, index) {

                          final award = awards[index];

                          final bool unlocked = award['unlocked'] as bool;

                          final Color color = unlocked ? (award['color'] as Color) : Colors.grey;



                          return Container(

                            padding: const EdgeInsets.all(10),

                            decoration: BoxDecoration(

                              color: unlocked ? color.withOpacity(0.1) : Colors.black.withOpacity(0.04),

                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(

                                color: unlocked ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.3),

                                width: 1.2,

                              ),

                            ),

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [

                                Row(

                                  children: [

                                    Icon(award['icon'] as IconData, color: color, size: 22),

                                    const Spacer(),

                                    if (unlocked)

                                      const Icon(Icons.check_circle, color: Colors.green, size: 14)

                                    else

                                      const Icon(Icons.lock_outline, color: Colors.grey, size: 14),

                                  ],

                                ),

                                const SizedBox(height: 6),

                                Text(

                                  award['title'] as String,

                                  style: TextStyle(

                                    fontWeight: FontWeight.bold,

                                    fontSize: 12,

                                    color: unlocked ? null : Colors.grey,

                                  ),

                                  maxLines: 1,

                                  overflow: TextOverflow.ellipsis,

                                ),

                                const SizedBox(height: 2),

                                Text(

                                  award['desc'] as String,

                                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),

                                  maxLines: 2,

                                  overflow: TextOverflow.ellipsis,

                                ),

                              ],

                            ),

                          );

                        },

                      ),

                    ],

                  ),

                ),

              ),

            ],

          );

        },

      ),

    );

  }



  Widget _buildInfoRow(IconData icon, String label, String value) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 6.0),

      child: Row(

        children: [

          Icon(icon, size: 18, color: Colors.grey),

          const SizedBox(width: 10),

          Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(width: 8),

          Expanded(

            child: Text(

              value,

              textAlign: TextAlign.right,

              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),

              overflow: TextOverflow.ellipsis,

            ),

          ),

        ],

      ),

    );

  }

}



