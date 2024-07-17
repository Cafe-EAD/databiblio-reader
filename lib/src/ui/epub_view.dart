import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:epub_view/src/data/epub_cfi_reader.dart';
import 'package:epub_view/src/data/epub_parser.dart';
import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
import 'package:epub_view/src/data/models/paragraph.dart' as epub_paragraph;
import 'package:epub_view/src/data/models/paragraph.dart';
import 'package:epub_view/src/network/rest.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

export 'package:epubx/epubx.dart' hide Image;

export 'utils/context_menu_stub.dart' if (dart.library.html) 'utils/context_menu_web.dart';

part '../epub_controller.dart';
part '../helpers/epub_view_builders.dart';

const _minTrailingEdge = 0.55;
const _minLeadingEdge = -0.05;

typedef ExternalLinkPressed = void Function(String href);
typedef OnSelectedChanged = void Function(String? selection);
typedef OnTextToSpeech = void Function(String text);
typedef OnHighlight = void Function(String text); //TODO
int? index;

enum TtsState { playing, stopped, paused, continued }

class EpubView extends StatefulWidget {
  const EpubView({
    required this.controller,
    this.onExternalLinkPressed,
    this.onChapterChanged,
    this.onDocumentLoaded,
    this.onDocumentError,
    this.builders = const EpubViewBuilders(
      options: DefaultBuilderOptions(),
      onParagraphDisplayed: _emptyParagraphFunction,
    ),
    this.shrinkWrap = false,
    Key? key,
  }) : super(key: key);

  static void _emptyParagraphFunction(int index) {}
  final EpubController controller;
  final ExternalLinkPressed? onExternalLinkPressed;
  final bool shrinkWrap;
  final void Function(EpubChapterViewValue? value)? onChapterChanged;

  /// Called when a document is loaded
  final void Function(EpubBook document)? onDocumentLoaded;

  /// Called when a document loading error
  final void Function(Exception? error)? onDocumentError;

  /// Builders
  final EpubViewBuilders builders;

  @override
  State<EpubView> createState() => _EpubViewState();
}

class _EpubViewState extends State<EpubView> {
  Exception? _loadingError;
  ItemScrollController? _itemScrollController;
  ItemPositionsListener? _itemPositionListener;
  List<EpubChapter> _chapters = [];
  List<Paragraph> _paragraphs = [];
  EpubCfiReader? _epubCfiReader;
  EpubChapterViewValue? _currentValue;
  final _chapterIndexes = <int>[];
  static String? _selectedText = '';
  Timer? _pageNumberTimer;
  static const int _pageNumberDuration = 2000;

  late FlutterTts _flutterTts;
  TtsState ttsState = TtsState.stopped;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  EpubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _initTts();
    _itemScrollController = ItemScrollController();
    _itemPositionListener = ItemPositionsListener.create();
    _itemPositionListener?.itemPositions.addListener(_updatePageOnScroll); // Add this line
    _controller._attach(this);
    _controller.loadingState.addListener(() {
      switch (_controller.loadingState.value) {
        case EpubViewLoadingState.loading:
          break;
        case EpubViewLoadingState.success:
          widget.onDocumentLoaded?.call(_controller._document!);
          break;
        case EpubViewLoadingState.error:
          widget.onDocumentError?.call(_loadingError);
          break;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    _flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });

    _flutterTts.setVolume(volume);
    _flutterTts.setSpeechRate(rate);
    _flutterTts.setPitch(pitch);
  }

  @override
  void dispose() {
    _itemPositionListener!.itemPositions.removeListener(_updatePageOnScroll); // Add this line
    _controller._detach();
    _flutterTts.stop();
    super.dispose();
  }

  Future<bool> _init() async {
    if (_controller.isBookLoaded.value) {
      return true;
    }
    _chapters = parseChapters(_controller._document!);
    final parseParagraphsResult = parseParagraphs(_chapters, _controller._document!.Content);
    _paragraphs = parseParagraphsResult.flatParagraphs;
    _chapterIndexes.addAll(parseParagraphsResult.chapterIndexes);

    _epubCfiReader = EpubCfiReader.parser(
      cfiInput: _controller.epubCfi,
      chapters: _chapters,
      paragraphs: _paragraphs,
    );
    _itemPositionListener!.itemPositions.addListener(_changeListener);
    _controller.isBookLoaded.value = true;

    return true;
  }

  void _updatePageOnScroll() {
    _controller.updateCurrentPage();
  }

  void _changeListener() {
    if (_paragraphs.isEmpty || _itemPositionListener!.itemPositions.value.isEmpty) {
      return;
    }
    final position = _itemPositionListener!.itemPositions.value.first;
    final chapterIndex = _getChapterIndexBy(
      positionIndex: position.index,
      trailingEdge: position.itemTrailingEdge,
      leadingEdge: position.itemLeadingEdge,
    );
    final paragraphIndex = _getParagraphIndexBy(
      positionIndex: position.index,
      trailingEdge: position.itemTrailingEdge,
      leadingEdge: position.itemLeadingEdge,
    );
    _currentValue = EpubChapterViewValue(
      chapter: chapterIndex >= 0 ? _chapters[chapterIndex] : null,
      chapterNumber: chapterIndex + 1,
      paragraphNumber: paragraphIndex + 1,
      position: position,
    );
    _controller.currentValueListenable.value = _currentValue;
    widget.onChapterChanged?.call(_currentValue);
  }

  void _gotoEpubCfi(
    String? epubCfi, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
  }) {
    _epubCfiReader?.epubCfi = epubCfi;
    final index = _epubCfiReader?.paragraphIndexByCfiFragment;

    if (index == null) {
      print("Epub CFI index null");
      return;
    }

    _itemScrollController?.scrollTo(
      index: index,
      duration: duration,
      alignment: alignment,
      curve: curve,
    );
  }

  void _onTextToSpeech(String text) {
    if (text.isNotEmpty) {
      _flutterTts.speak(text);
    }
  }

  void _onHighlight(String? selectedText) {
    _controller.allParagraphs = _controller.getAllParagraphs();

    if (selectedText != null) {
      final selectedParagraph = _controller.allParagraphs.firstWhereOrNull(
        (paragraph) {
          String paragraphText = paragraph.element.text.replaceAll('\n', ' ');
          if (paragraphText.contains(selectedText)) {
            return true;
          } else {
            return false;
          }
        },
      );

      if (selectedParagraph != null) {
        int chapterIndex = _controller.currentValueListenable.value!.chapterNumber;
        final paragraphNode = selectedParagraph.element;
        final nodeIndex = paragraphNode.nodes
            .indexWhere((node) => node.text!.trim().contains(selectedText.trim()));
        final startIndex = _controller
            .chapterStartIndices[_controller.currentValueListenable.value?.chapter?.Title ?? ''];
        final selectionLength = selectedText.length;
        final chapter = chapterIndex.toString();
        final paragraph = nodeIndex.toString();
        final startindex = startIndex.toString();
        final selectionlength = selectionLength.toString();
        final highlightedText = selectedText.toString();

        postHighlight(
          _controller.userId == 0 ? 1 : _controller.userId,
          _controller.bookId == 0 ? 1 : _controller.bookId,
          chapter,
          paragraph,
          startindex,
          selectionlength,
          highlightedText,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highligth salvo com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highligth não foi salvo')),
        );
      }
    }
  }

  void _onSelectionChanged(String? selection) {
    _selectedText = selection ?? '';
    _controller.selectedText = selection;
  }

  void _onLinkPressed(String href) {
    if (href.contains('://')) {
      widget.onExternalLinkPressed?.call(href);
      return;
    }

    String? hrefIdRef;
    String? hrefFileName;

    if (href.contains('#')) {
      final dividedHref = href.split('#');
      if (dividedHref.length == 1) {
        hrefIdRef = href;
      } else {
        hrefFileName = dividedHref[0];
        hrefIdRef = dividedHref[1];
      }
    } else {
      hrefFileName = href;
    }

    if (hrefIdRef == null) {
      final chapter = _chapterByFileName(hrefFileName);
      if (chapter != null) {
        final cfi = _epubCfiReader?.generateCfiChapter(
          book: _controller._document,
          chapter: chapter,
          additional: ['/4/2'],
        );

        _gotoEpubCfi(cfi);
      }
      return;
    } else {
      final paragraph = _paragraphByIdRef(hrefIdRef);
      final chapter = paragraph != null ? _chapters[paragraph.chapterIndex] : null;

      if (chapter != null && paragraph != null) {
        final paragraphIndex = _epubCfiReader?.getParagraphIndexByElement(paragraph.element);
        final cfi = _epubCfiReader?.generateCfi(
          book: _controller._document,
          chapter: chapter,
          paragraphIndex: paragraphIndex,
        );

        _gotoEpubCfi(cfi);
      }

      return;
    }
  }

  Paragraph? _paragraphByIdRef(String idRef) => _paragraphs.firstWhereOrNull((paragraph) {
        if (paragraph.element.id == idRef) {
          return true;
        }

        return paragraph.element.children.isNotEmpty && paragraph.element.children[0].id == idRef;
      });

  EpubChapter? _chapterByFileName(String? fileName) => _chapters.firstWhereOrNull((chapter) {
        if (fileName != null) {
          if (chapter.ContentFileName!.contains(fileName)) {
            return true;
          } else {
            return false;
          }
        }
        return false;
      });

  int _getChapterIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    final posIndex = _getAbsParagraphIndexBy(
      positionIndex: positionIndex,
      trailingEdge: trailingEdge,
      leadingEdge: leadingEdge,
    );
    final index = posIndex >= _chapterIndexes.last
        ? _chapterIndexes.length
        : _chapterIndexes.indexWhere((chapterIndex) {
            if (posIndex < chapterIndex) {
              return true;
            }
            return false;
          });

    return index - 1;
  }

  int _getParagraphIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    final posIndex = _getAbsParagraphIndexBy(
      positionIndex: positionIndex,
      trailingEdge: trailingEdge,
      leadingEdge: leadingEdge,
    );

    final index = _getChapterIndexBy(positionIndex: posIndex);

    if (index == -1) {
      return posIndex;
    }

    return posIndex - _chapterIndexes[index];
  }

  int _getAbsParagraphIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    int posIndex = positionIndex;
    if (trailingEdge != null &&
        leadingEdge != null &&
        trailingEdge < _minTrailingEdge &&
        leadingEdge < _minLeadingEdge) {
      posIndex += 1;
    }

    return posIndex;
  }

  static Widget _chapterDividerBuilder(EpubChapter chapter) => Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0x24000000),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          chapter.Title ?? '',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static Widget _chapterBuilder(
    BuildContext context,
    EpubViewBuilders builders,
    EpubBook document,
    List<EpubChapter> chapters,
    List<Paragraph> paragraphs,
    int index,
    int chapterIndex,
    int paragraphIndex,
    ExternalLinkPressed onExternalLinkPressed,
    OnSelectedChanged onSelectedChanged,
    OnTextToSpeech onTextToSpeech,
    OnHighlight onHighlight,
  ) {
    if (paragraphs.isEmpty) {
      return Container();
    }

    final options = builders.options;

    return Column(
      children: <Widget>[
        if (chapterIndex >= 0 && paragraphIndex == 0)
          builders.chapterDividerBuilder(chapters[chapterIndex]),
        GestureDetector(
          onSecondaryTapDown: (details) {
            if ((_selectedText?.isNotEmpty ?? false) && kIsWeb) {
              _showContextMenu(
                context,
                details.globalPosition,
                onSelectedChanged,
                paragraphIndex,
                chapterIndex,
                index,
                builders,
                paragraphs,
                document,
                onHighlight,
              );
            }
          },
          child: SelectionArea(
            contextMenuBuilder: (context, selectableTextState) {
              return AdaptiveTextSelectionToolbar(
                anchors: selectableTextState.contextMenuAnchors,
                children: [
                  GestureDetector(
                    onTap: () {
                      onHighlight(_selectedText ?? '');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: const Text(
                        'Marcar Texto',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      onTextToSpeech(_selectedText ?? "");
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black,
                      child: const Text(
                        'Ouvir',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
            onSelectionChanged: (selection) {
              onSelectedChanged(selection?.plainText);
            },
            child: Html(
              data: paragraphs[index].element.outerHtml,
              onLinkTap: (href, _, __) => onExternalLinkPressed(href!),
              style: {
                'html': Style(
                  padding: HtmlPaddings.only(
                    top: (options.paragraphPadding as EdgeInsets?)?.top,
                    right: (options.paragraphPadding as EdgeInsets?)?.right,
                    bottom: (options.paragraphPadding as EdgeInsets?)?.bottom,
                    left: (options.paragraphPadding as EdgeInsets?)?.left,
                  ),
                ).merge(Style.fromTextStyle(options.textStyle)),
              },
              extensions: [
                TagExtension(
                  tagsToExtend: {"img"},
                  builder: (imageContext) {
                    final url = imageContext.attributes['src']!.replaceAll('../', '');
                    final content = Uint8List.fromList(document.Content!.Images![url]!.Content!);
                    return Image(
                      image: MemoryImage(content),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static void _showContextMenu(
      BuildContext context,
      Offset position,
      OnSelectedChanged onSelectedChanged,
      paragraphIndex,
      chapterIndex,
      index,
      builders,
      paragraphs,
      document,
      onHighlight) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'Marcar Texto',
          child: const Text('Marcar Texto'),
          onTap: () {
            onHighlight();
            print('teste');
            // print(paragraphIndex);
            // print(chapterIndex);
            // print(index);
            // print(builders);
            // print(paragraphs.toString());
            // print(document);

            // if (_controller.selectedText != null &&
            //     _controller.generateEpubCfi() != null &&
            //     _controller.currentValueListenable.value != null) {
            //   HighlightModel(
            //           value: _controller.currentValueListenable.value,
            //           selectedText: _controller.selectedText,
            //           cfi: _controller.generateEpubCfi())
            //       .printar();
            // }
          },
        ),
        PopupMenuItem(
          value: 'Ouvir',
          child: const Text('Ouvir'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLoaded(BuildContext context) {
    return ScrollConfiguration(
      behavior: _ScrollbarBehavior(),
      child: ScrollablePositionedList.builder(
        shrinkWrap: widget.shrinkWrap,
        initialScrollIndex: _epubCfiReader!.paragraphIndexByCfiFragment ?? 0,
        itemCount: _paragraphs.length,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionListener,
        itemBuilder: (BuildContext context, int index) {
          return widget.builders.chapterBuilder(
            context,
            widget.builders,
            widget.controller._document!,
            _chapters,
            _paragraphs,
            index,
            _getChapterIndexBy(positionIndex: index),
            _getParagraphIndexBy(positionIndex: index),
            _onLinkPressed,
            _onSelectionChanged,
            _onTextToSpeech,
            _onHighlight,
          );
        },
      ),
    );
  }

  static Widget _builder(
    BuildContext context,
    EpubViewBuilders builders,
    EpubViewLoadingState state,
    WidgetBuilder loadedBuilder,
    Exception? loadingError,
  ) {
    final Widget content = () {
      switch (state) {
        case EpubViewLoadingState.loading:
          return KeyedSubtree(
            key: const Key('epubx.root.loading'),
            child: builders.loaderBuilder?.call(context) ?? const SizedBox(),
          );
        case EpubViewLoadingState.error:
          return KeyedSubtree(
            key: const Key('epubx.root.error'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: builders.errorBuilder?.call(context, loadingError!) ??
                  Center(child: Text(loadingError.toString())),
            ),
          );
        case EpubViewLoadingState.success:
          return KeyedSubtree(
            key: const Key('epubx.root.success'),
            child: loadedBuilder(context),
          );
      }
    }();

    final options = builders.options;

    return AnimatedSwitcher(
      duration: options.loaderSwitchDuration,
      transitionBuilder: options.transitionBuilder,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builders.builder(
      context,
      widget.builders,
      _controller.loadingState.value,
      _buildLoaded,
      _loadingError,
    );
  }
}

class _ScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      interactive: true,
      child: child,
    );
  }
}
