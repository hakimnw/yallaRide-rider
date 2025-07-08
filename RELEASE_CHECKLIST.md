# 🚀 Release APK Checklist

## ✅ **COMPLETED FIXES**

### 1. **Release Signing Configuration** ✅
- ✅ Updated `android/app/build.gradle` to use proper release signing
- ✅ Created `android/key.properties` template
- ⚠️ **ACTION REQUIRED**: Update `key.properties` with your actual keystore details

### 2. **Firebase Configuration** ✅
- ✅ Replaced placeholder Firebase Android App ID
- ✅ Replaced placeholder Firebase Messaging Sender ID
- ✅ Firebase API key is configured

### 3. **Debug Files Cleanup** ✅
- ✅ Removed `test_book_ride.dart` (contained placeholder URLs)
- ✅ Removed `test_api.dart` (test file)
- ✅ Removed `debug_onesignal.dart` (debug file)
- ✅ Reduced debug print statements in `NewEstimateRideListWidget.dart`

### 4. **Build Configuration** ✅
- ✅ ProGuard rules are properly configured
- ✅ Minify and shrink resources enabled for release
- ✅ Version code: 30, Version name: 7.0.0

---

## ⚠️ **ACTIONS REQUIRED BEFORE RELEASE**

### 1. **Keystore Setup** (CRITICAL)
Update `android/key.properties` with your actual values:
```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD  
keyAlias=YOUR_ACTUAL_KEY_ALIAS
storeFile=YOUR_ACTUAL_KEYSTORE_FILE_PATH.jks
```

### 2. **ZEGO Cloud Credentials** (If using calling feature)
According to `CRITICAL_FIXES_NEEDED.md`, verify:
- ✅ Real Zego credentials are set (App ID: 113057318)
- ❓ Driver app has matching Zego integration

### 3. **API Configuration**
Verify `lib/utils/Constants.dart`:
- ✅ Domain URL is set correctly
- ✅ Firebase configuration is complete
- ✅ OneSignal configuration is set

### 4. **Git Status Cleanup**
You have uncommitted changes. Consider committing or reverting:
```
Modified files:
- lib/components/DriverSelectionScreen.dart
- lib/components/RideAcceptWidget.dart
- lib/network/RestApis.dart
- lib/screens/DashBoardScreen.dart
- lib/screens/NewEstimateRideListWidget.dart
- lib/screens/SettingScreen.dart
- lib/screens/SignInScreen.dart
- lib/screens/SignUpScreen.dart
```

---

## 🔧 **BUILD COMMANDS**

### Clean Build
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
```

### Release APK
```bash
flutter build apk --release
```

### Release App Bundle (Recommended for Play Store)
```bash
flutter build appbundle --release
```

---

## 🎯 **VERIFICATION STEPS**

### Before Building:
- [ ] Update `key.properties` with real keystore details
- [ ] Verify all API endpoints are production URLs
- [ ] Test app functionality in release mode
- [ ] Commit all changes to git

### After Building:
- [ ] Test install APK on device
- [ ] Verify app signing
- [ ] Check app functionality
- [ ] Verify no debug logs in production

---

## ⚡ **QUICK STATUS**

**Ready for Release**: 🟡 **Almost Ready**
- ✅ Build configuration fixed
- ✅ Debug cleanup completed
- ⚠️ Keystore setup required
- ⚠️ Git changes need attention

**Next Steps**: 
1. Update `key.properties` with real keystore
2. Test release build
3. Commit changes
4. Build release APK 