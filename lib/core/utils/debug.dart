import 'package:flutter/foundation.dart';

void line(String label) {
  debugPrint("####################  $label  ####################");
}

void debug(dynamic object, {String label = 'DEBUG', int depth = 0}) {
  final indent = '  ' * depth;

  void printValue(String key, dynamic value) {
    debugPrint('$indent$key (${value.runtimeType}): $value');
  }

  void recurse(dynamic obj, {String? key}) {
    if (obj == null) {
      printValue(key ?? 'null', 'null');
    } else if (obj is Map) {
      debugPrint('$indent${key ?? "Map"} (${obj.runtimeType}):');
      if (obj.isEmpty) {
        debugPrint('$indent  (empty map)');
      } else {
        obj.forEach((k, v) => debug(v, label: '$k', depth: depth + 1));
      }
    } else if (obj is Iterable) {
      debugPrint('$indent${key ?? "Iterable"} (${obj.runtimeType}):');
      if (obj.isEmpty) {
        debugPrint('$indent  (empty iterable)');
      } else {
        int i = 0;
        for (var item in obj) {
          debug(item, label: '$i', depth: depth + 1);
          i++;
        }
      }
    } else if (obj is String) {
      printValue(key ?? 'String', obj);
      debugPrint('$indent  Length: ${obj.length}');
    } else if (obj is num || obj is bool || obj is DateTime) {
      printValue(key ?? 'Value', obj);
    } else if (obj is Iterable) {
      debugPrint('$indent${key ?? "Iterable"} (${obj.runtimeType}):');
      if (obj.isEmpty) {
        debugPrint('$indent  (empty iterable)');
      } else {
        int i = 0;
        for (var item in obj) {
          debug(item, label: '$i', depth: depth + 1);
          i++;
        }
      }
    } else if (obj is Function) {
      printValue(key ?? 'Function', obj.toString());
    } else if (obj is Type) {
      printValue(key ?? 'Type', obj.toString());
    } else if (obj is Exception) {
      printValue(key ?? 'Exception', obj.toString());
    } else {
      debugPrint('$indent${key ?? "Object"} (${obj.runtimeType}): $obj');
    }
  }

  line(label);
  recurse(object);
  line(label);
}
