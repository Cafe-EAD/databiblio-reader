import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class BottomSheetContent extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final Function(double) changeFontSize;
  final CustomBuilderOptions builderOptions;
  final Function() changeFontFamily;


  BottomSheetContent({
    required this.onToggleTheme,
    required this.changeFontSize,
    required this.builderOptions, required this.changeFontFamily,
  });

  @override
  _BottomSheetContentState createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
   
    bool disl = false;


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
             Text(
              'Tamanho da fonte',
              style:  widget.builderOptions.textStyle,
            ),
            const Gap(10),
            FontSizeAdjuster(changeFontSize: _updateFontSize, initialFontSize: widget.builderOptions.textStyle.fontSize!),
            const Gap(10),
             Text(
              'Fonte disléxica',
              style:  widget.builderOptions.textStyle,
            ),
            const Gap(10),
            Switch(
              activeColor: Colors.white,
              activeTrackColor: Colors.green[300],
              value: disl,
              onChanged: (newValue) {
                setState(() {
                  widget.changeFontFamily();
                  disl = newValue;
                });
              },
            ),
            const Gap(10),
             Text(
              'Tema Escuro',
              style:  widget.builderOptions.textStyle,
            ),
            const Gap(10),
            Switch(
              activeColor: Colors.white,
              activeTrackColor: Colors.indigo,
              inactiveThumbColor: Colors.amber,
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                widget.onToggleTheme(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showCustomModalBottomSheet(BuildContext context, Function(bool) onToggleTheme, Function(double) changeFontSize, CustomBuilderOptions builderOptions, Function() changeFontFamily) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return BottomSheetContent(
        onToggleTheme: onToggleTheme,
        changeFontSize: changeFontSize,
        builderOptions: builderOptions, changeFontFamily: changeFontFamily,
      );
    },
  );
}

class FontSizeAdjuster extends StatefulWidget {
  final Function(double) changeFontSize;
  final double initialFontSize;

  FontSizeAdjuster({required this.changeFontSize, required this.initialFontSize});

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
