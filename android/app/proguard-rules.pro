# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep rules for missing classes identified by R8

# Keep Karaoke SDK classes
-keep class com.itgsa.opensdk.** { *; }
-dontwarn com.itgsa.opensdk.**

# Keep Java beans classes
-keep class java.beans.** { *; }
-dontwarn java.beans.**

# Keep DOM classes
-keep class org.w3c.dom.bootstrap.** { *; }
-dontwarn org.w3c.dom.bootstrap.**

# Keep ProGuard annotation classes
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

# Keep Jackson databind classes
-keep class com.fasterxml.jackson.databind.** { *; }
-dontwarn com.fasterxml.jackson.databind.**

# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# General Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep all native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all classes with @Keep annotation
-keep @androidx.annotation.Keep class * {*;}
-keep @androidx.annotation.Keep public class * {
    public protected *;
}

# Keep all methods with @Keep annotation
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep all classes in kotlin package
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep Kotlin metadata
-keepattributes *Annotation*,InnerClasses,Signature,Exceptions

# Keep all attributes for debugging
-keepattributes *Annotation*,Signature,Exception,InnerClasses,EnclosingMethod,Deprecated,SourceFile,LineNumberTable

# Keep Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Additional rules for common issues
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe
-dontwarn java.lang.invoke.** 