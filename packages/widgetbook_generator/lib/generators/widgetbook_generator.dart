import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:widgetbook_generator/extensions/list_extension.dart';
import 'package:widgetbook_generator/generators/app_generator.dart';
import 'package:widgetbook_generator/generators/imports_generator.dart';
import 'package:widgetbook_generator/generators/main_generator.dart';
import 'package:widgetbook_generator/models/widgetbook_theme_data.dart';

class WidgetbookGenerator extends GeneratorForAnnotation<WidgetbookApp> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Verification that only one light and one dark theme exist
    final themeData = await loadDataFromJson<WidgetbookThemeData>(
      buildStep,
      '**.theme.widgetbook.json',
      (map) => WidgetbookThemeData.fromMap(map),
    );

    WidgetbookThemeData? lightTheme =
        themeData.firstWhereOrDefault((element) => !element.isDarkTheme);
    WidgetbookThemeData? darkTheme =
        themeData.firstWhereOrDefault((element) => element.isDarkTheme);

    final buffer = StringBuffer();
    buffer.writeln(
      generateImports(
        [
          ...themeData,
        ],
      ),
    );
    buffer.writeln(
      generateMain(),
    );
    buffer.writeln(
      generateWidgetbook(
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      ),
    );

    return buffer.toString();
  }
}

Future<List<T>> loadDataFromJson<T>(
  BuildStep buildStep,
  String extension,
  T Function(Map<String, dynamic>) fromMap,
) async {
  final glob = Glob(extension);
  final widgetbookData = <T>[];
  await for (final id in buildStep.findAssets(glob)) {
    List jsons = jsonDecode(await buildStep.readAsString(id)) as List;
    List<T> something = jsons.map<T>((json) {
      return fromMap(json);
    }).toList();

    widgetbookData.addAll(something);
  }
  return widgetbookData;
}
