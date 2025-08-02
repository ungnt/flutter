## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

## Dart
-keep class com.google.dart.** { *; }

## SQLite
-keep class io.flutter.plugins.sqflite.** { *; }

## Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

## Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## File picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

## Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

## Share plus
-keep class dev.fluttercommunity.plus.share.** { *; }



## Generic rules
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugins.**