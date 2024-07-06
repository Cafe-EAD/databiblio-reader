part of '../ui/epub_view.dart';

typedef EpubViewBuilder<T> = Widget Function(
  /// Build context
  BuildContext context,

  /// All passed builders
  EpubViewBuilders<T> builders,

  /// Document loading state
  EpubViewLoadingState state,

  /// Loaded result builder
  WidgetBuilder loadedBuilder,

  /// Error of pdf loading
  Exception? loadingError,
);

typedef ChaptersBuilder = Widget Function(
  BuildContext context,
  EpubViewBuilders builders,
  EpubBook document,
  EpubController c,
  List<EpubChapter> chapters,
  List<Paragraph> paragraphs,
  int index,
  int chapterIndex,
  int paragraphIndex,
  ExternalLinkPressed onExternalLinkPressed,
  OnSelectedChanged onSelectedChanged,
  OnTextToSpeech onTextToSpeech,
);

typedef ChapterDividerBuilder = Widget Function(EpubChapter value);
typedef ParagraphBuilder = Widget Function(
  String text,
  int paragraphIndex,
);

class EpubViewBuilders<T> {
  /// Root view builder
  final EpubViewBuilder<T> builder;

  final ChaptersBuilder chapterBuilder;
  final ChapterDividerBuilder chapterDividerBuilder;

  /// Widget showing when epub page loading
  final WidgetBuilder? loaderBuilder;

  /// Show document loading error message inside [EpubView]
  final Widget Function(BuildContext, Exception error)? errorBuilder;

  /// Additional options for builder
  final T options;

  final ParagraphBuilder? paragraphBuilder;

  // final void Function(int? index) onParagraphDisplayed;
  final void Function(int index) onParagraphDisplayed;

  const EpubViewBuilders({
    required this.options,
    this.builder = _EpubViewState._builder,
    this.chapterBuilder = _EpubViewState._chapterBuilder,
    this.chapterDividerBuilder = _EpubViewState._chapterDividerBuilder,
    this.loaderBuilder,
    this.errorBuilder,
    this.paragraphBuilder,
    this.onParagraphDisplayed = _emptyParagraphFunction,
  });
  static void _emptyParagraphFunction(int index) {}
}

enum EpubViewLoadingState {
  loading,
  error,
  success,
}

class CustomBuilderOptions {
  final Duration loaderSwitchDuration;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final EdgeInsetsGeometry chapterPadding;
  final EdgeInsetsGeometry paragraphPadding;
  TextStyle textStyle;

  CustomBuilderOptions({
    this.loaderSwitchDuration = const Duration(seconds: 1),
    this.transitionBuilder = CustomBuilderOptions._transitionBuilder,
    this.chapterPadding = const EdgeInsets.all(8),
    this.paragraphPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle = const TextStyle(
      height: 1.25,
      fontSize: 15,
    ),
  });

  static Widget _transitionBuilder(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);
}

class DefaultBuilderOptions {
  final Duration loaderSwitchDuration;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final EdgeInsetsGeometry chapterPadding;
  final EdgeInsetsGeometry paragraphPadding;
  final TextStyle textStyle;

  const DefaultBuilderOptions({
    this.loaderSwitchDuration = const Duration(seconds: 1),
    this.transitionBuilder = DefaultBuilderOptions._transitionBuilder,
    this.chapterPadding = const EdgeInsets.all(8),
    this.paragraphPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle =
        const TextStyle(height: 1.25, fontSize: 16, fontFamily: "OpenDyslexic"),
  });

  static Widget _transitionBuilder(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);
}
