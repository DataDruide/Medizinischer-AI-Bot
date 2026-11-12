import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.speechEnabled = true,
    this.speechLocale = 'de_DE',
    this.openFdaEnabled = true,
    this.ollamaBaseUrl = '',
    this.ollamaModel = 'qwen2.5:3b',
  });

  final ThemeMode themeMode;
  final bool speechEnabled;
  final String speechLocale;
  final bool openFdaEnabled;
  final String ollamaBaseUrl;
  final String ollamaModel;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? speechEnabled,
    String? speechLocale,
    bool? openFdaEnabled,
    String? ollamaBaseUrl,
    String? ollamaModel,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    speechEnabled: speechEnabled ?? this.speechEnabled,
    speechLocale: speechLocale ?? this.speechLocale,
    openFdaEnabled: openFdaEnabled ?? this.openFdaEnabled,
    ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
    ollamaModel: ollamaModel ?? this.ollamaModel,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'speechEnabled': speechEnabled,
    'speechLocale': speechLocale,
    'openFdaEnabled': openFdaEnabled,
    'ollamaBaseUrl': ollamaBaseUrl,
    'ollamaModel': ollamaModel,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final themeModeName = json['themeMode'];
    final themeMode = ThemeMode.values.where(
      (mode) => mode.name == themeModeName,
    );
    if (themeMode.isEmpty ||
        json['speechEnabled'] is! bool ||
        json['speechLocale'] is! String ||
        json['openFdaEnabled'] is! bool ||
        json['ollamaBaseUrl'] is! String ||
        json['ollamaModel'] is! String) {
      throw const FormatException('Ungültige Einstellungen');
    }
    if (!const ['de_DE', 'en_US'].contains(json['speechLocale'])) {
      throw const FormatException('Ungültige Spracheinstellung');
    }
    return AppSettings(
      themeMode: themeMode.first,
      speechEnabled: json['speechEnabled'] as bool,
      speechLocale: json['speechLocale'] as String,
      openFdaEnabled: json['openFdaEnabled'] as bool,
      ollamaBaseUrl: json['ollamaBaseUrl'] as String,
      ollamaModel: json['ollamaModel'] as String,
    );
  }
}
