import 'package:flutter/material.dart';



import 'package:cloud_firestore/cloud_firestore.dart';



import '../utils/admin_helper.dart';



import '../widgets/user_avatar.dart';







class AdminPanelScreen extends StatefulWidget {



  const AdminPanelScreen({super.key});







  @override



  State<AdminPanelScreen> createState() => _AdminPanelScreenState();



}







class _AdminPanelScreenState extends State<AdminPanelScreen> {



  String _searchQuery = '';



  Map<String, dynamic> _myMeta = {'role': 'member', 'prefix': '', 'nickname': 'Админ'};



  bool _isLoading = true;



  bool _isClearingChat = false;







  final List<Map<String, dynamic>> _assignableAwards = [



    {



      'id': 'hero_alliance',



      'title': 'Герой Альянса',



      'desc': 'Высшая боевая награда за исключительные заслуги',



      'icon': Icons.star_rate_rounded,



      'color': Colors.amberAccent,



    },



    {



      'id': 'scout_master',



      'title': 'Мастер Разведки',



      'desc': 'Безупречная служба и сбор разведданных',



      'icon': Icons.radar,



      'color': Colors.cyanAccent,



    },



    {



      'id': 'pack_veteran',



      'title': 'Ветеран Волков',



      'desc': 'Почетный боевой стаж и верность стае',



      'icon': Icons.military_tech,



      'color': Colors.deepOrange,



    },



    {



      'id': 'order_guardian',



      'title': 'Страж Порядка',



      'desc': 'Особый статус хранителя дисциплины чата',



      'icon': Icons.shield,



      'color': Colors.blueAccent,



    },



    {



      'id': 'gunsmith',



      'title': 'Оружейник',



      'desc': 'Мастер боевого снаряжения и экипировки',



      'icon': Icons.auto_awesome,



      'color': Colors.purpleAccent,



    },



    {



      'id': 'legend_protocol',



      'title': 'Легенда Протокола',



      'desc': 'Высшее признание верховного командования',



      'icon': Icons.workspace_premium,



      'color': Colors.redAccent,



    },



  ];







  @override



  void initState() {



    super.initState();



    _loadMyMeta();



  }







  Future<void> _loadMyMeta() async {



    final meta = await AdminHelper.getCurrentUserMeta();



    setState(() {



      _myMeta = meta;



      _isLoading = false;



    });



  }







  // Функция очистки общего чата с сохранением закрепленных сообщений



  Future<void> _clearGlobalChat() async {



    final confirm = await showDialog<bool>(



      context: context,



      builder: (ctx) => AlertDialog(



        title: const Text('Очистка общего чата'),



        content: const Text('Вы уверены, что хотите удалить все сообщения в общем чате, кроме закрепленных? Это действие необратимо!'),



        actions: [



          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),



          ElevatedButton(



            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),



            onPressed: () => Navigator.pop(ctx, true),



            child: const Text('Очистить', style: TextStyle(color: Colors.white)),



          ),



        ],



      ),



    );







    if (confirm != true) return;







    setState(() => _isClearingChat = true);







    try {



      // Получаем id закрепленного сообщения из chats_meta -> global_pin, если оно есть



      String? pinnedMessageId;



      final pinDoc = await FirebaseFirestore.instance.collection('chats_meta').doc('global_pin').get();



      if (pinDoc.exists) {



        pinnedMessageId = pinDoc.data()?['messageId'];



      }







      final messagesQuery = await FirebaseFirestore.instance.collection('messages').get();







      final batch = FirebaseFirestore.instance.batch();



      int deletedCount = 0;







      for (var doc in messagesQuery.docs) {



        if (doc.id != pinnedMessageId) {



          batch.delete(doc.reference);



          deletedCount++;



        }



      }







      if (deletedCount > 0) {



        await batch.commit();



      }







      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          SnackBar(content: Text('Общий чат очищен. Удалено сообщений: $deletedCount')),



        );



      }



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          SnackBar(content: Text('Ошибка очистки чата: $e')),



        );



      }



    } finally {



      if (mounted) {



        setState(() => _isClearingChat = false);



      }



    }



  }







  void _showAwardsDialog(String uid, List<dynamic> currentAwards, String nick) {



    List<String> selected = List<String>.from(currentAwards);



    bool isSaving = false;







    showDialog(



      context: context,



      builder: (ctx) => StatefulBuilder(



        builder: (context, setDialogState) => AlertDialog(



          title: Row(



            children: [



              const Icon(Icons.military_tech, color: Colors.amber),



              const SizedBox(width: 8),



              Expanded(



                child: Text(



                  'Награды: $nick',



                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),



                  overflow: TextOverflow.ellipsis,



                ),



              ),



            ],



          ),



          content: SizedBox(



            width: double.maxFinite,



            child: ListView.separated(



              shrinkWrap: true,



              itemCount: _assignableAwards.length,



              separatorBuilder: (_, __) => const Divider(height: 1),



              itemBuilder: (context, i) {



                final award = _assignableAwards[i];



                final String id = award['id'];



                final bool isChecked = selected.contains(id);



                final Color color = award['color'];







                return CheckboxListTile(



                  value: isChecked,



                  activeColor: color,



                  secondary: Container(



                    padding: const EdgeInsets.all(6),



                    decoration: BoxDecoration(



                      color: color.withOpacity(0.15),



                      shape: BoxShape.circle,



                    ),



                    child: Icon(award['icon'], color: color, size: 24),



                  ),



                  title: Text(award['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),



                  subtitle: Text(award['desc'], style: const TextStyle(fontSize: 11)),



                  onChanged: (val) {



                    setDialogState(() {



                      if (val == true) {



                        selected.add(id);



                      } else {



                        selected.remove(id);



                      }



                    });



                  },



                );



              },



            ),



          ),



          actions: [



            TextButton(



              onPressed: isSaving ? null : () => Navigator.pop(ctx),



              child: const Text('Отмена'),



            ),



            ElevatedButton(



              onPressed: isSaving



                  ? null



                  : () async {



                setDialogState(() => isSaving = true);



                try {



                  await FirebaseFirestore.instance.collection('users').doc(uid).update({



                    'assignedAwards': selected,



                  });



                  if (ctx.mounted) Navigator.pop(ctx);



                  if (mounted) {



                    ScaffoldMessenger.of(context).showSnackBar(



                      SnackBar(content: Text('Награды бойца $nick успешно обновлены!')),



                    );



                  }



                } catch (e) {



                  if (mounted) {



                    ScaffoldMessenger.of(context).showSnackBar(



                      SnackBar(content: Text('Ошибка обновления наград: $e')),



                    );



                  }



                } finally {



                  setDialogState(() => isSaving = false);



                }



              },



              child: isSaving



                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))



                  : const Text('Сохранить'),



            ),



          ],



        ),



      ),



    );



  }







  void _showRoleDialog(String uid, String currentRole, String nick) {



    String selectedRole = currentRole;



    showDialog(



      context: context,



      builder: (ctx) => StatefulBuilder(



        builder: (context, setDialogState) => AlertDialog(



          title: Text('Роль для $nick'),



          content: Column(



            mainAxisSize: MainAxisSize.min,



            children: [



              RadioListTile<String>(



                title: const Text('Боец (Участник)'),



                value: 'member',



                groupValue: selectedRole,



                onChanged: (val) => setDialogState(() => selectedRole = val!),



              ),



              RadioListTile<String>(



                title: const Text('Модератор'),



                value: 'moderator',



                groupValue: selectedRole,



                onChanged: (val) => setDialogState(() => selectedRole = val!),



              ),



              RadioListTile<String>(



                title: const Text('Администратор'),



                value: 'admin',



                groupValue: selectedRole,



                onChanged: (val) => setDialogState(() => selectedRole = val!),



              ),



            ],



          ),



          actions: [



            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),



            ElevatedButton(



              onPressed: () async {



                await AdminHelper.setRole(uid, selectedRole);



                if (ctx.mounted) Navigator.pop(ctx);



                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Роль обновлена')));



              },



              child: const Text('Сохранить'),



            )



          ],



        ),



      ),



    );



  }







  void _showPrefixDialog(String uid, String currentPrefix, int currentColor, String nick) {



    final prefixController = TextEditingController(text: currentPrefix);



    int selectedColor = currentColor == 0 ? 0xFFFFD700 : currentColor;







    final List<Map<String, dynamic>> colorPalette = [



      {'name': 'Золотой', 'color': 0xFFFFD700},



      {'name': 'Кроваво-красный', 'color': 0xFFE53935},



      {'name': 'Пламя (Оранжевый)', 'color': 0xFFFF6D00},



      {'name': 'Янтарный', 'color': 0xFFFFAB00},



      {'name': 'Токсик (Лайм)', 'color': 0xFF76FF03},



      {'name': 'Изумруд', 'color': 0xFF00E676},



      {'name': 'Мята', 'color': 0xFF1DE9B6},



      {'name': 'Кибер-бирюза', 'color': 0xFF00E5FF},



      {'name': 'Неоновый синий', 'color': 0xFF2979FF},



      {'name': 'Глубокий индиго', 'color': 0xFF3D5AFE},



      {'name': 'Фиолетовый электро', 'color': 0xFFAA00FF},



      {'name': 'Пурпурный', 'color': 0xFFE040FB},



      {'name': 'Малиновый', 'color': 0xFFFF1744},



      {'name': 'Розовый неон', 'color': 0xFFFF4081},



      {'name': 'Платиновый', 'color': 0xFFECEFF1},



      {'name': 'Бронзовый', 'color': 0xFFCD7F32},



    ];







    showDialog(



      context: context,



      builder: (ctx) => StatefulBuilder(



        builder: (context, setDialogState) => AlertDialog(



          title: Text('Префикс для $nick'),



          content: SingleChildScrollView(



            child: Column(



              mainAxisSize: MainAxisSize.min,



              crossAxisAlignment: CrossAxisAlignment.start,



              children: [



                TextField(



                  controller: prefixController,



                  decoration: const InputDecoration(



                    labelText: 'Текст префикса',



                    hintText: 'Например: [Гл.Админ] или [Волк]',



                    border: OutlineInputBorder(),



                  ),



                ),



                const SizedBox(height: 16),



                const Text('Цвет подсветки:', style: TextStyle(fontWeight: FontWeight.bold)),



                const SizedBox(height: 8),



                Wrap(



                  spacing: 6,



                  runSpacing: 6,



                  children: colorPalette.map((item) {



                    final isSelected = selectedColor == item['color'];



                    return ChoiceChip(



                      label: Text(



                        item['name'],



                        style: TextStyle(



                          color: isSelected ? Colors.black : Colors.white,



                          fontWeight: FontWeight.bold,



                          fontSize: 11,



                        ),



                      ),



                      selected: isSelected,



                      selectedColor: Color(item['color']),



                      backgroundColor: Color(item['color']).withOpacity(0.25),



                      onSelected: (selected) {



                        if (selected) setDialogState(() => selectedColor = item['color']);



                      },



                    );



                  }).toList(),



                ),



              ],



            ),



          ),



          actions: [



            TextButton(



              onPressed: () async {



                await AdminHelper.setPrefix(targetUid: uid, prefix: '', colorValue: 0);



                if (ctx.mounted) Navigator.pop(ctx);



              },



              child: const Text('Сбросить', style: TextStyle(color: Colors.grey)),



            ),



            ElevatedButton(



              onPressed: () async {



                await AdminHelper.setPrefix(



                  targetUid: uid,



                  prefix: prefixController.text,



                  colorValue: selectedColor,



                );



                if (ctx.mounted) Navigator.pop(ctx);



                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Префикс сохранен')));



              },



              child: const Text('Применить'),



            ),



          ],



        ),



      ),



    );



  }







  void _showMuteDialog(String uid, String nick) {



    Duration selectedDuration = const Duration(minutes: 15);



    String durationText = '15 минут';







    final options = [



      {'text': '15 минут', 'duration': const Duration(minutes: 15)},



      {'text': '1 час', 'duration': const Duration(hours: 1)},



      {'text': '8 часов', 'duration': const Duration(hours: 8)},



      {'text': '24 часа', 'duration': const Duration(hours: 24)},



      {'text': '7 дней', 'duration': const Duration(days: 7)},



    ];







    showDialog(



      context: context,



      builder: (ctx) => StatefulBuilder(



        builder: (context, setDialogState) => AlertDialog(



          title: Text('Воткнуть кляп для $nick'),



          content: Column(



            mainAxisSize: MainAxisSize.min,



            children: options.map((opt) {



              return RadioListTile<String>(



                title: Text(opt['text'] as String),



                value: opt['text'] as String,



                groupValue: durationText,



                onChanged: (val) {



                  setDialogState(() {



                    durationText = val!;



                    selectedDuration = opt['duration'] as Duration;



                  });



                },



              );



            }).toList(),



          ),



          actions: [



            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),



            ElevatedButton(



              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),



              onPressed: () async {



                final myNick = _myMeta['nickname'] ?? 'Администратор';







                await AdminHelper.muteUser(



                  targetUid: uid,



                  targetNick: nick,



                  durationText: durationText,



                  duration: selectedDuration,



                  actorNick: myNick,



                );



                if (ctx.mounted) Navigator.pop(ctx);



                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Кляп выдан пользователю $nick')));



              },



              child: const Text('Заглушить', style: TextStyle(color: Colors.white)),



            ),



          ],



        ),



      ),



    );



  }







  void _showBanDialog(String uid, String nick) {



    final reasonController = TextEditingController();



    Duration selectedDuration = const Duration(hours: 24);



    String durationText = '24 часа';







    final options = [



      {'text': '1 час', 'duration': const Duration(hours: 1)},



      {'text': '24 часа', 'duration': const Duration(hours: 24)},



      {'text': '7 дней', 'duration': const Duration(days: 7)},



      {'text': '30 дней', 'duration': const Duration(days: 30)},



      {'text': 'Навсегда', 'duration': const Duration(days: 36500)},



    ];







    showDialog(



      context: context,



      builder: (ctx) => StatefulBuilder(



        builder: (context, setDialogState) => AlertDialog(



          title: Text('Блокировка (Бан) $nick'),



          content: SingleChildScrollView(



            child: Column(



              mainAxisSize: MainAxisSize.min,



              crossAxisAlignment: CrossAxisAlignment.start,



              children: [



                const Text('Срок блокировки:', style: TextStyle(fontWeight: FontWeight.bold)),



                ...options.map((opt) {



                  return RadioListTile<String>(



                    dense: true,



                    contentPadding: EdgeInsets.zero,



                    title: Text(opt['text'] as String),



                    value: opt['text'] as String,



                    groupValue: durationText,



                    onChanged: (val) {



                      setDialogState(() {



                        durationText = val!;



                        selectedDuration = opt['duration'] as Duration;



                      });



                    },



                  );



                }),



                const SizedBox(height: 10),



                TextField(



                  controller: reasonController,



                  maxLines: 2,



                  decoration: const InputDecoration(



                    labelText: 'Причина бана',



                    hintText: 'Например: Саботаж или оскорбления',



                    border: OutlineInputBorder(),



                  ),



                ),



              ],



            ),



          ),



          actions: [



            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),



            ElevatedButton(



              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),



              onPressed: () async {



                await AdminHelper.banUser(



                  targetUid: uid,



                  targetNick: nick,



                  durationText: durationText,



                  duration: selectedDuration,



                  reason: reasonController.text,



                );



                if (ctx.mounted) Navigator.pop(ctx);



                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Пользователь $nick забанен!')));



              },



              child: const Text('Забанить', style: TextStyle(color: Colors.white)),



            ),



          ],



        ),



      ),



    );



  }







  @override



  Widget build(BuildContext context) {



    if (_isLoading) {



      return const Scaffold(body: Center(child: CircularProgressIndicator()));



    }







    final bool isFullAdmin = AdminHelper.hasAdminRights(_myMeta['role']);







    return Scaffold(



      appBar: AppBar(



        title: const Text('Управление Альянсом [vPv]'),



        centerTitle: true,



        actions: [



          if (isFullAdmin)



            IconButton(



              icon: _isClearingChat



                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))



                  : const Icon(Icons.delete_sweep, color: Colors.redAccent),



              tooltip: 'Очистить общий чат (кроме закрепленных)',



              onPressed: _isClearingChat ? null : _clearGlobalChat,



            ),



        ],



      ),



      body: Column(



        children: [



          Padding(



            padding: const EdgeInsets.all(12.0),



            child: TextField(



              decoration: InputDecoration(



                hintText: 'Поиск бойца по никнейму или email...',



                prefixIcon: const Icon(Icons.search),



                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),



                contentPadding: const EdgeInsets.symmetric(horizontal: 16),



              ),



              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),



            ),



          ),



          Expanded(



            child: StreamBuilder<QuerySnapshot>(



              stream: FirebaseFirestore.instance.collection('users').snapshots(),



              builder: (context, snapshot) {



                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());







                final users = snapshot.data!.docs.where((doc) {



                  final data = doc.data() as Map<String, dynamic>;



                  final nick = (data['nickname'] ?? '').toString().toLowerCase();



                  final email = (data['email'] ?? '').toString().toLowerCase();



                  return nick.contains(_searchQuery) || email.contains(_searchQuery);



                }).toList();







                if (users.isEmpty) {



                  return const Center(child: Text('Бойцы не найдены'));



                }







                return ListView.separated(



                  itemCount: users.length,



                  separatorBuilder: (_, __) => const Divider(height: 1),



                  itemBuilder: (context, index) {



                    final doc = users[index];



                    final data = doc.data() as Map<String, dynamic>;



                    final uid = doc.id;



                    final nick = data['nickname'] ?? 'Аноним';



                    final email = data['email'] ?? '';



                    final role = data['role'] ?? 'member';



                    final prefix = data['prefix'] ?? '';



                    final prefixColor = data['prefixColor'] ?? 0xFFFFD700;



                    final isBanned = data['isBanned'] ?? false;



                    final isMuted = data['isMuted'] ?? false;



                    final List<dynamic> assignedAwards = data['assignedAwards'] ?? [];







                    return ListTile(



                      leading: UserAvatar(userId: uid, directUrl: data['avatarUrl'], radius: 22),



                      title: Row(



                        children: [



                          if (prefix.toString().isNotEmpty) ...[



                            Container(



                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),



                              margin: const EdgeInsets.only(right: 6),



                              decoration: BoxDecoration(



                                color: Color(prefixColor).withOpacity(0.2),



                                borderRadius: BorderRadius.circular(6),



                                border: Border.all(color: Color(prefixColor)),



                              ),



                              child: Text(



                                prefix,



                                style: TextStyle(



                                  color: Color(prefixColor),



                                  fontSize: 10,



                                  fontWeight: FontWeight.bold,



                                ),



                              ),



                            ),



                          ],



                          Flexible(



                            child: Text(



                              nick,



                              style: const TextStyle(fontWeight: FontWeight.bold),



                              overflow: TextOverflow.ellipsis,



                            ),



                          ),



                        ],



                      ),



                      subtitle: Column(



                        crossAxisAlignment: CrossAxisAlignment.start,



                        children: [



                          Text('$email | Роль: $role', style: const TextStyle(fontSize: 11)),



                          if (assignedAwards.isNotEmpty)



                            Text('🎖 Наград: ${assignedAwards.length}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),



                          if (isBanned)



                            const Text('🚫 В БАНЕ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),



                          if (isMuted)



                            const Text('🤐 В МУТЕ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),



                        ],



                      ),



                      trailing: PopupMenuButton<String>(



                        onSelected: (action) {



                          if (action == 'awards') _showAwardsDialog(uid, assignedAwards, nick);



                          if (action == 'role') _showRoleDialog(uid, role, nick);



                          if (action == 'prefix') _showPrefixDialog(uid, prefix, prefixColor, nick);



                          if (action == 'mute') _showMuteDialog(uid, nick);



                          if (action == 'unmute') AdminHelper.unmuteUser(uid);



                          if (action == 'ban') _showBanDialog(uid, nick);



                          if (action == 'unban') AdminHelper.unbanUser(uid);



                        },



                        itemBuilder: (context) => [



                          if (isFullAdmin)



                            const PopupMenuItem(



                              value: 'awards',



                              child: Row(



                                children: [



                                  Icon(Icons.military_tech, color: Colors.amber, size: 20),



                                  SizedBox(width: 8),



                                  Text('Боевые награды'),



                                ],



                              ),



                            ),



                          if (isFullAdmin)



                            const PopupMenuItem(value: 'role', child: Text('Изменить роль')),



                          if (isFullAdmin)



                            const PopupMenuItem(value: 'prefix', child: Text('Настроить префикс')),



                          if (!isMuted)



                            const PopupMenuItem(value: 'mute', child: Text('Воткнуть кляп (Мут)'))



                          else



                            const PopupMenuItem(value: 'unmute', child: Text('Снять кляп')),



                          if (isFullAdmin) ...[



                            if (!isBanned)



                              const PopupMenuItem(value: 'ban', child: Text('Забанить', style: TextStyle(color: Colors.red)))



                            else



                              const PopupMenuItem(value: 'unban', child: Text('Разбанить', style: TextStyle(color: Colors.green))),



                          ],



                        ],



                      ),



                    );



                  },



                );



              },



            ),



          ),



        ],



      ),



    );



  }



}



