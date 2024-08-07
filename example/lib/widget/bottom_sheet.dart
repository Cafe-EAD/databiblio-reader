import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../reader.dart';

class BottomSheetContent extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final Function(double) changeFontSize;
  final CustomBuilderOptions builderOptions;
  final Function() changeFontFamily;
  final bool themeMode;

  BottomSheetContent({
    required this.onToggleTheme,
    required this.changeFontSize,
    required this.builderOptions,
    required this.changeFontFamily,
    required this.themeMode,
  });

  @override
  _BottomSheetContentState createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {


  void _updateFontSize(double newFontSize) {
    setState(() {
      widget.changeFontSize(newFontSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Tamanho da fonte',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),
            FontSizeAdjuster(
                changeFontSize: _updateFontSize,
                initialFontSize: widget.builderOptions.textStyle.fontSize!),
            const Gap(10),
            const Text(
              'Fonte disléxica',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),
            Switch(
              value: disl,
              onChanged: (newValue) {
                setState(() {
                  widget.changeFontFamily();
                  disl = newValue;
                });
              },
            ),
            const Gap(10),
            const Text(
              'Tema Escuro',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),
            Switch(
              value: tema??widget.themeMode,
              onChanged: (value) {
                setState(() {
                  widget.onToggleTheme(value);
                  tema = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showCustomModalBottomSheet(
    BuildContext context,
    Function(bool) onToggleTheme,
    Function(double) changeFontSize,
    CustomBuilderOptions builderOptions,
    Function() changeFontFamily,
    bool themeMode) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return BottomSheetContent(
        onToggleTheme: onToggleTheme,
        changeFontSize: changeFontSize,
        builderOptions: builderOptions,
        changeFontFamily: changeFontFamily,
        themeMode: themeMode,
      );
    },
  );
}

class FontSizeAdjuster extends StatefulWidget {
  final Function(double) changeFontSize;
  final double initialFontSize;

  FontSizeAdjuster(
      {required this.changeFontSize, required this.initialFontSize});

  @override
  _FontSizeAdjusterState createState() => _FontSizeAdjusterState();
}

class _FontSizeAdjusterState extends State<FontSizeAdjuster> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.initialFontSize;
  }

  String getFontSizeLabel(double value) {
    switch (value.round()) {
      case 6:
        return "50%";
      case 9:
        return "75%";
      case 12:
        return "100%";
      case 15:
        return "125%";
      case 18:
        return "150%";
      case 21:
        return "175%";
      case 24:
        return "200%";
      default:
        return "${value.round()}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_fontSize > 6) _fontSize -= 3;
                  widget.changeFontSize(_fontSize);
                });
              },
              child: const Text('-'),
            ),
            const Gap(20),
            Text(
              _fontSize.toString(),
            ),
            const Gap(20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_fontSize < 24) _fontSize += 3;
                  widget.changeFontSize(_fontSize);
                });
              },
              child: const Text('+'),
            ),
          ],
        ),
        Slider(
          value: _fontSize,
          min: 6.0,
          max: 24.0,
          divisions: 6,
          label: getFontSizeLabel(_fontSize),
          onChanged: (newFontSize) {
            setState(() {
              _fontSize = newFontSize;
              widget.changeFontSize(newFontSize);
            });
          },
        ),
      ],
    );
  }
}
