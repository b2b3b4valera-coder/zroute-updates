import 'dart:async';



import 'dart:convert';



import 'package:flutter/material.dart';



import 'package:cloud_firestore/cloud_firestore.dart';



import 'package:firebase_auth/firebase_auth.dart';



import 'package:image_picker/image_picker.dart';



import 'package:record/record.dart';



import 'package:supabase_flutter/supabase_flutter.dart';



import 'package:path_provider/path_provider.dart';



import 'package:flutter/foundation.dart' show kIsWeb;



import 'package:http/http.dart' as http;







import '../utils/helpers.dart';



import '../utils/theme_notifier.dart';



import '../widgets/user_avatar.dart';



import '../widgets/custom_painters.dart';



import '../widgets/media_players.dart';



import 'chat_screen.dart';







class PrivateChatScreen extends StatefulWidget {



  final String peerUserId;



  final String peerNickname;







  const PrivateChatScreen({super.key, required this.peerUserId, required this.peerNickname});







  @override



  State<PrivateChatScreen> createState() => _PrivateChatScreenState();



}







class _PrivateChatScreenState extends State<PrivateChatScreen> {



  final TextEditingController _messageController = TextEditingController();



  final ScrollController _scrollController = ScrollController();



  final ImagePicker _picker = ImagePicker();



  final AudioRecorder _audioRecorder = AudioRecorder();



  TapDownDetails? _tapDownDetails;







  late final String _chatRoomId;



  late Stream<QuerySnapshot> _privateMessagesStream;



  int _messageLimit = 30;



  bool _isLoadingMore = false;







  Timer? _recordDurationTimer;



  Timer? _typingTimer;



  int _recordDuration = 0;







  bool _isUploading = false;



  bool _isRecording = false;



  bool _hasText = false;



  bool _isTyping = false;



  bool _showScrollDownButton = false;







  Map<String, dynamic>? _replyMessage;



  String? _editingMessageId;



  bool _isSelectionMode = false;



  final Set<String> _selectedMessageIds = {};



  final Map<String, DocumentSnapshot> _selectedDocs = {};







  bool _isBlockedByMe = false;



  bool _isBlockedByPeer = false;







  final Map<String, String> _translations = {};



  final Set<String> _translatingIds = {};







  @override



  void initState() {



    super.initState();



    final currentUserId = FirebaseAuth.instance.currentUser!.uid;







    if (currentUserId.compareTo(widget.peerUserId) > 0) {



      _chatRoomId = '${currentUserId}_${widget.peerUserId}';



    } else {



      _chatRoomId = '${widget.peerUserId}_$currentUserId';



    }







    _initPrivateStream();







    FirebaseFirestore.instance



        .collection('chats_meta')



        .doc('${_chatRoomId}_$currentUserId')



        .set({'isRead': true, 'recipientId': currentUserId}, SetOptions(merge: true));







    _messageController.addListener(() {



      final hasTextNow = _messageController.text.trim().isNotEmpty;



      if (hasTextNow != _hasText) {



        setState(() {



          _hasText = hasTextNow;



        });



      }







      if (!_isRecording && !_isUploading) {



        if (!_isTyping && hasTextNow) {



          _isTyping = true;



          _setPrivateStatus('печатает...');



        }







        _typingTimer?.cancel();



        _typingTimer = Timer(const Duration(seconds: 2), () {



          if (_isTyping) {



            _isTyping = false;



            _setPrivateStatus(null);



          }



        });



      }



    });







    _scrollController.addListener(() {



      if (_scrollController.hasClients) {



        final shouldShow = _scrollController.offset > 250;



        if (shouldShow != _showScrollDownButton) {



          setState(() {



            _showScrollDownButton = shouldShow;



          });



        }







        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {



          _loadMorePrivateMessages();



        }



      }



    });







    _checkBlacklistStatus();



  }







  Future<void> _setPrivateStatus(String? actionText) async {



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    if (currentUserId == null) return;







    await FirebaseFirestore.instance.collection('typing_status').doc('${_chatRoomId}_$currentUserId').set({



      'action': actionText ?? '',



      'chatRoomId': _chatRoomId,



      'userId': currentUserId,



      'updatedAt': FieldValue.serverTimestamp(),



    }, SetOptions(merge: true));



  }







  void _initPrivateStream() {



    final currentUserId = FirebaseAuth.instance.currentUser!.uid;



    _privateMessagesStream = FirebaseFirestore.instance



        .collection('chat_rooms')



        .doc(_chatRoomId)



        .collection('messages')



        .where('deletedFor', isNotEqualTo: currentUserId)



        .orderBy('timestamp', descending: true)



        .limit(_messageLimit)



        .snapshots();



  }







  void _loadMorePrivateMessages() {



    setState(() {



      _isLoadingMore = true;



      _messageLimit += 30;



      _initPrivateStream();



    });







    Future.delayed(const Duration(milliseconds: 500), () {



      if (mounted) setState(() => _isLoadingMore = false);



    });



  }







  void _checkBlacklistStatus() {



    final currentUserId = FirebaseAuth.instance.currentUser!.uid;







    FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots().listen((doc) {



      if (doc.exists && mounted) {



        final blocked = List<String>.from(doc.data()?['blockedUsers'] ?? []);



        setState(() {



          _isBlockedByMe = blocked.contains(widget.peerUserId);



        });



      }



    });







    FirebaseFirestore.instance.collection('users').doc(widget.peerUserId).snapshots().listen((doc) {



      if (doc.exists && mounted) {



        final blocked = List<String>.from(doc.data()?['blockedUsers'] ?? []);



        setState(() {



          _isBlockedByPeer = blocked.contains(currentUserId);



        });



      }



    });



  }







  Future<void> _toggleBlockUser() async {



    final currentUserId = FirebaseAuth.instance.currentUser!.uid;



    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);



    final userDoc = await userRef.get();



    List<String> blocked = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);







    if (_isBlockedByMe) {



      blocked.remove(widget.peerUserId);



      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.peerNickname} удалён из чёрного списка')));



    } else {



      blocked.add(widget.peerUserId);



      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.peerNickname} добавлен в чёрный список')));



    }







    await userRef.update({'blockedUsers': blocked});



  }







  // Функция полной очистки диалога только для себя



  Future<void> _clearChatForMe() async {



    final confirm = await showDialog<bool>(



      context: context,



      builder: (ctx) => AlertDialog(



        title: const Text('Очистить диалог'),



        content: const Text('Вы действительно хотите полностью очистить этот диалог для себя? Ваши сообщения будут скрыты только у вас.'),



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







    try {



      final currentUserId = FirebaseAuth.instance.currentUser!.uid;



      final messagesSnapshot = await FirebaseFirestore.instance



          .collection('chat_rooms')



          .doc(_chatRoomId)



          .collection('messages')



          .get();







      final batch = FirebaseFirestore.instance.batch();



      for (var doc in messagesSnapshot.docs) {



        batch.update(doc.reference, {'deletedFor': currentUserId});



      }



      await batch.commit();







      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          const SnackBar(content: Text('Диалог успешно очищен для вас!')),



        );



      }



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          SnackBar(content: Text('Ошибка очистки: $e')),



        );



      }



    }



  }







  @override



  void dispose() {



    _setPrivateStatus(null);



    _recordDurationTimer?.cancel();



    _typingTimer?.cancel();



    _messageController.dispose();



    _scrollController.dispose();



    _audioRecorder.dispose();



    super.dispose();



  }







  void _scrollToBottom() {



    if (_scrollController.hasClients) {



      _scrollController.animateTo(



        0,



        duration: const Duration(milliseconds: 300),



        curve: Curves.easeOut,



      );



    }



  }







  Future<void> _translateMessage(String messageId, String text) async {



    if (text.trim().isEmpty) return;







    setState(() {



      _translatingIds.add(messageId);



    });







    try {



      final url = Uri.parse(



        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=ru&dt=t&q=${Uri.encodeComponent(text)}',



      );



      final response = await http.get(url);







      if (response.statusCode == 200) {



        final decoded = jsonDecode(response.body);



        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {



          final buffer = StringBuffer();



          for (var part in decoded[0]) {



            if (part is List && part.isNotEmpty && part[0] != null) {



              buffer.write(part[0]);



            }



          }



          final resultText = buffer.toString().trim();



          if (mounted) {



            setState(() {



              _translations[messageId] = resultText.isNotEmpty ? resultText : 'Текст перевода пуст';



            });



          }



          return;



        }



      }



      if (mounted) {



        setState(() {



          _translations[messageId] = 'Не удалось получить перевод';



        });



      }



    } catch (e) {



      if (mounted) {



        setState(() {



          _translations[messageId] = 'Ошибка соединения: $e';



        });



      }



    } finally {



      if (mounted) {



        setState(() {



          _translatingIds.remove(messageId);



        });



      }



    }



  }







  Future<void> _sendPrivateMessage() async {



    final user = FirebaseAuth.instance.currentUser;



    if (user != null && !user.emailVerified) {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(content: Text('Подтвердите ваш Email перед отправкой личных сообщений!')),



      );



      return;



    }







    if (_isBlockedByMe || _isBlockedByPeer) {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(content: Text('Невозможно отправить сообщение: переписка заблокирована.')),



      );



      return;



    }







    if (_messageController.text.trim().isNotEmpty) {



      final currentUserId = user!.uid;



      final text = _messageController.text.trim();







      _setPrivateStatus(null);







      if (_editingMessageId != null) {



        await FirebaseFirestore.instance



            .collection('chat_rooms')



            .doc(_chatRoomId)



            .collection('messages')



            .doc(_editingMessageId)



            .update({



          'text': text,



          'isEdited': true,



          'editedAt': FieldValue.serverTimestamp(),



        });



      } else {



        await FirebaseFirestore.instance



            .collection('chat_rooms')



            .doc(_chatRoomId)



            .collection('messages')



            .add({



          'type': 'text',



          'text': text,



          'senderId': currentUserId,



          'timestamp': FieldValue.serverTimestamp(),



          'replyTo': _replyMessage,



        });







        await FirebaseFirestore.instance



            .collection('chats_meta')



            .doc('${_chatRoomId}_${widget.peerUserId}')



            .set({



          'isRead': false,



          'recipientId': widget.peerUserId,



          'lastActivity': FieldValue.serverTimestamp(),



        }, SetOptions(merge: true));



      }







      _messageController.clear();



      setState(() {



        _replyMessage = null;



        _editingMessageId = null;



      });



      _scrollToBottom();



    }



  }







  Future<void> _startPrivateRecording() async {



    if (_isBlockedByMe || _isBlockedByPeer) return;







    try {



      if (await _audioRecorder.hasPermission()) {



        String? recordPath;



        if (!kIsWeb) {



          final dir = await getTemporaryDirectory();



          recordPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';



        }







        await _audioRecorder.start(



          const RecordConfig(encoder: AudioEncoder.aacLc),



          path: recordPath ?? '',



        );







        await _setPrivateStatus('записывает голосовое сообщение...');







        _recordDuration = 0;



        _recordDurationTimer?.cancel();



        _recordDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {



          if (mounted) {



            setState(() {



              _recordDuration++;



            });







            if (_recordDuration >= kMaxAudioRecordDuration) {



              timer.cancel();



              _stopAndSendPrivateRecording();



              ScaffoldMessenger.of(context).showSnackBar(



                const SnackBar(content: Text('Лимит записи (5 мин) достигнут. Аудио отправлено.')),



              );



            }



          }



        });







        setState(() {



          _isRecording = true;



        });



      }



    } catch (e) {



      await _setPrivateStatus(null);



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка микрофона: $e')));



      }



    }



  }







  Future<void> _stopAndSendPrivateRecording() async {



    if (!_isRecording) return;



    _recordDurationTimer?.cancel();







    try {



      final path = await _audioRecorder.stop();



      setState(() {



        _isRecording = false;



        _isUploading = true;



      });







      await _setPrivateStatus('загружает голосовое сообщение...');







      if (path != null && _recordDuration > 0) {



        final xfile = XFile(path);



        final bytes = await xfile.readAsBytes();



        final user = FirebaseAuth.instance.currentUser;



        final storagePath = 'private_voices/${DateTime.now().millisecondsSinceEpoch}_${user?.uid ?? 'anon'}.m4a';







        final storage = Supabase.instance.client.storage.from('chat-media');



        await storage.uploadBinary(



          storagePath,



          bytes,



          fileOptions: const FileOptions(contentType: 'audio/m4a', upsert: true),



        );



        final downloadUrl = storage.getPublicUrl(storagePath);







        await FirebaseFirestore.instance



            .collection('chat_rooms')



            .doc(_chatRoomId)



            .collection('messages')



            .add({



          'type': 'audio',



          'mediaUrl': downloadUrl,



          'text': '',



          'senderId': user?.uid ?? '',



          'timestamp': FieldValue.serverTimestamp(),



          'replyTo': _replyMessage,



        });







        await FirebaseFirestore.instance



            .collection('chats_meta')



            .doc('${_chatRoomId}_${widget.peerUserId}')



            .set({



          'isRead': false,



          'recipientId': widget.peerUserId,



          'lastActivity': FieldValue.serverTimestamp(),



        }, SetOptions(merge: true));







        setState(() {



          _replyMessage = null;



        });



        _scrollToBottom();



      }



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки аудио: $e')));



      }



    } finally {



      await _setPrivateStatus(null);



      if (mounted) setState(() { _isUploading = false; });



    }



  }







  Future<void> _pickAndUploadPrivateMedia(bool isVideo) async {



    if (_isBlockedByMe || _isBlockedByPeer) return;







    final XFile? file = isVideo



        ? await _picker.pickVideo(source: ImageSource.gallery)



        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);







    if (file == null) return;







    setState(() { _isUploading = true; });



    await _setPrivateStatus(isVideo ? 'загружает видео...' : 'загружает фотографию...');







    try {



      final bytes = await file.readAsBytes();



      final user = FirebaseAuth.instance.currentUser;



      final ext = file.name.split('.').last;



      final path = 'private_media/${DateTime.now().millisecondsSinceEpoch}_${user?.uid ?? 'anon'}.$ext';







      final storage = Supabase.instance.client.storage.from('chat-media');



      await storage.uploadBinary(



        path,



        bytes,



        fileOptions: FileOptions(contentType: isVideo ? 'video/$ext' : 'image/$ext', upsert: true),



      );



      final downloadUrl = storage.getPublicUrl(path);







      await FirebaseFirestore.instance



          .collection('chat_rooms')



          .doc(_chatRoomId)



          .collection('messages')



          .add({



        'type': isVideo ? 'video' : 'image',



        'mediaUrl': downloadUrl,



        'text': '',



        'senderId': user?.uid ?? '',



        'timestamp': FieldValue.serverTimestamp(),



        'replyTo': _replyMessage,



      });







      await FirebaseFirestore.instance



          .collection('chats_meta')



          .doc('${_chatRoomId}_${widget.peerUserId}')



          .set({



        'isRead': false,



        'recipientId': widget.peerUserId,



        'lastActivity': FieldValue.serverTimestamp(),



      }, SetOptions(merge: true));







      setState(() {



        _replyMessage = null;



      });



      _scrollToBottom();



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));



      }



    } finally {



      await _setPrivateStatus(null);



      if (mounted) setState(() { _isUploading = false; });



    }



  }







  void _showCompactContextMenu(BuildContext context, DocumentSnapshot doc, Offset position) async {



    final msg = doc.data() as Map<String, dynamic>;



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    final isMe = msg['senderId'] == currentUserId;



    final mediaUrl = msg['mediaUrl'] as String?;



    final type = msg['type'] ?? 'text';



    final theme = Theme.of(context);







    final selected = await showMenu<String>(



      context: context,



      elevation: 8,



      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),



      color: theme.dialogBackgroundColor,



      surfaceTintColor: Colors.transparent,



      position: RelativeRect.fromRect(



        Rect.fromLTWH(position.dx, position.dy - 20, 0, 0),



        Offset.zero & MediaQuery.of(context).size,



      ),



      items: [



        PopupMenuItem(



          value: 'reply',



          child: Row(



            children: [



              Icon(Icons.reply, color: theme.colorScheme.primary, size: 20),



              const SizedBox(width: 12),



              const Text('Ответить'),



            ],



          ),



        ),



        if (type == 'text')



          PopupMenuItem(



            value: 'translate',



            child: Row(



              children: [



                const Icon(Icons.translate, color: Colors.indigoAccent, size: 20),



                const SizedBox(width: 12),



                Text(_translations.containsKey(doc.id) ? 'Скрыть перевод' : 'Перевести'),



              ],



            ),



          ),



        if (isMe && type == 'text')



          PopupMenuItem(



            value: 'edit',



            child: Row(



              children: [



                Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),



                const SizedBox(width: 12),



                const Text('Редактировать'),



              ],



            ),



          ),



        PopupMenuItem(



          value: 'forward',



          child: Row(



            children: [



              Icon(Icons.forward, color: theme.colorScheme.secondary, size: 20),



              const SizedBox(width: 12),



              const Text('Переслать'),



            ],



          ),



        ),



        if (mediaUrl != null && mediaUrl.isNotEmpty)



          const PopupMenuItem(



            value: 'download',



            child: Row(



              children: [



                Icon(Icons.download, color: Colors.teal, size: 20),



                const SizedBox(width: 12),



                Text('Скачать на устройство'),



              ],



            ),



          ),



        const PopupMenuItem(



          value: 'select',



          child: Row(



            children: [



              Icon(Icons.check_box_outlined, color: Colors.orange, size: 20),



              const SizedBox(width: 12),



              const Text('Выделить'),



            ],



          ),



        ),



        if (isMe)



          const PopupMenuItem(



            value: 'delete',



            child: Row(



              children: [



                Icon(Icons.delete, color: Colors.red, size: 20),



                const SizedBox(width: 12),



                Text('Удалить', style: TextStyle(color: Colors.red)),



              ],



            ),



          ),



      ],



    );







    if (selected == 'reply') {



      setState(() {



        _replyMessage = {



          'sender': isMe ? 'Вы' : widget.peerNickname,



          'text': msg['text'] ?? '',



          'type': msg['type'] ?? 'text',



        };



      });



    } else if (selected == 'translate') {



      if (_translations.containsKey(doc.id)) {



        setState(() => _translations.remove(doc.id));



      } else {



        _translateMessage(doc.id, msg['text'] ?? '');



      }



    } else if (selected == 'edit') {



      setState(() {



        _editingMessageId = doc.id;



        _messageController.text = msg['text'] ?? '';



        _replyMessage = null;



      });



    } else if (selected == 'forward') {



      _showForwardDialog([msg]);



    } else if (selected == 'download' && mediaUrl != null) {



      downloadMediaFile(context, mediaUrl);



    } else if (selected == 'select') {



      setState(() {



        _isSelectionMode = true;



        _selectedMessageIds.add(doc.id);



        _selectedDocs[doc.id] = doc;



      });



    } else if (selected == 'delete') {



      await doc.reference.update({'deletedFor': currentUserId});



    }



  }







  void _showForwardDialog(List<Map<String, dynamic>> messagesToForward) {



    final currentUid = FirebaseAuth.instance.currentUser?.uid;



    showDialog(



      context: context,



      builder: (dialogCtx) => AlertDialog(



        title: const Text('Переслать в...'),



        content: SizedBox(



          width: double.maxFinite,



          height: 320,



          child: StreamBuilder<QuerySnapshot>(



            stream: FirebaseFirestore.instance.collection('users').snapshots(),



            builder: (context, snapshot) {



              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());



              final users = snapshot.data!.docs;







              return ListView(



                children: [



                  ListTile(



                    leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.groups, color: Colors.white)),



                    title: const Text('Общий чат', style: TextStyle(fontWeight: FontWeight.bold)),



                    onTap: () async {



                      Navigator.pop(dialogCtx);



                      for (var m in messagesToForward) {



                        await FirebaseFirestore.instance.collection('messages').add({



                          'type': m['type'] ?? 'text',



                          'text': m['text'] ?? '',



                          'mediaUrl': m['mediaUrl'] ?? '',



                          'sender': FirebaseAuth.instance.currentUser?.displayName ?? 'Я',



                          'senderId': currentUid ?? '',



                          'timestamp': FieldValue.serverTimestamp(),



                          'reactions': {},



                          'replyTo': m['replyTo'],



                          'forwardedFrom': 'ЛС (${widget.peerNickname})',



                        });



                      }



                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Переслано в общий чат')));



                    },



                  ),



                  const Divider(),



                  ...users.where((u) => u.id != currentUid).map((uDoc) {



                    final uData = uDoc.data() as Map<String, dynamic>;



                    final name = uData['nickname'] ?? 'Без имени';



                    final targetId = uDoc.id;







                    return ListTile(



                      leading: UserAvatar(userId: targetId, directUrl: uData['avatarUrl'], radius: 18),



                      title: Text(name),



                      onTap: () async {



                        Navigator.pop(dialogCtx);



                        final targetRoomId = currentUid!.compareTo(targetId) > 0



                            ? '${currentUid}_$targetId'



                            : '${targetId}_$currentUid';







                        for (var m in messagesToForward) {



                          await FirebaseFirestore.instance



                              .collection('chat_rooms')



                              .doc(targetRoomId)



                              .collection('messages')



                              .add({



                            'type': m['type'] ?? 'text',



                            'text': m['text'] ?? '',



                            'mediaUrl': m['mediaUrl'] ?? '',



                            'senderId': currentUid,



                            'timestamp': FieldValue.serverTimestamp(),



                            'forwardedFrom': 'ЛС (${widget.peerNickname})',



                          });



                        }







                        await FirebaseFirestore.instance



                            .collection('chats_meta')



                            .doc('${targetRoomId}_$targetId')



                            .set({



                          'isRead': false,



                          'recipientId': targetId,



                          'lastActivity': FieldValue.serverTimestamp(),



                        }, SetOptions(merge: true));







                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Переслано для $name')));



                      },



                    );



                  }),



                ],



              );



            },



          ),



        ),



        actions: [



          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Отмена')),



        ],



      ),



    );



  }







  void _deleteSelectedMessages() async {



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    int deletedCount = 0;







    for (var doc in _selectedDocs.values) {



      final data = doc.data() as Map<String, dynamic>;



      if (data['senderId'] == currentUserId) {



        await doc.reference.update({'deletedFor': currentUserId});



        deletedCount++;



      }



    }







    setState(() {



      _isSelectionMode = false;



      _selectedMessageIds.clear();



      _selectedDocs.clear();



    });







    if (mounted) {



      ScaffoldMessenger.of(context).showSnackBar(



        SnackBar(content: Text('Успешно скрыто для вас: $deletedCount')),



      );



    }



  }







  Widget _buildPrivateMessageContent(Map<String, dynamic> msg, bool isMe) {



    final type = msg['type'] ?? 'text';



    final text = msg['text'] ?? '';



    final mediaUrl = msg['mediaUrl'] ?? '';



    final isEdited = msg['isEdited'] ?? false;







    if (type == 'image') {



      return GestureDetector(



        onTap: () {



          showDialog(



            context: context,



            builder: (ctx) => Dialog(



              backgroundColor: Colors.black.withOpacity(0.95),



              insetPadding: const EdgeInsets.all(10),



              child: Stack(



                children: [



                  Center(



                    child: InteractiveViewer(



                      panEnabled: true,



                      minScale: 0.5,



                      maxScale: 4.0,



                      child: Image.network(mediaUrl, fit: BoxFit.contain),



                    ),



                  ),



                  Positioned(



                    top: 10,



                    right: 10,



                    child: Row(



                      children: [



                        IconButton(



                          icon: const Icon(Icons.download, color: Colors.white, size: 28),



                          onPressed: () => downloadMediaFile(ctx, mediaUrl),



                        ),



                        IconButton(



                          icon: const Icon(Icons.close, color: Colors.white, size: 30),



                          onPressed: () => Navigator.pop(ctx),



                        ),



                      ],



                    ),



                  ),



                ],



              ),



            ),



          );



        },



        child: ClipRRect(



          borderRadius: BorderRadius.circular(8),



          child: Image.network(mediaUrl, width: 220, height: 220, fit: BoxFit.cover),



        ),



      );



    } else if (type == 'video') {



      return GestureDetector(



        onTap: () {



          showDialog(



            context: context,



            builder: (context) => VideoPlayerDialog(videoUrl: mediaUrl),



          );



        },



        child: Container(



          width: 200,



          height: 140,



          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),



          child: const Column(



            mainAxisAlignment: MainAxisAlignment.center,



            children: [



              Icon(Icons.play_circle_fill, color: Colors.white, size: 50),



              SizedBox(height: 6),



              Text('Видеозапись', style: TextStyle(color: Colors.white, fontSize: 13)),



            ],



          ),



        ),



      );



    } else if (type == 'audio') {



      return AudioMessagePlayer(audioUrl: mediaUrl);



    }







    return buildTextWithMentions(context, text, isEdited, isMe: isMe);



  }







  @override



  Widget build(BuildContext context) {



    final currentUserId = FirebaseAuth.instance.currentUser!.uid;



    final theme = Theme.of(context);







    final currentTheme = appThemeNotifier.value;



    final bool isBloodTheme = currentTheme == 'Бордовый (Кровь)' || currentTheme == 'blood_crimson';



    final bool isZombieTheme = currentTheme == 'Зомби' || currentTheme == 'zombie_horde';



    final bool isGreyTheme = currentTheme == 'Серый узор' || currentTheme == 'grey_pattern';



    final bool isDarkGeoTheme = currentTheme == 'Тёмная' || currentTheme == 'Тёмная сталь' || currentTheme == 'dark_geo';







    CustomPainter? bgPainter;



    if (isGreyTheme) {



      bgPainter = GeoPatternPainter(Colors.white.withOpacity(0.04));



    } else if (isDarkGeoTheme) {



      bgPainter = GeoPatternPainter(Colors.cyan.withOpacity(0.03));



    } else if (isBloodTheme) {



      bgPainter = PatternPainter(Colors.red.withOpacity(0.03));



    } else if (isZombieTheme) {



      bgPainter = GeoPatternPainter(const Color(0xFF4CAF50).withOpacity(0.03));



    }







    return Scaffold(



      appBar: _isSelectionMode



          ? AppBar(



        backgroundColor: theme.colorScheme.primary.withOpacity(0.3),



        leading: IconButton(



          icon: const Icon(Icons.close),



          onPressed: () {



            setState(() {



              _isSelectionMode = false;



              _selectedMessageIds.clear();



              _selectedDocs.clear();



            });



          },



        ),



        title: Text('Выбрано: ${_selectedMessageIds.length}'),



        actions: [



          IconButton(



            icon: const Icon(Icons.forward),



            onPressed: () {



              final list = _selectedDocs.values.map((d) => d.data() as Map<String, dynamic>).toList();



              _showForwardDialog(list);



            },



          ),



          IconButton(



            icon: const Icon(Icons.delete, color: Colors.red),



            onPressed: _deleteSelectedMessages,



          ),



        ],



      )



          : AppBar(



        title: StreamBuilder<DocumentSnapshot>(



          stream: FirebaseFirestore.instance.collection('typing_status').doc('${_chatRoomId}_${widget.peerUserId}').snapshots(),



          builder: (context, snapshot) {



            String peerAction = '';



            if (snapshot.hasData && snapshot.data!.exists) {



              final data = snapshot.data!.data() as Map<String, dynamic>?;



              peerAction = data?['action'] ?? '';



            }







            return Column(



              mainAxisSize: MainAxisSize.min,



              children: [



                Text(widget.peerNickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),



                if (peerAction.isNotEmpty)



                  Text(



                    peerAction,



                    style: const TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold),



                  ),



              ],



            );



          },



        ),



        centerTitle: true,



        actions: [



          PopupMenuButton<String>(



            onSelected: (value) {



              if (value == 'block') {



                _toggleBlockUser();



              } else if (value == 'clear_chat') {



                _clearChatForMe();



              }



            },



            itemBuilder: (context) => [



              const PopupMenuItem(



                value: 'clear_chat',



                child: Row(



                  children: [



                    Icon(Icons.cleaning_services, color: Colors.orange, size: 20),



                    SizedBox(width: 8),



                    Text('Очистить диалог (для себя)'),



                  ],



                ),



              ),



              PopupMenuItem(



                value: 'block',



                child: Text(



                  _isBlockedByMe ? 'Разблокировать' : 'Заблокировать',



                  style: TextStyle(color: _isBlockedByMe ? Colors.green : Colors.red),



                ),



              ),



            ],



          ),



        ],



      ),



      body: CustomPaint(



        painter: bgPainter,



        child: Stack(



          children: [



            Column(



              children: [



                if (_isBlockedByMe)



                  Container(



                    color: Colors.red[100],



                    width: double.infinity,



                    padding: const EdgeInsets.all(8),



                    child: const Text('Вы заблокировали этого пользователя', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),



                  )



                else if (_isBlockedByPeer)



                  Container(



                    color: Colors.grey[300],



                    width: double.infinity,



                    padding: const EdgeInsets.all(8),



                    child: const Text('Этот пользователь ограничил доступ к сообщениям', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),



                  ),



                if (_isUploading)



                  const LinearProgressIndicator(minHeight: 3),



                Expanded(



                  child: StreamBuilder<QuerySnapshot>(



                    stream: _privateMessagesStream,



                    builder: (context, snapshot) {



                      if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingMore) {



                        return const Center(child: CircularProgressIndicator());



                      }







                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {



                        return const Center(child: Text('Это начало вашего личного чата. Напишите сообщение!'));



                      }







                      final messages = snapshot.data!.docs;







                      return ListView.builder(



                        key: const PageStorageKey('private_chat_list'),



                        controller: _scrollController,



                        reverse: true,



                        cacheExtent: 1500,



                        physics: const AlwaysScrollableScrollPhysics(),



                        itemCount: messages.length + (_isLoadingMore ? 1 : 0),



                        itemBuilder: (context, index) {



                          if (index == messages.length) {



                            return const Center(



                              child: Padding(



                                padding: EdgeInsets.all(8.0),



                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),



                              ),



                            );



                          }







                          final msgDoc = messages[index];



                          final msg = msgDoc.data() as Map<String, dynamic>;



                          final senderId = msg['senderId'] ?? '';



                          final replyTo = msg['replyTo'] as Map<String, dynamic>?;



                          final forwardedFrom = msg['forwardedFrom'] as String?;



                          final timestamp = msg['timestamp'];







                          bool isMe = senderId == currentUserId;



                          bool isSelected = _selectedMessageIds.contains(msgDoc.id);







                          final double bottomMargin = isBloodTheme ? 18.0 : (isZombieTheme ? 8.0 : 4.0);







                          Color bubbleColor = isSelected



                              ? theme.colorScheme.primary.withOpacity(0.3)



                              : (isMe ? theme.colorScheme.primary.withOpacity(0.15) : theme.colorScheme.surface);







                          if (isBloodTheme) {



                            bubbleColor = isMe ? const Color(0xFF4A0E0E) : const Color(0xFF2A0808);



                          } else if (isZombieTheme) {



                            bubbleColor = isMe ? const Color(0xFF1E3320) : const Color(0xFF142416);



                          } else if (isGreyTheme) {



                            bubbleColor = isMe ? const Color(0xFF383D40) : const Color(0xFF25292B);



                          }







                          final bool isTranslating = _translatingIds.contains(msgDoc.id);



                          final String? translatedText = _translations[msgDoc.id];







                          Widget messageBubble = Container(



                            padding: EdgeInsets.only(



                              left: (isZombieTheme && !isMe) ? 18 : 12,



                              right: (isZombieTheme && isMe) ? 18 : 12,



                              top: 8,



                              bottom: 8,



                            ),



                            constraints: BoxConstraints(



                              maxWidth: MediaQuery.of(context).size.width > 600



                                  ? 400.0



                                  : MediaQuery.of(context).size.width * 0.78,



                            ),



                            decoration: BoxDecoration(



                              color: bubbleColor,



                              borderRadius: BorderRadius.circular(12),



                              border: isSelected



                                  ? Border.all(color: theme.colorScheme.primary, width: 2)



                                  : (isZombieTheme



                                  ? Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1.2)



                                  : null),



                            ),



                            child: Column(



                              crossAxisAlignment: CrossAxisAlignment.start,



                              mainAxisSize: MainAxisSize.min,



                              children: [



                                if (forwardedFrom != null)



                                  Padding(



                                    padding: const EdgeInsets.only(bottom: 4.0),



                                    child: Text(



                                      'Переслано: $forwardedFrom',



                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),



                                    ),



                                  ),



                                if (replyTo != null)



                                  Container(



                                    margin: const EdgeInsets.only(bottom: 6),



                                    padding: const EdgeInsets.all(6),



                                    decoration: BoxDecoration(



                                      color: Colors.black.withOpacity(0.1),



                                      borderRadius: BorderRadius.circular(6),



                                      border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),



                                    ),



                                    child: Column(



                                      crossAxisAlignment: CrossAxisAlignment.start,



                                      children: [



                                        Text(replyTo['sender'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.primary)),



                                        Text(replyTo['text'] ?? 'Вложение', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),



                                      ],



                                    ),



                                  ),



                                _buildPrivateMessageContent(msg, isMe),







                                if (isTranslating) ...[



                                  const SizedBox(height: 6),



                                  const Row(



                                    mainAxisSize: MainAxisSize.min,



                                    children: [



                                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),



                                      SizedBox(width: 6),



                                      Text('Переводим...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),



                                    ],



                                  ),



                                ] else if (translatedText != null) ...[



                                  Container(



                                    margin: const EdgeInsets.only(top: 6),



                                    padding: const EdgeInsets.all(8),



                                    decoration: BoxDecoration(



                                      color: Colors.black.withOpacity(0.15),



                                      borderRadius: BorderRadius.circular(8),



                                      border: const Border(left: BorderSide(color: Colors.indigoAccent, width: 3)),



                                    ),



                                    child: Column(



                                      crossAxisAlignment: CrossAxisAlignment.start,



                                      children: [



                                        Row(



                                          mainAxisSize: MainAxisSize.min,



                                          children: [



                                            const Icon(Icons.translate, size: 12, color: Colors.indigoAccent),



                                            const SizedBox(width: 4),



                                            const Text(



                                              'Перевод (RU):',



                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigoAccent),



                                            ),



                                            const Spacer(),



                                            GestureDetector(



                                              onTap: () => setState(() => _translations.remove(msgDoc.id)),



                                              child: const Icon(Icons.close, size: 14, color: Colors.grey),



                                            ),



                                          ],



                                        ),



                                        const SizedBox(height: 3),



                                        Text(



                                          translatedText,



                                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),



                                        ),



                                      ],



                                    ),



                                  ),



                                ],







                                Padding(



                                  padding: const EdgeInsets.only(top: 4.0),



                                  child: Row(



                                    mainAxisSize: MainAxisSize.min,



                                    mainAxisAlignment: MainAxisAlignment.end,



                                    children: [



                                      Text(



                                        formatMessageTime(timestamp),



                                        style: const TextStyle(



                                          fontSize: 10,



                                          color: Colors.grey,



                                        ),



                                      ),



                                    ],



                                  ),



                                ),



                              ],



                            ),



                          );







                          if (isBloodTheme) {



                            messageBubble = CustomPaint(



                              foregroundPainter: BloodDripPainter(bubbleColor),



                              child: messageBubble,



                            );



                          } else if (isZombieTheme) {



                            messageBubble = CustomPaint(



                              foregroundPainter: ZombieHandsPainter(isMe: isMe),



                              child: messageBubble,



                            );



                          }







                          return Align(



                            key: ValueKey(msgDoc.id),



                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,



                            child: GestureDetector(



                              onTapDown: (details) {



                                _tapDownDetails = details;



                              },



                              onTap: () {



                                if (_isSelectionMode) {



                                  setState(() {



                                    if (isSelected) {



                                      _selectedMessageIds.remove(msgDoc.id);



                                      _selectedDocs.remove(msgDoc.id);



                                      if (_selectedMessageIds.isEmpty) _isSelectionMode = false;



                                    } else {



                                      _selectedMessageIds.add(msgDoc.id);



                                      _selectedDocs[msgDoc.id] = msgDoc;



                                    }



                                  });



                                }



                              },



                              onLongPress: () {



                                if (!_isSelectionMode && _tapDownDetails != null) {



                                  _showCompactContextMenu(context, msgDoc, _tapDownDetails!.globalPosition);



                                }



                              },



                              child: Padding(



                                padding: EdgeInsets.only(top: 4, bottom: bottomMargin, left: 12, right: 12),



                                child: messageBubble,



                              ),



                            ),



                          );



                        },



                      );



                    },



                  ),



                ),



                if (_replyMessage != null)



                  Container(



                    color: theme.colorScheme.surface,



                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),



                    child: Row(



                      children: [



                        Icon(Icons.reply, color: theme.colorScheme.primary),



                        const SizedBox(width: 8),



                        Expanded(



                          child: Column(



                            crossAxisAlignment: CrossAxisAlignment.start,



                            children: [



                              Text('Ответ для ${_replyMessage!['sender']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.primary)),



                              Text(_replyMessage!['text'] ?? 'Вложение', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),



                            ],



                          ),



                        ),



                        IconButton(



                          icon: const Icon(Icons.close, size: 20),



                          onPressed: () => setState(() => _replyMessage = null),



                        ),



                      ],



                    ),



                  ),



                if (_editingMessageId != null)



                  Container(



                    color: theme.colorScheme.primary.withOpacity(0.1),



                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),



                    child: Row(



                      children: [



                        Icon(Icons.edit, color: theme.colorScheme.primary),



                        const SizedBox(width: 8),



                        Expanded(



                          child: Text('Редактирование сообщения', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary)),



                        ),



                        IconButton(



                          icon: const Icon(Icons.close, size: 20),



                          onPressed: () {



                            setState(() {



                              _editingMessageId = null;



                              _messageController.clear();



                            });



                          },



                        ),



                      ],



                    ),



                  ),



                if (!_isBlockedByMe && !_isBlockedByPeer)



                  Container(



                    padding: const EdgeInsets.all(8.0),



                    color: theme.scaffoldBackgroundColor,



                    child: Row(



                      children: [



                        IconButton(



                          icon: const Icon(Icons.attach_file, color: Colors.grey, size: 28),



                          onPressed: () => _pickAndUploadPrivateMedia(false),



                        ),



                        Expanded(



                          child: _isRecording



                              ? Container(



                            height: 48,



                            alignment: Alignment.centerLeft,



                            padding: const EdgeInsets.symmetric(horizontal: 14),



                            decoration: BoxDecoration(



                              color: Colors.red.withOpacity(0.1),



                              borderRadius: BorderRadius.circular(24),



                              border: Border.all(color: Colors.red.withOpacity(0.3)),



                            ),



                            child: Row(



                              children: [



                                const Icon(Icons.fiber_manual_record, color: Colors.red, size: 18),



                                const SizedBox(width: 8),



                                Text(



                                  '${formatDuration(_recordDuration)} / 05:00',



                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),



                                ),



                                const Spacer(),



                                const Text(



                                  'Отпустите для отправки',



                                  style: TextStyle(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic),



                                ),



                              ],



                            ),



                          )



                              : TextField(



                            controller: _messageController,



                            decoration: const InputDecoration(



                              hintText: 'Личное сообщение...',



                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),



                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),



                            ),



                          ),



                        ),



                        const SizedBox(width: 8),



                        _hasText



                            ? IconButton(



                          icon: Icon(Icons.send, color: theme.colorScheme.primary),



                          onPressed: _sendPrivateMessage,



                        )



                            : GestureDetector(



                          onLongPressStart: (_) => _startPrivateRecording(),



                          onLongPressEnd: (_) => _stopAndSendPrivateRecording(),



                          child: CircleAvatar(



                            backgroundColor: _isRecording ? Colors.red : theme.colorScheme.primary,



                            radius: 22,



                            child: const Icon(Icons.mic, color: Colors.white),



                          ),



                        ),



                      ],



                    ),



                  ),



              ],



            ),



            if (_showScrollDownButton)



              Positioned(



                right: 16,



                bottom: 80,



                child: FloatingActionButton.small(



                  onPressed: _scrollToBottom,



                  child: const Icon(Icons.arrow_downward),



                ),



              ),



          ],



        ),



      ),



    );



  }



}



