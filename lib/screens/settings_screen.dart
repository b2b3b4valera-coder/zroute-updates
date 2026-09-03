import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:audioplayers/audioplayers.dart';



import '../utils/theme_notifier.dart';

import '../widgets/user_avatar.dart';



class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});



  @override

  State<SettingsScreen> createState() => _SettingsScreenState();

}



class _SettingsScreenState extends State<SettingsScreen> {

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Настройки'),

        centerTitle: true,

      ),

      body: ListView(

        children: [

          _buildSettingsTile(

            context,

            icon: Icons.notifications_active,

            title: 'Уведомления',

            subtitle: 'Настройка Mute общего чата и ЛС',

            onTap: () {

              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()));

            },

          ),

          const Divider(height: 1),

          _buildSettingsTile(

            context,

            icon: Icons.volume_up,

            title: 'Звуки сообщений',

            subtitle: 'Вкл/выкл звука, выбор аудиосигнала',

            onTap: () {

              Navigator.push(context, MaterialPageRoute(builder: (_) => const SoundSettingsScreen()));

            },

          ),

          const Divider(height: 1),

          _buildSettingsTile(

            context,

            icon: Icons.color_lens,

            title: 'Дизайн и стили чата',

            subtitle: 'Зомби, Бордовый с кровью, Серый узор, Тёмная',

            onTap: () {

              Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignSettingsScreen()));

            },

          ),

          const Divider(height: 1),

          _buildSettingsTile(

            context,

            icon: Icons.storage,

            title: 'Хранение и загрузка медиа',

            subtitle: 'Кэш, автозагрузка фото и видео',

            onTap: () {

              Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageSettingsScreen()));

            },

          ),

          const Divider(height: 1),

          _buildSettingsTile(

            context,

            icon: Icons.support_agent,

            title: 'Поддержка и связь',

            subtitle: 'Написать разработчику, тикет с фото',

            onTap: () {

              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));

            },

          ),

        ],

      ),

    );

  }



  Widget _buildSettingsTile(

      BuildContext context, {

        required IconData icon,

        required String title,

        required String subtitle,

        required VoidCallback onTap,

      }) {

    return ListTile(

      leading: Container(

        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(

          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),

          shape: BoxShape.circle,

        ),

        child: Icon(icon, color: Theme.of(context).colorScheme.primary),

      ),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),

      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),

      onTap: onTap,

    );

  }

}



// =======================================================

// --- 1. ЭКРАН НАСТРОЙКИ УВЕДОМЛЕНИЙ (MUTE) ---

// =======================================================

class NotificationsSettingsScreen extends StatefulWidget {

  const NotificationsSettingsScreen({super.key});



  @override

  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();

}



class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {

  String _muteAll = 'Не отключать';

  String _muteGlobal = 'Не отключать';

  final List<String> _muteOptions = ['Не отключать', 'На 1 час', 'На 8 часов', 'На 24 часа', 'Навсегда'];



  @override

  void initState() {

    super.initState();

    _loadSettings();

  }



  Future<void> _loadSettings() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {

      _muteAll = prefs.getString('muteAll') ?? 'Не отключать';

      _muteGlobal = prefs.getString('muteGlobal') ?? 'Не отключать';

    });

  }



  Future<void> _saveSetting(String key, String value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);

    if (mounted) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены!')));

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Уведомления')),

      body: Padding(

        padding: const EdgeInsets.all(16.0),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text('Отключить все уведомления', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(

              value: _muteAll,

              decoration: const InputDecoration(border: OutlineInputBorder()),

              items: _muteOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),

              onChanged: (val) {

                if (val != null) {

                  setState(() => _muteAll = val);

                  _saveSetting('muteAll', val);

                }

              },

            ),

            const SizedBox(height: 30),

            const Text('Отключить уведомления общего чата', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(

              value: _muteGlobal,

              decoration: const InputDecoration(border: OutlineInputBorder()),

              items: _muteOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),

              onChanged: (val) {

                if (val != null) {

                  setState(() => _muteGlobal = val);

                  _saveSetting('muteGlobal', val);

                }

              },

            ),

          ],

        ),

      ),

    );

  }

}



// =======================================================

// --- 2. ЭКРАН НАСТРОЙКИ ЗВУКОВ ---

// =======================================================

class SoundSettingsScreen extends StatefulWidget {

  const SoundSettingsScreen({super.key});



  @override

  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();

}



class _SoundSettingsScreenState extends State<SoundSettingsScreen> {

  bool _privateSound = true;

  bool _globalSound = true;

  String _soundType = 'Щелчок (стандартный)';

  final List<String> _soundOptions = ['Щелчок (стандартный)', 'Капля', 'Дзинь'];



  final AudioPlayer _audioPlayer = AudioPlayer();



  @override

  void initState() {

    super.initState();

    _loadSettings();

  }



  @override

  void dispose() {

    _audioPlayer.dispose();

    super.dispose();

  }



  Future<void> _loadSettings() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {

      _privateSound = prefs.getBool('privateSound') ?? true;

      _globalSound = prefs.getBool('globalSound') ?? true;

      String savedSound = prefs.getString('soundType') ?? 'Щелчок (стандартный)';

      if (savedSound == 'Колокольчик' || savedSound == 'Щелчок') {

        savedSound = 'Щелчок (стандартный)';

      }

      if (!_soundOptions.contains(savedSound)) {

        savedSound = 'Щелчок (стандартный)';

      }

      _soundType = savedSound;

    });

  }



  Future<void> _playSound(String soundName) async {

    String fileName = 'click.mp3';

    if (soundName == 'Капля') fileName = 'drop.mp3';

    if (soundName == 'Дзинь') fileName = 'bell.mp3';



    try {

      await _audioPlayer.stop();

      await _audioPlayer.play(AssetSource('sounds/$fileName'));

    } catch (e) {

      debugPrint('Ошибка воспроизведения: $e');

    }

  }



  Future<void> _saveBool(String key, bool value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(key, value);

  }



  Future<void> _saveString(String key, String value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);

    if (mounted) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Звук изменен!')));

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Звуки')),

      body: ListView(

        padding: const EdgeInsets.all(16.0),

        children: [

          SwitchListTile(

            title: const Text('Звук в Личных сообщениях', style: TextStyle(fontWeight: FontWeight.bold)),

            subtitle: const Text('Воспроизводить звук при новом ЛС'),

            value: _privateSound,

            onChanged: (val) {

              setState(() => _privateSound = val);

              _saveBool('privateSound', val);

            },

          ),

          const Divider(),

          SwitchListTile(

            title: const Text('Звук в Общем чате', style: TextStyle(fontWeight: FontWeight.bold)),

            subtitle: const Text('Воспроизводить звук при сообщении в общем чате'),

            value: _globalSound,

            onChanged: (val) {

              setState(() => _globalSound = val);

              _saveBool('globalSound', val);

            },

          ),

          const Divider(),

          const SizedBox(height: 16),

          const Text('Выбор звука уведомлений', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(

            value: _soundType,

            decoration: const InputDecoration(border: OutlineInputBorder()),

            items: _soundOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),

            onChanged: (val) {

              if (val != null) {

                setState(() => _soundType = val);

                _saveString('soundType', val);

                _playSound(val);

              }

            },

          ),

        ],

      ),

    );

  }

}



// =======================================================

// --- 3. ЭКРАН ДИЗАЙНА И ТЕМ ОФОРМЛЕНИЯ ---

// =======================================================

class DesignSettingsScreen extends StatefulWidget {

  const DesignSettingsScreen({super.key});



  @override

  State<DesignSettingsScreen> createState() => _DesignSettingsScreenState();

}



class _DesignSettingsScreenState extends State<DesignSettingsScreen> {

  final List<Map<String, dynamic>> _themeList = [

    {

      'id': 'Тёмная',

      'title': 'Тёмная сталь',

      'desc': 'Глубокий тёмный кибер-стиль с геометрическими акцентами',

      'icon': Icons.dark_mode,

      'color': Colors.blueGrey,

    },

    {

      'id': 'Серый узор',

      'title': 'Серый бункер (Узор)',

      'desc': 'Матовый фон с перекрестными геометрическими фигурами',

      'icon': Icons.grid_4x4,

      'color': Colors.grey,

    },

    {

      'id': 'Бордовый (Кровь)',

      'title': 'Кровавый потёк (Crimson)',

      'desc': 'Винно-бордовые тона, пузыри чата со стекающими каплями крови',

      'icon': Icons.water_drop,

      'color': const Color(0xFF8B0000),

    },

    {

      'id': 'Зомби',

      'title': 'Зомби-апокалипсис',

      'desc': 'Пузыри сообщений в мёртвой хватке рук и когтей зомби',

      'icon': Icons.coronavirus,

      'color': const Color(0xFF388E3C),

    },

    {

      'id': 'Светлая',

      'title': 'Светлая классика',

      'desc': 'Чистая светлая тема приложения',

      'icon': Icons.light_mode,

      'color': Colors.amber,

    },

  ];



  Future<void> _changeTheme(String newTheme) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('appTheme', newTheme);

    setState(() {

      appThemeNotifier.value = newTheme;

    });

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Оформление')),

      body: ListView(

        padding: const EdgeInsets.all(16.0),

        children: [

          const Text('Стиль интерфейса и чатов', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

          const SizedBox(height: 12),

          ..._themeList.map((item) {

            final themeId = item['id'] as String;

            final isSelected = appThemeNotifier.value == themeId;

            final color = item['color'] as Color;



            return Card(

              elevation: isSelected ? 4 : 1,

              margin: const EdgeInsets.only(bottom: 10),

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(14),

                side: BorderSide(

                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,

                  width: 2,

                ),

              ),

              child: ListTile(

                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

                leading: Container(

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(

                    color: color.withOpacity(0.15),

                    shape: BoxShape.circle,

                    border: Border.all(color: color, width: 1.5),

                  ),

                  child: Icon(item['icon'] as IconData, color: color, size: 24),

                ),

                title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),

                subtitle: Text(item['desc'] as String, style: const TextStyle(fontSize: 11)),

                trailing: Radio<String>(

                  value: themeId,

                  groupValue: appThemeNotifier.value,

                  onChanged: (val) {

                    if (val != null) _changeTheme(val);

                  },

                ),

                onTap: () => _changeTheme(themeId),

              ),

            );

          }),

          const SizedBox(height: 16),

          Container(

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(

              color: Theme.of(context).colorScheme.surface,

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),

            ),

            child: const Text(

              'Смените тему, чтобы преобразить пузыри сообщений, фон и цвета альянса.',

              style: TextStyle(fontSize: 13),

              textAlign: TextAlign.center,

            ),

          ),

        ],

      ),

    );

  }

}



// =======================================================

// --- 4. ЭКРАН ХРАНЕНИЯ И ОЧИСТКИ КЭША ---

// =======================================================

class StorageSettingsScreen extends StatefulWidget {

  const StorageSettingsScreen({super.key});



  @override

  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();

}



class _StorageSettingsScreenState extends State<StorageSettingsScreen> {

  String _autoPhoto = 'Всегда';

  String _autoVideo = 'Только Wi-Fi';

  final List<String> _downloadOptions = ['Всегда', 'Только Wi-Fi', 'Никогда'];



  @override

  void initState() {

    super.initState();

    _loadSettings();

  }



  Future<void> _loadSettings() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {

      _autoPhoto = prefs.getString('autoPhoto') ?? 'Всегда';

      _autoVideo = prefs.getString('autoVideo') ?? 'Только Wi-Fi';

    });

  }



  Future<void> _saveSetting(String key, String value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);

    if (mounted) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены!')));

    }

  }



  void _clearCache() {

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Очистка кэша'),

        content: const Text('Все временно загруженные миниатюры будут удалены. Медиа загрузятся заново при повторном просмотре.'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),

          ElevatedButton(

            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: () {

              UserAvatar.avatarCache.clear();

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Кэш успешно очищен!')));

            },

            child: const Text('Очистить', style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Хранение данных')),

      body: ListView(

        padding: const EdgeInsets.all(16.0),

        children: [

          ListTile(

            leading: Icon(Icons.cleaning_services, color: Theme.of(context).colorScheme.primary),

            title: const Text('Очистить кэш приложения', style: TextStyle(fontWeight: FontWeight.bold)),

            subtitle: const Text('Освободить память устройства'),

            onTap: _clearCache,

          ),

          const Divider(),

          const SizedBox(height: 16),

          const Text('Автозагрузка фото', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(

            value: _autoPhoto,

            decoration: const InputDecoration(border: OutlineInputBorder()),

            items: _downloadOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),

            onChanged: (val) {

              if (val != null) {

                setState(() => _autoPhoto = val);

                _saveSetting('autoPhoto', val);

              }

            },

          ),

          const SizedBox(height: 24),

          const Text('Автозагрузка видео', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(

            value: _autoVideo,

            decoration: const InputDecoration(border: OutlineInputBorder()),

            items: _downloadOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),

            onChanged: (val) {

              if (val != null) {

                setState(() => _autoVideo = val);

                _saveSetting('autoVideo', val);

              }

            },

          ),

        ],

      ),

    );

  }

}



// =======================================================

// --- 5. ЭКРАН ПОДДЕРЖКИ И ОБРАТНОЙ СВЯЗИ ---

// =======================================================

class SupportScreen extends StatefulWidget {

  const SupportScreen({super.key});



  @override

  State<SupportScreen> createState() => _SupportScreenState();

}



class _SupportScreenState extends State<SupportScreen> {

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _messageController = TextEditingController();



  final ImagePicker _picker = ImagePicker();

  Uint8List? _attachedImageBytes;

  String? _imageExtension;



  bool _isLoading = false;



  @override

  void dispose() {

    _nameController.dispose();

    _emailController.dispose();

    _messageController.dispose();

    super.dispose();

  }



  Future<void> _pickImage() async {

    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (file != null) {

      final bytes = await file.readAsBytes();

      setState(() {

        _attachedImageBytes = bytes;

        _imageExtension = file.name.split('.').last;

      });

    }

  }



  String? _encodeQueryParameters(Map<String, String> params) {

    return params.entries

        .map((MapEntry<String, String> e) =>

    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')

        .join('&');

  }



  Future<void> _sendSupportRequest() async {

    final name = _nameController.text.trim();

    final email = _emailController.text.trim();

    final message = _messageController.text.trim();



    if (email.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Поле Email обязательно для заполнения!')));

      return;

    }

    if (message.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите текст сообщения!')));

      return;

    }



    setState(() { _isLoading = true; });



    try {

      String? photoUrl;

      if (_attachedImageBytes != null) {

        final storage = Supabase.instance.client.storage.from('chat-media');

        final path = 'support/${DateTime.now().millisecondsSinceEpoch}_ticket.${_imageExtension ?? 'jpg'}';

        await storage.uploadBinary(

          path,

          _attachedImageBytes!,

          fileOptions: FileOptions(contentType: 'image/${_imageExtension ?? 'jpeg'}', upsert: true),

        );

        photoUrl = storage.getPublicUrl(path);

      }



      await FirebaseFirestore.instance.collection('support_tickets').add({

        'name': name,

        'email': email,

        'message': message,

        'photoUrl': photoUrl ?? '',

        'timestamp': FieldValue.serverTimestamp(),

        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anon',

      });



      final Uri emailLaunchUri = Uri(

        scheme: 'mailto',

        path: 'valera.trushko1998@mail.ru',

        query: _encodeQueryParameters(<String, String>{

          'subject': 'Обращение в поддержку [vPv]',

          'body': 'Имя: $name\nEmail для обратной связи: $email\n\nСообщение:\n$message\n\nПрикрепленное фото: ${photoUrl ?? 'Нет вложений'}'

        }),

      );



      if (await canLaunchUrl(emailLaunchUri)) {

        await launchUrl(emailLaunchUri);

      }



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Обращение сформировано и отправлено!')));

        Navigator.pop(context);

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));

      }

    } finally {

      if (mounted) {

        setState(() { _isLoading = false; });

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('Поддержка')),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20.0),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Container(

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),

              ),

              child: Text(

                'Связь напрямую с создателем альянса [vPv]: задайте вопрос, сообщите о баге или предложите идею!',

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),

              ),

            ),

            const SizedBox(height: 20),

            TextField(

              controller: _nameController,

              decoration: const InputDecoration(labelText: 'Ваше имя', border: OutlineInputBorder()),

            ),

            const SizedBox(height: 15),

            TextField(

              controller: _emailController,

              keyboardType: TextInputType.emailAddress,

              decoration: const InputDecoration(labelText: 'Ваш email (Обязательно)', border: OutlineInputBorder()),

            ),

            const SizedBox(height: 15),

            TextField(

              controller: _messageController,

              maxLines: 5,

              decoration: const InputDecoration(labelText: 'Сообщение', border: OutlineInputBorder()),

            ),

            const SizedBox(height: 15),

            if (_attachedImageBytes != null)

              Container(

                margin: const EdgeInsets.only(bottom: 15),

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  color: Colors.green.withOpacity(0.1),

                  borderRadius: BorderRadius.circular(8),

                  border: Border.all(color: Colors.green),

                ),

                child: const Row(

                  children: [

                    Icon(Icons.check_circle, color: Colors.green),

                    SizedBox(width: 8),

                    Text('Скриншот прикреплен!', style: TextStyle(color: Colors.green)),

                  ],

                ),

              ),

            OutlinedButton.icon(

              onPressed: _pickImage,

              icon: const Icon(Icons.add_photo_alternate),

              label: Text(_attachedImageBytes == null ? 'Прикрепить скриншот/фото' : 'Выбрать другое фото'),

            ),

            const SizedBox(height: 25),

            SizedBox(

              height: 50,

              child: ElevatedButton(

                onPressed: _isLoading ? null : _sendSupportRequest,

                child: _isLoading

                    ? const CircularProgressIndicator(color: Colors.white)

                    : const Text('Отправить обращение', style: TextStyle(fontSize: 16)),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



