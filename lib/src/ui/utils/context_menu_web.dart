// context_menu_web.dart
import 'dart:html' as html;

void preventContextMenu() {
  html.document.onContextMenu.listen((evt) => evt.preventDefault());
}
