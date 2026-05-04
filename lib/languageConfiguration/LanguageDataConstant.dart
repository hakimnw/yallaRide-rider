import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:taxi_booking/utils/images.dart';

import '../main.dart';
import '../utils/Constants.dart';
import 'LanguageDefaultJson.dart';
import 'LocalLanguageResponse.dart';
import 'ServerLanguageResponse.dart';

const LanguageJsonDataRes = 'LanguageJsonDataRes'; // DO NOT CHANGE
const CURRENT_LAN_VERSION = 'LanguageData'; // DO NOT CHANGE
const LanguageVersion = '0'; // DO NOT CHANGE
const SELECTED_LANGUAGE_CODE = 'selected_language_code'; // DO NOT CHANGE
const SELECTED_LANGUAGE_COUNTRY_CODE = 'selected_language_country_code'; // DO NOT CHANGE
const IS_SELECTED_LANGUAGE_CHANGE = 'isSelectedLanguageChange';

Locale defaultLanguageLocale = Locale(defaultLanguageCode, defaultCountryCode);

Locale setDefaultLocate() {
  String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? "";
  if (getJsonData.isNotEmpty) {
    ServerLanguageResponse languageSettings = ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
    if (languageSettings.data!.length > 0) {
      defaultServerLanguageData = languageSettings.data;
      performLanguageOperation(defaultServerLanguageData);
    }
  }
  if (defaultServerLanguageData != null && defaultServerLanguageData!.length > 0) {
    performLanguageOperation(defaultServerLanguageData);
  }

  return defaultLanguageLocale;
}

performLanguageOperation(List<LanguageJsonData>? _defaultServerLanguageData) {
  String selectedLanguageCode = sharedPref.getString(SELECTED_LANGUAGE_CODE) ?? "";
  bool isFoundLocalSelectedLanguage = false;
  bool isFoundSelectedLanguageFromServer = false;

  for (int index = 0; index < _defaultServerLanguageData!.length; index++) {
    if (selectedLanguageCode.isNotEmpty) {
      if (_defaultServerLanguageData[index].languageCode == selectedLanguageCode) {
        isFoundLocalSelectedLanguage = true;
        defaultLanguageLocale =
            Locale(_defaultServerLanguageData[index].languageCode!, _defaultServerLanguageData[index].countryCode!);
        selectedServerLanguageData = _defaultServerLanguageData[index];
        break;
      }
    }
    if (_defaultServerLanguageData[index].isDefaultLanguage == 1) {
      isFoundSelectedLanguageFromServer = true;
      defaultLanguageLocale =
          Locale(_defaultServerLanguageData[index].languageCode!, _defaultServerLanguageData[index].countryCode!);
      selectedServerLanguageData = _defaultServerLanguageData[index];
    }
  }

  if (!isFoundLocalSelectedLanguage && !isFoundSelectedLanguageFromServer) {
    selectedServerLanguageData = null;
  }
}

List<Locale> getSupportedLocales() {
  List<Locale> list = [];
  if (defaultServerLanguageData != null && defaultServerLanguageData!.length > 0) {
    for (int index = 0; index < defaultServerLanguageData!.length; index++) {
      list.add(Locale(defaultServerLanguageData![index].languageCode!, defaultServerLanguageData![index].countryCode!));
    }
  } else {
    list.add(defaultLanguageLocale);
  }
  return list;
}

String getContentValueFromKey(int keywordId) {
  String defaultKeyValue = defaultKeyNotFoundValue;
  bool isFoundKey = false;

  // First try to find in selected server language data
  if (selectedServerLanguageData != null) {
    for (int index = 0; index < selectedServerLanguageData!.contentData!.length; index++) {
      if (selectedServerLanguageData!.contentData![index].keywordId == keywordId) {
        defaultKeyValue = selectedServerLanguageData!.contentData![index].keywordValue!;
        isFoundKey = true;
        break;
      }
    }
  }

  // If not found in server data, try default language data
  if (!isFoundKey) {
    for (int index = 0; index < defaultLanguageDataKeys.length; index++) {
      if (defaultLanguageDataKeys[index].keywordId == keywordId) {
        defaultKeyValue = defaultLanguageDataKeys[index].keywordValue!;
        isFoundKey = true;
        break;
      }
    }
  }

  // If still not found, return a user-friendly message instead of showing the key ID
  if (!isFoundKey) {
    // Return a generic message instead of showing the key ID
    switch (keywordId) {
      // Login Screen Keys
      case 2:
        return "هذا الحقل مطلوب";
      case 3:
        return "البريد الإلكتروني";
      case 4:
        return "كلمة المرور";
      case 5:
        return "نسيت كلمة المرور؟";
      case 6:
        return "تسجيل الدخول";
      case 7:
        return "أو سجل الدخول باستخدام";
      case 8:
        return "ليس لديك حساب؟";
      case 9:
        return "إنشاء حساب";
      case 10:
        return "إنشاء حساب جديد";
      case 11:
        return "الاسم الأول";
      case 12:
        return "اسم العائلة";
      case 13:
        return "اسم المستخدم";
      case 14:
        return "رقم الهاتف";
      case 15:
        return "لديك حساب بالفعل؟";
      case 16:
        return "تغيير كلمة المرور";
      case 17:
        return "كلمة المرور القديمة";
      case 18:
        return "كلمة المرور الجديدة";
      case 19:
        return "تأكيد كلمة المرور";
      case 20:
        return "كلمات المرور غير متطابقة";
      case 21:
        return "الحد الأدنى المطلوب لطول كلمة المرور هو 8 أحرف.";
      case 22:
        return "نعم";
      case 23:
        return "لا";
      case 27:
        return "اللغة";
      case 28:
        return "الإشعارات";
      case 32:
        return "شكوى";
      case 36:
        return "تعديل الملف الشخصي";
      case 37:
        return "العنوان";
      case 45:
        return "حفظ";
      case 50:
        return "إلغاء";
      case 57:
        return "تأكيد";
      case 92:
        return "تسجيل الخروج";
      case 93:
        return "هل أنت متأكد أنك تريد تسجيل الخروج من هذا التطبيق؟";
      case 94:
        return "إلى أين تريد الذهاب؟";
      case 95:
        return "أدخل وجهتك";
      case 96:
        return "الموقع الحالي";
      case 97:
        return "موقع الوجهة";
      case 98:
        return "اختر على الخريطة";
      case 99:
        return "الملف الشخصي";
      case 100:
        return "سياسة الخصوصية";
      case 102:
        return "الشروط والأحكام";
      case 104:
        return "البحث عن سائقين قريبين";
      case 105:
        return "نحن نبحث عن سيارة قريبة منك لقبول عرضك في أسرع وقت";
      case 116:
        return "سجل الدخول باستخدام رقم هاتفك المحمول";
      case 117:
        return "رمز التحقق";
      case 132:
        return "حذف الحساب";
      case 133:
        return "الحساب";
      case 136:
        return "هل أنت متأكد أنك تريد حذف الحساب؟";
      case 157:
        return "يرجى قبول شروط الخدمة وسياسة الخصوصية";
      case 158:
        return "تذكرني";
      case 159:
        return "أوافق على";
      case 167:
        return "موقع الانطلاق";
      case 192:
        return "سبب الإلغاء";
      case 232:
        return "من سيركب؟";
      case 233:
        return "عبر";
      case 234:
        return "الحالة";
      case 236:
        return "سعر الدقيقة";
      case 240:
        return "مرحباً";
      case 241:
        return "سجل الدخول للمتابعة";
      case 242:
        return "يجب أن يكون طول كلمة المرور 8 أحرف على الأقل";
      case 243:
        return "يجب أن تتطابق كلمتا المرور";
      case 253:
        return "تم إلغاء الرحلة من قبل السائق";
      case 267:
        return "+إضافة نقطة إنزال";
      case 383:
        return "مسافة الرحلة";
      case 393:
        return "رحلاتك المجدولة";
      case 606:
        return "زائر";
      case 1:
        return "مايتي تاكسي";
      default:
        return "النص غير متوفر";
    }
  }

  return defaultKeyValue.toString().trim();
}

initJsonFile() async {
  final String jsonString = await rootBundle.loadString(languageJsonPath);
  final list = json.decode(jsonString) as List;
  List<LocalLanguageResponse> finalList = list.map((jsonElement) => LocalLanguageResponse.fromJson(jsonElement)).toList();
  defaultLanguageDataKeys.clear();
  for (int index = 0; index < finalList.length; index++) {
    for (int i = 0; i < finalList[index].keywordData!.length; i++) {
      defaultLanguageDataKeys.add(ContentData(
          keywordId: finalList[index].keywordData![i].keywordId,
          keywordName: finalList[index].keywordData![i].keywordName,
          keywordValue: finalList[index].keywordData![i].keywordValue));
    }
  }
}

// DO NOT CHANGE

String getCountryCode() {
  String defaultCode = defaultCountry;
  String selectedLang = sharedPref.getString(SELECTED_LANGUAGE_CODE) ?? defaultLanguageCode;
  if (defaultServerLanguageData != null && defaultServerLanguageData!.length > 0) {
    for (int index = 0; index < defaultServerLanguageData!.length; index++) {
      if (selectedLang == defaultServerLanguageData![index].languageCode) {
        List<String> selectedCoutry = defaultServerLanguageData![index].countryCode!.split("-");
        if (selectedCoutry.length > 0) {
          defaultCode = selectedCoutry[1];
        }
      }
    }
  }

  return defaultCode;
}
