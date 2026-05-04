import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../main.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class NotificationService {
  Future<void> sendPushNotifications(String title, String content,
      {String? id, String? image, String? receiverPlayerId}) async {
    // Start debug logging
    print('=== NOTIFICATION DEBUG START ===');
    print('📱 Sending push notification:');
    print('  - Title: $title');
    print('  - Content: $content');
    print('  - Receiver ID: $receiverPlayerId');
    print('  - Current User Player ID: ${sharedPref.getString(PLAYER_ID)}');
    print('  - Image: ${image ?? 'No image'}');
    print('  - Custom ID: ${id ?? 'No custom ID'}');

    try {
      // Validate required parameters
      if (receiverPlayerId == null || receiverPlayerId.isEmpty) {
        print('❌ ERROR: receiverPlayerId is null or empty');
        throw 'Receiver Player ID is required';
      }

      print('🔧 Building notification payload...');
      Map req = {
        'headings': {
          'en': title,
        },
        'contents': {
          'en': content,
        },
        'data': {
          'id': 'CHAT_${sharedPref.getInt(USER_ID)}',
        },
        'big_picture': image.validate().isNotEmpty ? image.validate() : '',
        'large_icon': image.validate().isNotEmpty ? image.validate() : '',
        //   'small_icon': mAppIconUrl,
        'app_id': mOneSignalAppIdDriver,
        'android_channel_id': mOneSignalDriverChannelID,
        'include_player_ids': [receiverPlayerId],
        'android_group': mAppName,
        // 'sound': 'ride_get_sound',
      };

      print('📦 Notification payload:');
      print(JsonEncoder.withIndent('  ').convert(req));

      print('🔑 Setting up headers...');
      var header = {
        HttpHeaders.authorizationHeader: 'Basic $mOneSignalRestKeyDriver',
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      };
      print('  - Authorization: Basic ${mOneSignalRestKeyDriver.substring(0, 10)}...');
      print('  - Content-Type: ${header[HttpHeaders.contentTypeHeader]}');

      print('🚀 Sending request to OneSignal API...');
      Response res = await post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        body: jsonEncode(req),
        headers: header,
      );

      print('📬 Response received:');
      print('  - Status code: ${res.statusCode}');
      print('  - Body: ${res.body}');

      if (res.statusCode.isEven) {
        print('✅ Notification sent successfully!');
      } else {
        print('❌ Error sending notification:');
        print('  - Status code: ${res.statusCode}');
        print('  - Error body: ${res.body}');
        throw 'Something Went Wrong';
      }
    } catch (e) {
      print('❌ Exception caught while sending notification:');
      print('  - Error: $e');
      print('=== NOTIFICATION DEBUG END ===');
      throw e;
    }

    print('=== NOTIFICATION DEBUG END ===');
  }

  // دالة جديدة لإرسال الإشعارات بناءً على رقم الهاتف
  Future<void> sendPushNotificationByPhone(String title, String content,
      {String? id, String? image, String? receiverPhoneNumber}) async {
    print('=== PHONE-BASED NOTIFICATION DEBUG START ===');
    print('📱 Sending phone-based push notification:');
    print('  - Title: $title');
    print('  - Content: $content');
    print('  - Receiver Phone: $receiverPhoneNumber');
    print('  - Current User Phone: ${sharedPref.getString(CONTACT_NUMBER)}');
    print('  - Image: ${image ?? 'No image'}');
    print('  - Custom ID: ${id ?? 'No custom ID'}');

    try {
      // Validate required parameters
      if (receiverPhoneNumber == null || receiverPhoneNumber.isEmpty) {
        print('❌ ERROR: receiverPhoneNumber is null or empty');
        throw 'Receiver Phone Number is required';
      }

      print('🔧 Building phone-based notification payload...');
      Map req = {
        'headings': {
          'en': title,
        },
        'contents': {
          'en': content,
        },
        'data': {
          'id': 'CHAT_${sharedPref.getInt(USER_ID)}',
          'type': 'CHAT',
          'sender_phone': sharedPref.getString(CONTACT_NUMBER),
          'receiver_phone': receiverPhoneNumber,
        },
        'big_picture': image.validate().isNotEmpty ? image.validate() : '',
        'large_icon': image.validate().isNotEmpty ? image.validate() : '',
        'app_id': mOneSignalAppIdDriver,
        'android_channel_id': mOneSignalDriverChannelID,
        'android_group': mAppName,
        // استخدام External User IDs بدلاً من Player IDs
        'include_external_user_ids': [receiverPhoneNumber],
      };

      print('📦 Phone-based notification payload:');
      print(JsonEncoder.withIndent('  ').convert(req));

      print('🔑 Setting up headers...');
      var header = {
        HttpHeaders.authorizationHeader: 'Basic $mOneSignalRestKeyDriver',
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      };

      print('🚀 Sending phone-based request to OneSignal API...');
      Response res = await post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        body: jsonEncode(req),
        headers: header,
      );

      print('📬 Phone-based response received:');
      print('  - Status code: ${res.statusCode}');
      print('  - Body: ${res.body}');

      if (res.statusCode.isEven) {
        print('✅ Phone-based notification sent successfully!');
      } else {
        print('❌ Error sending phone-based notification:');
        print('  - Status code: ${res.statusCode}');
        print('  - Error body: ${res.body}');
        throw 'Something Went Wrong with phone-based notification';
      }
    } catch (e) {
      print('❌ Exception caught while sending phone-based notification:');
      print('  - Error: $e');
      print('=== PHONE-BASED NOTIFICATION DEBUG END ===');
      throw e;
    }

    print('=== PHONE-BASED NOTIFICATION DEBUG END ===');
  }

  // دالة مساعدة لتسجيل External User ID (رقم الهاتف) في OneSignal
  Future<void> setExternalUserId(String phoneNumber) async {
    print('🔧 Setting External User ID: $phoneNumber');
    // هذا سيتم استدعاؤه في Common.dart مع OneSignal settings
  }
}
