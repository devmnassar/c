import 'package:flutter/widgets.dart';
import 'package:gaseel_courier/core/locale/core_localizer.dart';
import 'package:gaseel_courier/core/locale/legacy_l10n_keys.dart';

/// Backward-compatibility adapter:
/// lets old `'someGetter'.tr` / `l10n.someMethod(args)` resolve through
/// the new core-based translations source.
class LegacyL10nProxy {
  const LegacyL10nProxy._(this.context);

  final BuildContext context;

  static dynamic of(BuildContext context) => LegacyL10nProxy._(context);

  // Explicit getters for call sites that use static typing (not dynamic).
  String get enableLocationDesc => _translateKey('enableLocationDesc');
  String get locationUnavailable => _translateKey('locationUnavailable');
  String get locationPermissionDenied =>
      _translateKey('locationPermissionDenied');
  String get mustTakeBuildingPhotoWarning =>
      _translateKey('mustTakeBuildingPhotoWarning');
  String get complaintSubmitted => _translateKey('complaintSubmitted');
  String get openSettings => _translateKey('openSettings');

  String _translateKey(String key) {
    final english = LegacyL10nKeys.keyToEnglish[key];
    if (english == null) return key;
    return CoreLocalizer.t(english, context: context);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final symbol = invocation.memberName.toString();
    final match = RegExp(r'Symbol\("(.+)"\)').firstMatch(symbol);
    final key = match?.group(1);
    if (key == null || key.isEmpty) {
      return super.noSuchMethod(invocation);
    }

    final english = LegacyL10nKeys.keyToEnglish[key];
    if (english == null) return key;

    if (!invocation.isMethod || invocation.positionalArguments.isEmpty) {
      return CoreLocalizer.t(english, context: context);
    }

    // Generic positional placeholder replacement for legacy generated methods:
    // e.g. "Order Number #{number}" with one arg => replaces first placeholder.
    var resolvedTemplate = english;
    var index = 0;
    final placeholders = RegExp(r'\{[^}]+\}').allMatches(english).toList();
    for (final placeholder in placeholders) {
      if (index >= invocation.positionalArguments.length) break;
      resolvedTemplate = resolvedTemplate.replaceFirst(
        placeholder.group(0)!,
        '${invocation.positionalArguments[index]}',
      );
      index++;
    }

    return CoreLocalizer.t(resolvedTemplate, context: context);
  }
}
