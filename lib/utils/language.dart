import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Language {
  Locale locale;
  String langName;
  Language({
    required this.locale,
    required this.langName,
  });
  String get translatedName => 'lang.${locale.languageCode}'.tr();
}

/*List<Language> languageList = [
  Language(
    langName: 'lang.en'.tr(),
    locale: const Locale('en'),
  ),
  Language(
    langName: 'lang.fr'.tr(),
    locale: const Locale('fr'),
  ),
  Language(
    langName: 'lang.es'.tr(),
    locale: const Locale('es'),
  )
];*/

extension convertFlag on String {
  String get toFlag {
    return (this)
        .toUpperCase()
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
  }
}
