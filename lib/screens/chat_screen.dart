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



import 'package:package_info_plus/package_info_plus.dart';



import 'package:dio/dio.dart';



import 'package:open_filex/open_filex.dart';







import '../utils/helpers.dart';



import '../utils/theme_notifier.dart';



import '../utils/local_notifications.dart';



import '../utils/admin_helper.dart';



import '../widgets/user_avatar.dart';



import '../widgets/custom_painters.dart';



import '../widgets/media_players.dart';



import 'private_chat_screen.dart';



import 'profile_screen.dart';



import 'users_screen.dart';



import 'admin_panel_screen.dart';



import 'settings_screen.dart';



import 'dart:io';





const int kMaxAudioRecordDuration = 300;







class ZombieHandsPainter extends CustomPainter {



  final bool isMe;



  final Color skinColor;



  final Color clawColor;







  ZombieHandsPainter({



    required this.isMe,



    this.skinColor = const Color(0xFF3F5E3F),



    this.clawColor = const Color(0xFF1B261B),



  });







  @override



  void paint(Canvas canvas, Size size) {



    final skinPaint = Paint()



      ..color = skinColor



      ..style = PaintingStyle.fill;







    final clawPaint = Paint()



      ..color = clawColor



      ..style = PaintingStyle.fill;







    final shadowPaint = Paint()



      ..color = Colors.black.withOpacity(0.35)



      ..style = PaintingStyle.fill;







    if (isMe) {



      final baseX = size.width;



      final baseY = size.height * 0.35;



      _drawClawFinger(canvas, baseX, baseY, -18, 6.5, skinPaint, clawPaint, shadowPaint, true);



      _drawClawFinger(canvas, baseX, baseY + 13, -22, 7.5, skinPaint, clawPaint, shadowPaint, true);



      _drawClawFinger(canvas, baseX, baseY + 26, -17, 6.5, skinPaint, clawPaint, shadowPaint, true);



    } else {



      const baseX = 0.0;



      final baseY = size.height * 0.35;



      _drawClawFinger(canvas, baseX, baseY, 18, 6.5, skinPaint, clawPaint, shadowPaint, false);



      _drawClawFinger(canvas, baseX, baseY + 13, 22, 7.5, skinPaint, clawPaint, shadowPaint, false);



      _drawClawFinger(canvas, baseX, baseY + 26, 17, 6.5, skinPaint, clawPaint, shadowPaint, false);



    }



  }







  void _drawClawFinger(



      Canvas canvas,



      double x,



      double y,



      double length,



      double thickness,



      Paint skin,



      Paint claw,



      Paint shadow,



      bool flip,



      ) {



    final dir = flip ? -1.0 : 1.0;



    final path = Path();







    path.moveTo(x, y - thickness / 2);



    path.quadraticBezierTo(x + (length * 0.45), y - thickness * 0.8, x + (length * 0.55), y - thickness * 0.2);



    path.quadraticBezierTo(x + (length * 0.85), y - thickness * 0.6, x + length, y);



    path.quadraticBezierTo(x + (length * 0.5), y + thickness * 0.7, x, y + thickness / 2);



    path.close();







    canvas.drawPath(path.shift(Offset(dir * 1, 1.5)), shadow);



    canvas.drawPath(path, skin);







    final clawPath = Path();



    clawPath.moveTo(x + length - (dir * 3), y - (thickness * 0.35));



    clawPath.lineTo(x + length + (dir * 7), y + (thickness * 0.25));



    clawPath.lineTo(x + length - (dir * 1.5), y + (thickness * 0.5));



    clawPath.close();







    canvas.drawPath(clawPath, claw);



  }







  @override



  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;



}







class GeoPatternPainter extends CustomPainter {



  final Color color;



  GeoPatternPainter(this.color);







  @override



  void paint(Canvas canvas, Size size) {



    final paint = Paint()



      ..color = color



      ..strokeWidth = 1.0



      ..style = PaintingStyle.stroke;







    const double step = 45.0;



    for (double x = 0; x < size.width; x += step) {



      for (double y = 0; y < size.height; y += step) {



        canvas.drawRect(Rect.fromLTWH(x, y, step * 0.7, step * 0.7), paint);



        canvas.drawLine(Offset(x, y), Offset(x + step * 0.3, y + step * 0.3), paint);



      }



    }



  }







  @override



  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;



}







Widget buildTextWithMentions(



    BuildContext context,



    String text,



    bool isEdited, {



      bool isMe = false,



      void Function(String)? onMentionTap,



    }) {



  final RegExp regex = RegExp(r'(@[\wа-яА-ЯёЁ_]+)');



  List<InlineSpan> spans = [];







  final colorScheme = Theme.of(context).colorScheme;



  final isBloodTheme = appThemeNotifier.value == 'Бордовый (Кровь)' || appThemeNotifier.value == 'blood_crimson';



  final mentionColor = isBloodTheme ? Colors.white : colorScheme.primary;







  text.splitMapJoin(



    regex,



    onMatch: (Match match) {



      final fullMatch = match.group(0)!;



      final cleanNick = fullMatch.replaceFirst('@', '');







      spans.add(



        WidgetSpan(



          alignment: PlaceholderAlignment.middle,



          child: GestureDetector(



            onTap: onMentionTap != null ? () => onMentionTap(cleanNick) : null,



            child: Container(



              margin: const EdgeInsets.symmetric(horizontal: 2),



              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),



              decoration: BoxDecoration(



                color: mentionColor.withOpacity(0.16),



                borderRadius: BorderRadius.circular(6),



                border: Border.all(color: mentionColor.withOpacity(0.4), width: 1),



              ),



              child: Text(



                fullMatch,



                style: TextStyle(



                  color: mentionColor,



                  fontWeight: FontWeight.bold,



                  fontSize: 14,



                ),



              ),



            ),



          ),



        ),



      );



      return '';



    },



    onNonMatch: (String nonMatch) {



      spans.add(TextSpan(



        text: nonMatch,



        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16),



      ));



      return '';



    },



  );







  return Column(



    crossAxisAlignment: CrossAxisAlignment.start,



    children: [



      RichText(text: TextSpan(children: spans)),



      if (isEdited)



        const Padding(



          padding: EdgeInsets.only(top: 2.0),



          child: Text('(изменено)', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),



        ),



    ],



  );



}







class ChatScreen extends StatefulWidget {



  final String nickname;







  const ChatScreen({super.key, required this.nickname});







  @override



  State<ChatScreen> createState() => _ChatScreenState();



}







class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {



  final TextEditingController _messageController = TextEditingController();



  final TextEditingController _searchController = TextEditingController();



  final ScrollController _scrollController = ScrollController();



  final ImagePicker _picker = ImagePicker();



  final AudioRecorder _audioRecorder = AudioRecorder();







  Stream<QuerySnapshot>? _messagesStream;



  StreamSubscription? _usersSubscription;



  List<Map<String, dynamic>> _allUsers = [];



  List<Map<String, dynamic>> _filteredUsers = [];







  int _messageLimit = 40;



  bool _isLoadingMore = false;



  Timestamp? _userCreatedAt;







  Timer? _verificationTimer;



  Timer? _verifiedBannerTimer;



  Timer? _recordDurationTimer;



  Timer? _typingTimer;



  Timer? _announcementRefreshTimer;



  int _recordDuration = 0;



  TapDownDetails? _tapDownDetails;







  bool _isRecording = false;



  bool _isUploading = false;



  bool _hasText = false;



  bool _isTyping = false;



  bool _showScrollDownButton = false;



  bool _showVerifiedBanner = false;



  bool _isSearching = false;



  String _searchKeyword = '';







  bool _showMentionSuggestions = false;



  int _mentionStartIndex = -1;







  String? _highlightedMessageId;



  List<DocumentSnapshot> _currentLoadedDocs = [];



  Map<String, dynamic> _myMeta = {'role': 'member', 'prefix': '', 'prefixColor': 0};







  Map<String, dynamic>? _replyMessage;



  String? _editingMessageId;



  bool _isSelectionMode = false;



  final Set<String> _selectedMessageIds = {};



  final Map<String, DocumentSnapshot> _selectedDocs = {};







  final Map<String, String> _translations = {};



  final Set<String> _translatingIds = {};



  final Set<String> _expandedMessageIds = {};







  DateTime? _lastMessageSentTime;



  String? _lastSentMessageText;







  @override



  void initState() {



    super.initState();







    LocalNotifications.startListening(widget.nickname);



    WidgetsBinding.instance.addObserver(this);



    _updateOnlineStatus(true);



    _loadUserPermissions();



    _loadAllianceUsers();



    _initUserDataAndStream();







    checkForUpdate(context);







    _announcementRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {



      if (mounted) setState(() {});



    });







    _messageController.addListener(_handleMessageInput);







    _scrollController.addListener(() {



      if (_scrollController.hasClients) {



        final shouldShow = _scrollController.offset > 250;



        if (shouldShow != _showScrollDownButton) {



          setState(() {



            _showScrollDownButton = shouldShow;



          });



        }







        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {



          _loadMoreMessages();



        }



      }



    });



  }







  void _loadAllianceUsers() {



    _usersSubscription = FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {



      if (mounted) {



        _allUsers = snapshot.docs.map((d) {



          final data = d.data();



          return {



            'id': d.id,



            'nickname': data['nickname'] ?? 'Без имени',



            'avatarUrl': data['avatarUrl'],



            'prefix': data['prefix'] ?? '',



            'prefixColor': data['prefixColor'] ?? 0,



            'role': data['role'] ?? 'member',



          };



        }).toList();



      }



    });



  }







  Future<void> _openProfileByNickname(String nick) async {



    if (nick.toLowerCase() == 'all') {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(content: Text('Это общий вызов участников альянса!')),



      );



      return;



    }







    try {



      final query = await FirebaseFirestore.instance



          .collection('users')



          .where('nickname', isEqualTo: nick)



          .limit(1)



          .get();







      if (query.docs.isNotEmpty && mounted) {



        Navigator.push(



          context,



          MaterialPageRoute(



            builder: (_) => ProfileScreen(userId: query.docs.first.id),



          ),



        );



      } else if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          SnackBar(content: Text('Боец $nick не найден')),



        );



      }



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          SnackBar(content: Text('Ошибка перехода: $e')),



        );



      }



    }



  }







  void _handleMessageInput() {



    final text = _messageController.text;



    final hasTextNow = text.trim().isNotEmpty;



    if (hasTextNow != _hasText) {



      setState(() {



        _hasText = hasTextNow;



      });



    }







    final selection = _messageController.selection;



    if (selection.baseOffset > 0 && selection.baseOffset <= text.length) {



      final textBeforeCursor = text.substring(0, selection.baseOffset);



      final match = RegExp(r'@([a-zA-Zа-яА-Я0-9_]*)$').firstMatch(textBeforeCursor);



      if (match != null) {



        final query = match.group(1) ?? '';



        _mentionStartIndex = match.start;



        _filterMentions(query);



      } else {



        if (_showMentionSuggestions) {



          setState(() => _showMentionSuggestions = false);



        }



      }



    } else {



      if (_showMentionSuggestions) {



        setState(() => _showMentionSuggestions = false);



      }



    }







    if (!_isRecording && !_isUploading) {



      if (!_isTyping && hasTextNow) {



        _isTyping = true;



        _setUserAction('печатает...');



      }







      _typingTimer?.cancel();



      _typingTimer = Timer(const Duration(seconds: 2), () {



        if (_isTyping) {



          _isTyping = false;



          _setUserAction(null);



        }



      });



    }



  }







  void _filterMentions(String query) {



    final q = query.toLowerCase();



    final isModer = AdminHelper.hasModerRights(_myMeta['role']);



    List<Map<String, dynamic>> results = [];







    if (isModer && ('all'.startsWith(q) || q.isEmpty)) {



      results.add({



        'nickname': 'all',



        'isAll': true,



        'prefix': 'ВСЕ',



        'prefixColor': 0xFFFF9800,



      });



    }







    final matched = _allUsers.where((u) {



      final nick = (u['nickname'] as String).toLowerCase();



      return nick.contains(q) && u['nickname'] != widget.nickname;



    }).toList();







    results.addAll(matched);







    setState(() {



      _filteredUsers = results;



      _showMentionSuggestions = results.isNotEmpty;



    });



  }







  void _selectMention(String nick) {



    final text = _messageController.text;



    final selection = _messageController.selection;



    if (_mentionStartIndex >= 0 && _mentionStartIndex <= text.length) {



      final textBefore = text.substring(0, _mentionStartIndex);



      final textAfter = selection.baseOffset <= text.length ? text.substring(selection.baseOffset) : '';



      final replacement = '@$nick ';



      final newText = '$textBefore$replacement$textAfter';



      final newCursorPosition = textBefore.length + replacement.length;







      _messageController.value = TextEditingValue(



        text: newText,



        selection: TextSelection.collapsed(offset: newCursorPosition),



      );



    }



    setState(() {



      _showMentionSuggestions = false;



    });



  }







  Future<void> _loadUserPermissions() async {



    final meta = await AdminHelper.getCurrentUserMeta();



    if (mounted) {



      setState(() {



        _myMeta = meta;



      });



    }



  }







  Future<void> _setUserAction(String? actionText) async {



    final user = FirebaseAuth.instance.currentUser;



    if (user == null) return;







    await FirebaseFirestore.instance.collection('typing_status').doc(user.uid).set({



      'action': actionText ?? '',



      'nickname': widget.nickname,



      'updatedAt': FieldValue.serverTimestamp(),



    }, SetOptions(merge: true));



  }







  void _triggerVerifiedNotification() {



    setState(() {



      _showVerifiedBanner = true;



    });







    _verifiedBannerTimer?.cancel();



    _verifiedBannerTimer = Timer(const Duration(minutes: 3), () {



      if (mounted) {



        setState(() {



          _showVerifiedBanner = false;



        });



      }



    });



  }







  Future<void> _initUserDataAndStream() async {



    final user = FirebaseAuth.instance.currentUser;



    if (user != null) {



      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();



      if (doc.exists && mounted) {



        final data = doc.data() as Map<String, dynamic>;



        _userCreatedAt = data['createdAt'] as Timestamp?;



        final bool welcomed = data['welcomed'] ?? false;



        final String name = data['name'] ?? widget.nickname;







        if (user.emailVerified && !welcomed) {



          await _sendSystemWelcomeMessage(name, user.uid);



          _triggerVerifiedNotification();



        } else if (!user.emailVerified) {



          _startEmailVerificationCheck(name);



        }



      }



    }



    _initStream();



  }







  Future<void> _sendSystemWelcomeMessage(String userName, String uid) async {



    await FirebaseFirestore.instance.collection('users').doc(uid).update({



      'welcomed': true,



    });







    await FirebaseFirestore.instance.collection('messages').add({



      'type': 'system',



      'text': 'Уважаемый $userName, добро пожаловать в чат альянса [vPv] Волчий Протокол. Просим соблюдать правила чата и альянса. Не устраивать ругань, национальных, межрассовых, религиозных и политических ссор. Шутки можно, но все в меру. Администрация в праве делать что ей вздумается. Рады вас приветствовать!!!',



      'sender': 'Система',



      'senderId': 'system',



      'timestamp': FieldValue.serverTimestamp(),



      'reactions': {},



    });



  }







  void _initStream() {



    Query query = FirebaseFirestore.instance.collection('messages');







    if (_userCreatedAt != null) {



      query = query.where('timestamp', isGreaterThanOrEqualTo: _userCreatedAt);



    }







    setState(() {



      _messagesStream = query



          .orderBy('timestamp', descending: true)



          .limit(_messageLimit)



          .snapshots();



    });



  }







  void _loadMoreMessages() {



    setState(() {



      _isLoadingMore = true;



      _messageLimit += 30;



      _initStream();



    });







    Future.delayed(const Duration(milliseconds: 500), () {



      if (mounted) setState(() => _isLoadingMore = false);



    });



  }







  @override



  void didChangeAppLifecycleState(AppLifecycleState state) {



    if (state == AppLifecycleState.resumed) {



      _updateOnlineStatus(true);



      _loadUserPermissions();



    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.hidden) {



      _updateOnlineStatus(false);



      _setUserAction(null);



    }



  }







  void _updateOnlineStatus(bool isOnline) {



    final uid = FirebaseAuth.instance.currentUser?.uid;



    if (uid != null) {



      FirebaseFirestore.instance.collection('users').doc(uid).update({



        'isOnline': isOnline,



      });



    }



  }







  void _startEmailVerificationCheck(String userName) {



    final user = FirebaseAuth.instance.currentUser;



    if (user != null && !user.emailVerified) {



      _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {



        await user.reload();



        final refreshedUser = FirebaseAuth.instance.currentUser;



        if (refreshedUser != null && refreshedUser.emailVerified) {



          timer.cancel();



          await _sendSystemWelcomeMessage(userName, refreshedUser.uid);



          if (mounted) {



            _triggerVerifiedNotification();



          }



        }



      });



    }



  }







  @override



  void dispose() {



    WidgetsBinding.instance.removeObserver(this);



    _usersSubscription?.cancel();



    _updateOnlineStatus(false);



    _setUserAction(null);



    _verificationTimer?.cancel();



    _verifiedBannerTimer?.cancel();



    _announcementRefreshTimer?.cancel();



    _recordDurationTimer?.cancel();



    _typingTimer?.cancel();



    _messageController.removeListener(_handleMessageInput);



    _messageController.dispose();



    _searchController.dispose();



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







  void _scrollToPinnedMessage(String messageId) {



    final index = _currentLoadedDocs.indexWhere((doc) => doc.id == messageId);



    if (index != -1) {



      final approxOffset = (index * 75.0).clamp(0.0, _scrollController.position.maxScrollExtent);



      _scrollController.animateTo(



        approxOffset,



        duration: const Duration(milliseconds: 500),



        curve: Curves.easeInOut,



      );



      setState(() {



        _highlightedMessageId = messageId;



      });



      Future.delayed(const Duration(seconds: 2), () {



        if (mounted) setState(() => _highlightedMessageId = null);



      });



    } else {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(content: Text('Сообщение находится дальше в истории. Прокрутите чат вверх.')),



      );



    }



  }







  Future<bool> _canUserInteract() async {



    final user = FirebaseAuth.instance.currentUser;



    if (user != null) {



      await user.reload();



      if (!user.emailVerified) {



        if (mounted) {



          ScaffoldMessenger.of(context).showSnackBar(



            const SnackBar(content: Text('Подтвердите ваш Email! Проверьте почту и папку СПАМ.')),



          );



        }



        return false;



      }







      final meta = await AdminHelper.getCurrentUserMeta();



      _myMeta = meta;







      if (meta['isBanned'] == true) {



        final Timestamp? until = meta['bannedUntil'];



        if (until == null || until.toDate().isAfter(DateTime.now())) {



          if (mounted) {



            ScaffoldMessenger.of(context).showSnackBar(



              SnackBar(



                backgroundColor: Colors.red,



                content: Text('Вы заблокированы! Причина: ${meta['banReason']}'),



              ),



            );



          }



          return false;



        }



      }







      if (meta['isMuted'] == true) {



        final Timestamp? until = meta['mutedUntil'];



        if (until != null && until.toDate().isAfter(DateTime.now())) {



          final remaining = until.toDate().difference(DateTime.now());



          final minutes = remaining.inMinutes + 1;



          if (mounted) {



            ScaffoldMessenger.of(context).showSnackBar(



              SnackBar(



                backgroundColor: Colors.orange,



                content: Text('У вас кляп! Осталось ждать: $minutes мин. Не пытайся его выплюнуть!'),



              ),



            );



          }



          return false;



        }



      }



    }



    return true;



  }







  Future<void> _sendMessage() async {



    if (!await _canUserInteract()) return;







    final rawText = _messageController.text;



    final text = rawText.trim();



    if (text.isEmpty) return;







    if (rawText.length > 2500) {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(



          backgroundColor: Colors.red,



          content: Text('Сообщение слишком длинное (максимум 2500 символов)!'),



        ),



      );



      return;



    }







    final now = DateTime.now();



    if (_lastMessageSentTime != null &&



        now.difference(_lastMessageSentTime!).inMilliseconds < 1200) {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(



          backgroundColor: Colors.orange,



          content: Text('Не так быстро! Подождите секунду перед отправкой.'),



        ),



      );



      return;



    }







    if (_lastSentMessageText == text &&



        _lastMessageSentTime != null &&



        now.difference(_lastMessageSentTime!).inSeconds < 4) {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(



          backgroundColor: Colors.orange,



          content: Text('Не отправляйте одинаковые сообщения подряд!'),



        ),



      );



      return;



    }







    _lastMessageSentTime = now;



    _lastSentMessageText = text;







    final user = FirebaseAuth.instance.currentUser;



    List<String> mentionedUsers = extractMentions(text);







    if (!AdminHelper.hasModerRights(_myMeta['role'])) {



      mentionedUsers.removeWhere((m) => m.toLowerCase() == 'all' || m.toLowerCase() == '@all');



    }







    _setUserAction(null);







    if (_editingMessageId != null) {



      await FirebaseFirestore.instance.collection('messages').doc(_editingMessageId).update({



        'text': text,



        'isEdited': true,



        'editedAt': FieldValue.serverTimestamp(),



        'mentions': mentionedUsers,



      });



    } else {



      await FirebaseFirestore.instance.collection('messages').add({



        'type': 'text',



        'text': text,



        'sender': widget.nickname,



        'senderId': user?.uid ?? '',



        'senderPrefix': _myMeta['prefix'] ?? '',



        'senderPrefixColor': _myMeta['prefixColor'] ?? 0,



        'timestamp': FieldValue.serverTimestamp(),



        'reactions': {},



        'replyTo': _replyMessage,



        'mentions': mentionedUsers,



      });



    }







    _messageController.clear();



    setState(() {



      _replyMessage = null;



      _editingMessageId = null;



      _showMentionSuggestions = false;



    });



    _scrollToBottom();



  }







  Future<void> _pickAndUploadMedia(bool isVideo) async {



    if (_isUploading) return;



    if (!await _canUserInteract()) return;







    final XFile? file = isVideo



        ? await _picker.pickVideo(source: ImageSource.gallery)



        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);







    if (file == null) return;







    setState(() { _isUploading = true; });



    await _setUserAction(isVideo ? 'загружает видео...' : 'загружает фотографию...');







    try {



      final bytes = await file.readAsBytes();



      final user = FirebaseAuth.instance.currentUser;



      final ext = file.name.split('.').last;



      final path = 'media/${DateTime.now().millisecondsSinceEpoch}_${user?.uid ?? 'anon'}.$ext';







      final storage = Supabase.instance.client.storage.from('chat-media');



      await storage.uploadBinary(



        path,



        bytes,



        fileOptions: FileOptions(contentType: isVideo ? 'video/$ext' : 'image/$ext', upsert: true),



      );



      final downloadUrl = storage.getPublicUrl(path);







      await FirebaseFirestore.instance.collection('messages').add({



        'type': isVideo ? 'video' : 'image',



        'mediaUrl': downloadUrl,



        'text': '',



        'sender': widget.nickname,



        'senderId': user?.uid ?? '',



        'senderPrefix': _myMeta['prefix'] ?? '',



        'senderPrefixColor': _myMeta['prefixColor'] ?? 0,



        'timestamp': FieldValue.serverTimestamp(),



        'reactions': {},



        'replyTo': _replyMessage,



      });







      setState(() {



        _replyMessage = null;



      });



      _scrollToBottom();



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));



      }



    } finally {



      await _setUserAction(null);



      if (mounted) setState(() { _isUploading = false; });



    }



  }







  void _showAttachMenu() {



    showModalBottomSheet(



      context: context,



      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),



      builder: (context) {



        return SafeArea(



          child: Wrap(



            children: [



              ListTile(



                leading: Icon(Icons.image, color: Theme.of(context).colorScheme.primary),



                title: const Text('Фотография'),



                onTap: () {



                  Navigator.pop(context);



                  _pickAndUploadMedia(false);



                },



              ),



              ListTile(



                leading: Icon(Icons.videocam, color: Theme.of(context).colorScheme.secondary),



                title: const Text('Видеозапись'),



                onTap: () {



                  Navigator.pop(context);



                  _pickAndUploadMedia(true);



                },



              ),



            ],



          ),



        );



      },



    );



  }







  Future<void> _startRecording() async {



    if (_isRecording || _isUploading) return;



    if (!await _canUserInteract()) return;







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







        await _setUserAction('записывает голосовое сообщение...');







        _recordDuration = 0;



        _recordDurationTimer?.cancel();



        _recordDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {



          if (mounted) {



            setState(() {



              _recordDuration++;



            });







            if (_recordDuration >= kMaxAudioRecordDuration) {



              timer.cancel();



              _stopAndSendRecording();



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



      await _setUserAction(null);



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка микрофона: $e')));



      }



    }



  }







  Future<void> _stopAndSendRecording() async {



    if (!_isRecording) return;



    _recordDurationTimer?.cancel();







    try {



      final path = await _audioRecorder.stop();



      setState(() {



        _isRecording = false;



        _isUploading = true;



      });







      await _setUserAction('загружает голосовое сообщение...');







      if (path != null && _recordDuration > 0) {



        final xfile = XFile(path);



        final bytes = await xfile.readAsBytes();



        final user = FirebaseAuth.instance.currentUser;



        final storagePath = 'voices/${DateTime.now().millisecondsSinceEpoch}_${user?.uid ?? 'anon'}.m4a';







        final storage = Supabase.instance.client.storage.from('chat-media');



        await storage.uploadBinary(



          storagePath,



          bytes,



          fileOptions: const FileOptions(contentType: 'audio/m4a', upsert: true),



        );



        final downloadUrl = storage.getPublicUrl(storagePath);







        await FirebaseFirestore.instance.collection('messages').add({



          'type': 'audio',



          'mediaUrl': downloadUrl,



          'text': '',



          'sender': widget.nickname,



          'senderId': user?.uid ?? '',



          'senderPrefix': _myMeta['prefix'] ?? '',



          'senderPrefixColor': _myMeta['prefixColor'] ?? 0,



          'timestamp': FieldValue.serverTimestamp(),



          'reactions': {},



          'replyTo': _replyMessage,



        });







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



      await _setUserAction(null);



      if (mounted) setState(() { _isUploading = false; });



    }



  }







  Future<void> _resendVerificationEmail() async {



    try {



      final user = FirebaseAuth.instance.currentUser;



      await user?.sendEmailVerification();



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          const SnackBar(content: Text('Письмо отправлено повторно! Проверьте папку СПАМ.')),



        );



      }



    } catch (e) {



      if (mounted) {



        ScaffoldMessenger.of(context).showSnackBar(



          SnackBar(content: Text('Ошибка отправки: $e')),



        );



      }



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







  Future<void> _selectReaction(String messageId, String emoji, Map<String, dynamic>? currentReactions) async {



    final user = FirebaseAuth.instance.currentUser;



    if (user == null) return;



    final userId = user.uid;







    Map<String, dynamic> reactions = currentReactions != null ? Map.from(currentReactions) : {};







    bool wasAlreadySelected = false;



    if (reactions.containsKey(emoji) && (reactions[emoji] as List<dynamic>).contains(userId)) {



      wasAlreadySelected = true;



    }







    reactions.forEach((key, value) {



      List<dynamic> usersList = List.from(value);



      if (usersList.contains(userId)) {



        usersList.remove(userId);



        reactions[key] = usersList;



      }



    });







    reactions.removeWhere((key, value) => (value as List<dynamic>).isEmpty);







    if (!wasAlreadySelected) {



      List<dynamic> targetList = reactions[emoji] != null ? List.from(reactions[emoji]) : [];



      targetList.add(userId);



      reactions[emoji] = targetList;



    }







    await FirebaseFirestore.instance.collection('messages').doc(messageId).update({



      'reactions': reactions,



    });



  }







  void _showCompactReactionPopup(BuildContext context, String messageId, Map<String, dynamic>? currentReactions, TapDownDetails details) async {



    final position = details.globalPosition;



    const emojis = ['👍', '🔥', '💩', '😂', '😢', '🎉'];







    final selectedEmoji = await showMenu<String>(



      context: context,



      elevation: 6,



      color: Theme.of(context).dialogBackgroundColor,



      surfaceTintColor: Colors.transparent,



      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),



      position: RelativeRect.fromRect(



        Rect.fromLTWH(position.dx - 40, position.dy - 55, 0, 0),



        Offset.zero & MediaQuery.of(context).size,



      ),



      items: [



        PopupMenuItem<String>(



          enabled: true,



          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),



          child: Row(



            mainAxisSize: MainAxisSize.min,



            mainAxisAlignment: MainAxisAlignment.spaceEvenly,



            children: emojis.map((emoji) {



              return InkWell(



                borderRadius: BorderRadius.circular(20),



                onTap: () {



                  Navigator.pop(context, emoji);



                },



                child: Padding(



                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),



                  child: Text(



                    emoji,



                    style: const TextStyle(fontSize: 26),



                  ),



                ),



              );



            }).toList(),



          ),



        ),



      ],



    );







    if (selectedEmoji != null) {



      _selectReaction(messageId, selectedEmoji, currentReactions);



    }



  }







  void _showCompactContextMenu(BuildContext context, DocumentSnapshot doc, Offset position) async {



    final msg = doc.data() as Map<String, dynamic>;



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    final isMe = msg['senderId'] == currentUserId;



    final mediaUrl = msg['mediaUrl'] as String?;



    final type = msg['type'] ?? 'text';



    final theme = Theme.of(context);



    final isModer = AdminHelper.hasModerRights(_myMeta['role']);







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



        if (isModer)



          const PopupMenuItem(



            value: 'pin',



            child: Row(



              children: [



                Icon(Icons.push_pin, color: Colors.amber, size: 20),



                SizedBox(width: 12),



                Text('Закрепить'),



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



        if (isMe || isModer)



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



          'sender': msg['sender'] ?? 'Аноним',



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



    } else if (selected == 'pin') {



      await AdminHelper.pinMessage(



        messageId: doc.id,



        text: msg['text'] ?? '',



        sender: msg['sender'] ?? 'Аноним',



        type: msg['type'] ?? 'text',



        pinnedBy: widget.nickname,



      );



      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сообщение закреплено')));



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



      await doc.reference.delete();



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



                          'sender': widget.nickname,



                          'senderId': currentUid ?? '',



                          'timestamp': FieldValue.serverTimestamp(),



                          'reactions': {},



                          'replyTo': m['replyTo'],



                          'forwardedFrom': m['sender'] ?? 'Аноним',



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



                            'forwardedFrom': m['sender'] ?? 'Аноним',



                          });



                        }







                        await FirebaseFirestore.instance



                            .collection('chats_meta')



                            .doc('${targetRoomId}_$targetId')



                            .set({'isRead': false, 'recipientId': targetId}, SetOptions(merge: true));







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



    final isModer = AdminHelper.hasModerRights(_myMeta['role']);



    int deletedCount = 0;







    for (var doc in _selectedDocs.values) {



      final data = doc.data() as Map<String, dynamic>;



      if (data['senderId'] == currentUserId || isModer) {



        await doc.reference.delete();



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



        SnackBar(content: Text('Удалено сообщений: $deletedCount')),



      );



    }



  }







  void _showFullScreenImage(BuildContext context, String imageUrl) {



    showDialog(



      context: context,



      builder: (context) => Dialog(



        backgroundColor: Colors.black.withOpacity(0.95),



        insetPadding: const EdgeInsets.all(10),



        child: Stack(



          children: [



            Center(



              child: InteractiveViewer(



                panEnabled: true,



                minScale: 0.5,



                maxScale: 4.0,



                child: Image.network(imageUrl, fit: BoxFit.contain),



              ),



            ),



            Positioned(



              top: 10,



              right: 10,



              child: Row(



                children: [



                  IconButton(



                    icon: const Icon(Icons.download, color: Colors.white, size: 28),



                    tooltip: 'Скачать фото',



                    onPressed: () => downloadMediaFile(context, imageUrl),



                  ),



                  IconButton(



                    icon: const Icon(Icons.close, color: Colors.white, size: 30),



                    onPressed: () => Navigator.pop(context),



                  ),



                ],



              ),



            ),



          ],



        ),



      ),



    );



  }







  Future<void> _openChatWithUser(BuildContext context, String senderName, String senderId) async {



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    if (senderId.isEmpty || senderId == 'system') return;







    if (senderId != currentUserId) {



      if (context.mounted) {



        Navigator.push(



          context,



          MaterialPageRoute(



            builder: (context) => PrivateChatScreen(



              peerUserId: senderId,



              peerNickname: senderName,



            ),



          ),



        );



      }



    }



  }







  Future<void> _showAvatarDialog(BuildContext context, String senderName, String senderId) async {



    if (senderId == 'system' || senderId.isEmpty) return;







    if (context.mounted) {



      showDialog(



        context: context,



        builder: (context) => AvatarDetailDialog(userId: senderId, nickname: senderName),



      );



    }



  }







  Widget _buildMessageContent(Map<String, dynamic> msg, bool isMe, String messageId) {



    final type = msg['type'] ?? 'text';



    final text = msg['text'] ?? '';



    final mediaUrl = msg['mediaUrl'] ?? '';



    final isEdited = msg['isEdited'] ?? false;







    if (type == 'image') {



      return GestureDetector(



        onTap: () => _showFullScreenImage(context, mediaUrl),



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







    final bool isLong = text.length > 500;



    final bool isExpanded = _expandedMessageIds.contains(messageId);



    final String displayText = (isLong && !isExpanded)



        ? '${text.substring(0, 500)}...'



        : text;







    return Column(



      crossAxisAlignment: CrossAxisAlignment.start,



      children: [



        buildTextWithMentions(



          context,



          displayText,



          isEdited,



          isMe: isMe,



          onMentionTap: _openProfileByNickname,



        ),



        if (isLong)



          InkWell(



            onTap: () {



              setState(() {



                if (isExpanded) {



                  _expandedMessageIds.remove(messageId);



                } else {



                  _expandedMessageIds.add(messageId);



                }



              });



            },



            child: Padding(



              padding: const EdgeInsets.only(top: 4.0),



              child: Row(



                mainAxisSize: MainAxisSize.min,



                children: [



                  Text(



                    isExpanded ? 'Свернуть' : 'Читать полностью',



                    style: TextStyle(



                      fontSize: 12,



                      fontWeight: FontWeight.bold,



                      color: Theme.of(context).colorScheme.primary,



                    ),



                  ),



                  Icon(



                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,



                    size: 16,



                    color: Theme.of(context).colorScheme.primary,



                  ),



                ],



              ),



            ),



          ),



      ],



    );



  }







  @override



  Widget build(BuildContext context) {



    final currentUserId = FirebaseAuth.instance.currentUser?.uid;



    final user = FirebaseAuth.instance.currentUser;



    final bool isEmailVerified = user?.emailVerified ?? true;



    final theme = Theme.of(context);



    final isModer = AdminHelper.hasModerRights(_myMeta['role']);







    final currentTheme = appThemeNotifier.value;



    final bool isBloodTheme = currentTheme == 'Бордовый (Кровь)' || currentTheme == 'blood_crimson';



    final bool isZombieTheme = currentTheme == 'Зомби' || currentTheme == 'zombie_horde';



    final bool isGreyTheme = currentTheme == 'Серый узор' || currentTheme == 'grey_pattern';



    final bool isDarkGeoTheme = currentTheme == 'Тёмная сталь' || currentTheme == 'dark_geo';







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



      resizeToAvoidBottomInset: true,



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



        title: _isSearching



            ? TextField(



          controller: _searchController,



          autofocus: true,



          style: const TextStyle(color: Colors.white),



          decoration: const InputDecoration(



            hintText: 'Поиск по тексту сообщений...',



            hintStyle: TextStyle(color: Colors.white70),



            border: InputBorder.none,



          ),



          onChanged: (val) => setState(() => _searchKeyword = val.trim().toLowerCase()),



        )



            : StreamBuilder<QuerySnapshot>(



          stream: FirebaseFirestore.instance.collection('typing_status').snapshots(),



          builder: (context, typingSnapshot) {



            String typingText = '';



            if (typingSnapshot.hasData) {



              final activeActions = typingSnapshot.data!.docs.where((doc) {



                final data = doc.data() as Map<String, dynamic>;



                final action = data['action'] ?? '';



                final uid = doc.id;



                return action.toString().isNotEmpty && uid != currentUserId;



              }).map((doc) {



                final data = doc.data() as Map<String, dynamic>;



                return '${data['nickname']} ${data['action']}';



              }).toList();







              if (activeActions.isNotEmpty) {



                typingText = activeActions.join(', ');



              }



            }







            return StreamBuilder<QuerySnapshot>(



              stream: FirebaseFirestore.instance.collection('users').where('isOnline', isEqualTo: true).snapshots(),



              builder: (context, onlineSnapshot) {



                int onlineCount = onlineSnapshot.hasData ? onlineSnapshot.data!.docs.length : 1;



                return Column(



                  children: [



                    const Text('Общий чат', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),



                    Text(



                      typingText.isNotEmpty ? typingText : 'Онлайн: $onlineCount',



                      style: TextStyle(



                        fontSize: 12,



                        color: typingText.isNotEmpty ? Colors.orangeAccent : Colors.green,



                        fontWeight: typingText.isNotEmpty ? FontWeight.bold : FontWeight.normal,



                      ),



                    ),



                  ],



                );



              },



            );



          },



        ),



        centerTitle: true,



        actions: [



          IconButton(



            icon: Icon(_isSearching ? Icons.close : Icons.search),



            onPressed: () {



              setState(() {



                _isSearching = !_isSearching;



                if (!_isSearching) {



                  _searchController.clear();



                  _searchKeyword = '';



                }



              });



            },



          ),



          if (isModer)



            IconButton(



              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),



              tooltip: 'Панель управления альянса',



              onPressed: () {



                Navigator.push(



                  context,



                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),



                );



              },



            ),



          StreamBuilder<QuerySnapshot>(



            stream: FirebaseFirestore.instance



                .collection('chats_meta')



                .where('recipientId', isEqualTo: currentUserId)



                .where('isRead', isEqualTo: false)



                .snapshots(),



            builder: (context, snapshot) {



              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;



              return Badge(



                isLabelVisible: unreadCount > 0,



                label: Text('$unreadCount'),



                child: IconButton(



                  icon: const Icon(Icons.people, size: 28),



                  onPressed: () {



                    Navigator.push(



                      context,



                      MaterialPageRoute(builder: (context) => const UsersScreen()),



                    );



                  },



                ),



              );



            },



          ),



          IconButton(



            icon: const Icon(Icons.person, size: 28),



            tooltip: 'Профиль',



            onPressed: () {



              if (currentUserId != null) {



                Navigator.push(



                  context,



                  MaterialPageRoute(builder: (context) => ProfileScreen(userId: currentUserId)),



                );



              }



            },



          ),



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



        ],



      ),



      body: CustomPaint(



        painter: bgPainter,



        child: Stack(



          children: [



            Column(



              children: [



                StreamBuilder<DocumentSnapshot>(



                  stream: FirebaseFirestore.instance.collection('chats_meta').doc('global_pin').snapshots(),



                  builder: (context, pinSnapshot) {



                    if (pinSnapshot.hasData && pinSnapshot.data!.exists) {



                      final pinData = pinSnapshot.data!.data() as Map<String, dynamic>;



                      final pinMessageId = pinData['messageId'] ?? '';



                      final pinSender = pinData['sender'] ?? 'Аноним';



                      final pinType = pinData['type'] ?? 'text';



                      String pinText = pinData['text'] ?? '';



                      if (pinType == 'image') pinText = '🖼 Фотография';



                      if (pinType == 'video') pinText = '🎥 Видеозапись';



                      if (pinType == 'audio') pinText = '🎤 Голосовое сообщение';







                      return Container(



                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),



                        decoration: BoxDecoration(



                          color: theme.colorScheme.primary.withOpacity(0.12),



                          border: Border(bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3), width: 1)),



                        ),



                        child: Row(



                          children: [



                            const Icon(Icons.push_pin, color: Colors.amber, size: 20),



                            const SizedBox(width: 8),



                            Expanded(



                              child: InkWell(



                                onTap: () => _scrollToPinnedMessage(pinMessageId),



                                child: Column(



                                  crossAxisAlignment: CrossAxisAlignment.start,



                                  children: [



                                    Text(



                                      'Закреплено ($pinSender)',



                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.primary),



                                    ),



                                    Text(



                                      pinText,



                                      maxLines: 1,



                                      overflow: TextOverflow.ellipsis,



                                      style: const TextStyle(fontSize: 12),



                                    ),



                                  ],



                                ),



                              ),



                            ),



                            if (isModer)



                              IconButton(



                                icon: const Icon(Icons.close, size: 18),



                                tooltip: 'Открепить',



                                onPressed: () => AdminHelper.unpinMessage(),



                              ),



                          ],



                        ),



                      );



                    }



                    return const SizedBox.shrink();



                  },



                ),



                if (!isEmailVerified)



                  Container(



                    color: Colors.amber[100],



                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),



                    child: Row(



                      children: [



                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),



                        const SizedBox(width: 8),



                        const Expanded(



                          child: Text(



                            'Проверьте почту и папку СПАМ (идёт проверка...)',



                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),



                          ),



                        ),



                        TextButton(



                          onPressed: _resendVerificationEmail,



                          child: const Text('Повторить', style: TextStyle(fontSize: 12)),



                        ),



                      ],



                    ),



                  )



                else if (_showVerifiedBanner)



                  Container(



                    color: Colors.green.shade700,



                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),



                    child: Row(



                      children: [



                        const Icon(Icons.verified, color: Colors.white, size: 20),



                        const SizedBox(width: 10),



                        const Expanded(



                          child: Text(



                            'Email успешно подтверждён! Добро пожаловать в альянс [vPv].',



                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),



                          ),



                        ),



                        IconButton(



                          icon: const Icon(Icons.close, color: Colors.white70, size: 18),



                          onPressed: () {



                            setState(() => _showVerifiedBanner = false);



                            _verifiedBannerTimer?.cancel();



                          },



                        ),



                      ],



                    ),



                  ),



                if (_isUploading)



                  const LinearProgressIndicator(minHeight: 3),



                Expanded(



                  child: _messagesStream == null



                      ? const Center(child: CircularProgressIndicator())



                      : StreamBuilder<QuerySnapshot>(



                    stream: _messagesStream,



                    builder: (context, snapshot) {



                      if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingMore) {



                        return const Center(child: CircularProgressIndicator());



                      }







                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {



                        return const Center(child: Text('Сообщений пока нет. Напиши первым!'));



                      }







                      _currentLoadedDocs = snapshot.data!.docs;



                      var messages = _currentLoadedDocs;







                      if (_searchKeyword.isNotEmpty) {



                        messages = messages.where((doc) {



                          final data = doc.data() as Map<String, dynamic>;



                          final text = (data['text'] ?? '').toString().toLowerCase();



                          final sender = (data['sender'] ?? '').toString().toLowerCase();



                          return text.contains(_searchKeyword) || sender.contains(_searchKeyword);



                        }).toList();



                      }







                      return ListView.builder(



                        key: const PageStorageKey('global_chat_list'),



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







                          final messageDoc = messages[index];



                          final msg = messageDoc.data() as Map<String, dynamic>;



                          final sender = msg['sender'] ?? 'Аноним';



                          final senderId = msg['senderId'] ?? '';



                          final isSystem = senderId == 'system' || msg['type'] == 'system';



                          final isPunishment = msg['subType'] == 'punishment';



                          final reactions = msg['reactions'] as Map<String, dynamic>?;



                          final replyTo = msg['replyTo'] as Map<String, dynamic>?;



                          final forwardedFrom = msg['forwardedFrom'] as String?;



                          final timestamp = msg['timestamp'];







                          final senderPrefix = msg['senderPrefix'] as String? ?? '';



                          final senderPrefixColor = msg['senderPrefixColor'] as int? ?? 0;







                          bool isMe = senderId == currentUserId;



                          bool isSelected = _selectedMessageIds.contains(messageDoc.id);



                          bool isHighlighted = _highlightedMessageId == messageDoc.id;







                          if (isSystem) {



                            if (timestamp != null && timestamp is Timestamp) {



                              final diffSeconds = DateTime.now().difference(timestamp.toDate()).inSeconds;



                              if (isPunishment && diffSeconds >= 60) {



                                return const SizedBox.shrink();



                              } else if (!isPunishment && diffSeconds >= 180) {



                                return const SizedBox.shrink();



                              }



                            }







                            return Center(



                              child: Container(



                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),



                                padding: const EdgeInsets.all(12),



                                decoration: BoxDecoration(



                                  color: Colors.amber.withOpacity(0.15),



                                  borderRadius: BorderRadius.circular(14),



                                  border: Border.all(color: Colors.amber.shade700, width: 1.2),



                                ),



                                child: Column(



                                  crossAxisAlignment: CrossAxisAlignment.center,



                                  children: [



                                    Row(



                                      mainAxisSize: MainAxisSize.min,



                                      children: [



                                        Icon(Icons.shield, color: Colors.amber[800], size: 18),



                                        const SizedBox(width: 6),



                                        Text(



                                          'Официальное объявление',



                                          style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 13),



                                        ),



                                      ],



                                    ),



                                    const SizedBox(height: 6),



                                    Text(



                                      msg['text'] ?? '',



                                      textAlign: TextAlign.center,



                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),



                                    ),



                                    const SizedBox(height: 4),



                                    Text(



                                      formatMessageTime(timestamp),



                                      style: const TextStyle(fontSize: 10, color: Colors.grey),



                                    ),



                                  ],



                                ),



                              ),



                            );



                          }







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







                          if (isHighlighted) {



                            bubbleColor = Colors.amber.withOpacity(0.4);



                          }







                          final bool isTranslating = _translatingIds.contains(messageDoc.id);



                          final String? translatedText = _translations[messageDoc.id];







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



                              border: isSelected || isHighlighted



                                  ? Border.all(color: isHighlighted ? Colors.amber : theme.colorScheme.primary, width: 2)



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



                                      'Переслано от: $forwardedFrom',



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



                                        Text(



                                          replyTo['sender'] ?? '',



                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.primary),



                                        ),



                                        Text(



                                          replyTo['text'] != null && replyTo['text'].toString().isNotEmpty



                                              ? replyTo['text']



                                              : (replyTo['type'] == 'image' ? '🖼 Фото' : (replyTo['type'] == 'video' ? '🎥 Видео' : '🎤 Голосовое')),



                                          maxLines: 1,



                                          overflow: TextOverflow.ellipsis,



                                          style: const TextStyle(fontSize: 11, color: Colors.grey),



                                        ),



                                      ],



                                    ),



                                  ),



                                Row(



                                  mainAxisSize: MainAxisSize.min,



                                  crossAxisAlignment: CrossAxisAlignment.start,



                                  children: [



                                    if (!isMe) ...[



                                      GestureDetector(



                                        onTap: () => _showAvatarDialog(context, sender, senderId),



                                        child: UserAvatar(userId: senderId, radius: 16),



                                      ),



                                      const SizedBox(width: 8),



                                    ],



                                    Flexible(



                                      child: Column(



                                        crossAxisAlignment: CrossAxisAlignment.start,



                                        children: [



                                          Wrap(



                                            crossAxisAlignment: WrapCrossAlignment.center,



                                            spacing: 6,



                                            children: [



                                              if (senderPrefix.isNotEmpty)



                                                Container(



                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),



                                                  decoration: BoxDecoration(



                                                    color: Color(senderPrefixColor != 0 ? senderPrefixColor : 0xFFFFD700).withOpacity(0.2),



                                                    borderRadius: BorderRadius.circular(6),



                                                    border: Border.all(color: Color(senderPrefixColor != 0 ? senderPrefixColor : 0xFFFFD700), width: 1.2),



                                                    boxShadow: [



                                                      BoxShadow(



                                                        color: Color(senderPrefixColor != 0 ? senderPrefixColor : 0xFFFFD700).withOpacity(0.3),



                                                        blurRadius: 4,



                                                      )



                                                    ],



                                                  ),



                                                  child: Text(



                                                    senderPrefix,



                                                    style: TextStyle(



                                                      color: Color(senderPrefixColor != 0 ? senderPrefixColor : 0xFFFFD700),



                                                      fontWeight: FontWeight.bold,



                                                      fontSize: 10,



                                                    ),



                                                  ),



                                                ),



                                              GestureDetector(



                                                onTap: () => _openChatWithUser(context, sender, senderId),



                                                child: Text(



                                                  sender,



                                                  style: TextStyle(



                                                    fontWeight: FontWeight.bold,



                                                    color: theme.colorScheme.primary,



                                                    fontSize: 13,



                                                  ),



                                                ),



                                              ),



                                            ],



                                          ),



                                          const SizedBox(height: 2),



                                          _buildMessageContent(msg, isMe, messageDoc.id),







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



                                                        onTap: () => setState(() => _translations.remove(messageDoc.id)),



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



                                        ],



                                      ),



                                    ),



                                  ],



                                ),



                                if (reactions != null && reactions.isNotEmpty) ...[



                                  const SizedBox(height: 6),



                                  Wrap(



                                    spacing: 4,



                                    runSpacing: 4,



                                    children: reactions.entries.map((entry) {



                                      final emoji = entry.key;



                                      final list = entry.value as List<dynamic>;



                                      final count = list.length;



                                      final hasReacted = list.contains(currentUserId);







                                      if (count == 0) return const SizedBox.shrink();







                                      return InkWell(



                                        onTap: () => _selectReaction(messageDoc.id, emoji, reactions),



                                        child: Container(



                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),



                                          decoration: BoxDecoration(



                                            color: hasReacted ? theme.colorScheme.primary.withOpacity(0.2) : Colors.black.withOpacity(0.1),



                                            borderRadius: BorderRadius.circular(12),



                                            border: Border.all(color: hasReacted ? theme.colorScheme.primary : Colors.transparent),



                                          ),



                                          child: Text('$emoji $count', style: const TextStyle(fontSize: 12)),



                                        ),



                                      );



                                    }).toList(),



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



                                        style: const TextStyle(fontSize: 10, color: Colors.grey),



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



                            key: ValueKey(messageDoc.id),



                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,



                            child: GestureDetector(



                              onTapDown: (details) => _tapDownDetails = details,



                              onTap: () {



                                if (_isSelectionMode) {



                                  setState(() {



                                    if (isSelected) {



                                      _selectedMessageIds.remove(messageDoc.id);



                                      _selectedDocs.remove(messageDoc.id);



                                      if (_selectedMessageIds.isEmpty) _isSelectionMode = false;



                                    } else {



                                      _selectedMessageIds.add(messageDoc.id);



                                      _selectedDocs[messageDoc.id] = messageDoc;



                                    }



                                  });



                                } else if (_tapDownDetails != null) {



                                  _showCompactReactionPopup(context, messageDoc.id, reactions, _tapDownDetails!);



                                }



                              },



                              onLongPress: () {



                                if (!_isSelectionMode && _tapDownDetails != null) {



                                  _showCompactContextMenu(context, messageDoc, _tapDownDetails!.globalPosition);



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







                if (_showMentionSuggestions)



                  Container(



                    constraints: const BoxConstraints(maxHeight: 180),



                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),



                    decoration: BoxDecoration(



                      color: theme.dialogBackgroundColor,



                      borderRadius: BorderRadius.circular(16),



                      boxShadow: [



                        BoxShadow(



                          color: Colors.black.withOpacity(0.2),



                          blurRadius: 8,



                          offset: const Offset(0, -2),



                        )



                      ],



                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),



                    ),



                    child: ListView.separated(



                      shrinkWrap: true,



                      padding: const EdgeInsets.symmetric(vertical: 4),



                      itemCount: _filteredUsers.length,



                      separatorBuilder: (_, __) => const Divider(height: 1),



                      itemBuilder: (context, index) {



                        final item = _filteredUsers[index];



                        final isAll = item['isAll'] == true;



                        final nick = item['nickname'] as String;



                        final prefix = item['prefix'] as String? ?? '';



                        final prefixColor = item['prefixColor'] as int? ?? 0xFFFF9800;







                        if (isAll) {



                          return ListTile(



                            dense: true,



                            leading: Container(



                              padding: const EdgeInsets.all(6),



                              decoration: const BoxDecoration(



                                shape: BoxShape.circle,



                                color: Colors.orange,



                              ),



                              child: const Icon(Icons.campaign, color: Colors.white, size: 20),



                            ),



                            title: const Text(



                              '@all (Общий сбор)',



                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),



                            ),



                            subtitle: const Text('Уведомить всех участников альянса', style: TextStyle(fontSize: 11)),



                            onTap: () => _selectMention('all'),



                          );



                        }







                        return ListTile(



                          dense: true,



                          leading: UserAvatar(userId: item['id'] ?? '', directUrl: item['avatarUrl'], radius: 14),



                          title: Row(



                            children: [



                              if (prefix.isNotEmpty) ...[



                                Container(



                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),



                                  margin: const EdgeInsets.only(right: 6),



                                  decoration: BoxDecoration(



                                    color: Color(prefixColor != 0 ? prefixColor : 0xFFFFD700).withOpacity(0.2),



                                    borderRadius: BorderRadius.circular(4),



                                    border: Border.all(color: Color(prefixColor != 0 ? prefixColor : 0xFFFFD700), width: 1),



                                  ),



                                  child: Text(



                                    prefix,



                                    style: TextStyle(



                                      color: Color(prefixColor != 0 ? prefixColor : 0xFFFFD700),



                                      fontWeight: FontWeight.bold,



                                      fontSize: 9,



                                    ),



                                  ),



                                ),



                              ],



                              Text(nick, style: const TextStyle(fontWeight: FontWeight.bold)),



                            ],



                          ),



                          onTap: () => _selectMention(nick),



                        );



                      },



                    ),



                  ),







                Container(



                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),



                  color: theme.scaffoldBackgroundColor,



                  child: Row(



                    children: [



                      IconButton(



                        icon: const Icon(Icons.attach_file, color: Colors.grey, size: 28),



                        onPressed: _showAttachMenu,



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



                              const SizedBox(width: 5),



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



                            hintText: 'Введите сообщение...',



                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),



                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),



                          ),



                        ),



                      ),



                      const SizedBox(width: 6),



                      _hasText



                          ? IconButton(



                        icon: Icon(Icons.send, color: theme.colorScheme.primary, size: 28),



                        onPressed: _sendMessage,



                      )



                          : GestureDetector(



                        onLongPressStart: (_) => _startRecording(),



                        onLongPressEnd: (_) => _stopAndSendRecording(),



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







void checkForUpdate(BuildContext context) async {



  try {



    PackageInfo packageInfo = await PackageInfo.fromPlatform();



    int currentVersionCode = int.parse(packageInfo.buildNumber);







    var doc = await FirebaseFirestore.instance.collection('config').doc('update').get();



    if (!doc.exists) return;







    int serverVersionCode = doc.data()?['version_code'] ?? 0;



    String apkUrl = doc.data()?['apk_url'] ?? '';







    if (serverVersionCode > currentVersionCode) {



      showDialog(



        context: context,



        barrierDismissible: false,



        builder: (BuildContext context) {



          return AlertDialog(



            title: const Text("Доступно обновление"),



            content: const Text("Вышла новая версия приложения. Рекомендуем обновиться."),



            actions: [



              TextButton(



                onPressed: () async {



                  Navigator.pop(context);



                  await _downloadAndInstallApk(apkUrl, context);



                },



                child: const Text("Скачать и обновить"),



              ),



            ],



          );



        },



      );



    }



  } catch (e) {



    print("Ошибка при проверке обновления: $e");



  }



}







Future<void> _downloadAndInstallApk(String url, BuildContext context) async {



  try {



    ScaffoldMessenger.of(context).showSnackBar(



      const SnackBar(content: Text("Загрузка обновления...")),



    );







    Directory tempDir = await getTemporaryDirectory();



    String savePath = "${tempDir.path}/update.apk";







    await Dio().download(url, savePath);







    final result = await OpenFilex.open(savePath);







    if (result.type != ResultType.done) {



      ScaffoldMessenger.of(context).showSnackBar(



        const SnackBar(content: Text("Не удалось открыть файл установки")),



      );



    }



  } catch (e) {



    print("Ошибка скачивания: $e");



  }



}



