import 'package:audioplayers/audioplayers.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';



class SoundHelper {

  static final AudioPlayer _player = AudioPlayer();



  static Future<void> playSound(bool isPrivate) async {

    try {

      final prefs = await SharedPreferences.getInstance();



      final muteAll = prefs.getString('muteAll') ?? 'Не отключать';

      if (muteAll != 'Не отключать') return;



      if (isPrivate) {

        final privateSound = prefs.getBool('privateSound') ?? true;

        if (!privateSound) return;

      } else {

        final globalSound = prefs.getBool('globalSound') ?? true;

        final muteGlobal = prefs.getString('muteGlobal') ?? 'Не отключать';

        if (!globalSound || muteGlobal != 'Не отключать') return;

      }



      // Новое значение по умолчанию — Щелчок

      final soundType = prefs.getString('soundType') ?? 'Щелчок';

      String assetName = 'sounds/click.mp3';



      if (soundType == 'Щелчок') {

        assetName = 'sounds/click.mp3';

      } else if (soundType == 'Капля') {

        assetName = 'sounds/drop.mp3';

      } else if (soundType == 'Дзинь') {

        assetName = 'sounds/bell.mp3';

      }



      await _player.play(AssetSource(assetName));

    } catch (e) {

      if (kDebugMode) {

        debugPrint('Ошибка воспроизведения звука: $e');

      }

    }

  }

}



