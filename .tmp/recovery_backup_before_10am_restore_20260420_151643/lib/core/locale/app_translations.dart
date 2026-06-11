import 'package:get/get.dart';
import 'package:gaseel_courier/core/locale/core_translations_data.dart';

class AppTranslations extends Translations {
  AppTranslations();

  final Map<String, String> en = Map.unmodifiable(CoreTranslationsData.en);
  final Map<String, String> ar = Map.unmodifiable(CoreTranslationsData.ar);

  @override
  Map<String, Map<String, String>> get keys => {
        'en': en,
        'ar': ar,
      };
}
