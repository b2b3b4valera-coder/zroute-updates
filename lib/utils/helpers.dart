import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';



// --- ФОРМАТИРОВАНИЕ ВРЕМЕНИ ---

String formatMessageTime(dynamic timestamp) {

  if (timestamp == null || timestamp is! Timestamp) return '';

  DateTime date = timestamp.toDate();

  DateTime now = DateTime.now();



  bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;

  String hour = date.hour.toString().padLeft(2, '0');

  String minute = date.minute.toString().padLeft(2, '0');

  String timeStr = '$hour:$minute';



  if (isToday) {

    return 'Сегодня $timeStr';

  } else {

    String day = date.day.toString().padLeft(2, '0');

    String month = date.month.toString().padLeft(2, '0');

    String year = date.year.toString();

    return '$day.$month.$year $timeStr';

  }

}



// --- ФОРМАТИРОВАНИЕ ДЛИТЕЛЬНОСТИ АУДИО ---

String formatDuration(int seconds) {

  final min = (seconds ~/ 60).toString().padLeft(2, '0');

  final sec = (seconds % 60).toString().padLeft(2, '0');

  return '$min:$sec';

}



// --- СКАЧИВАНИЕ ФАЙЛОВ ---

Future<void> downloadMediaFile(BuildContext context, String url) async {

  try {

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Началось скачивание файла...')),

        );

      }

    } else {

      throw 'Не удалось открыть ссылку для скачивания';

    }

  } catch (e) {

    if (context.mounted) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Ошибка скачивания: $e')),

      );

    }

  }

}



// --- ИЗВЛЕЧЕНИЕ УПОМИНАНИЙ (@никнейм) ---

List<String> extractMentions(String text) {

  final RegExp regex = RegExp(r'@([\wа-яА-ЯёЁ_]+)');

  final Iterable<Match> matches = regex.allMatches(text);

  return matches.map((m) => m.group(1)!).toList();

}



