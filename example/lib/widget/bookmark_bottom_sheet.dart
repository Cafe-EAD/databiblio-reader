// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:epub_view/epub_view.dart';
import 'package:epub_view_example/model/bookmark.dart';
import 'package:epub_view_example/model/highlight_model.dart';
import 'package:epub_view_example/network/rest.dart';
import 'package:flutter/material.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
import 'package:html/parser.dart';

class BookmarkBottomSheet extends StatefulWidget {
  final bool isBookmarkMarked;
  final Function() onBookmarkToggle;
  final Function() onClose;
  final TabController tabController;
  final List<BookmarkModel> bookmarksinfo;
  final List<HighlightModel> highlightsinfo;
  final EpubChapterViewValue? chapterValue;
  final EpubController epubReaderController;
  final Function() onBookmarkAdded;
  final int bookId;
  final int userId;
  final Map<String, int> chapterStartIndices;
  final Function(int) onBookmarkTap;

  const BookmarkBottomSheet({
    Key? key,
    required this.isBookmarkMarked,
    required this.onBookmarkToggle,
    required this.onClose,
    required this.tabController,
    required this.bookmarksinfo,
    required this.highlightsinfo,
    required this.chapterValue,
    required this.epubReaderController,
    required this.onBookmarkAdded,
    required this.bookId,
    required this.userId,
    required this.chapterStartIndices,
    required this.onBookmarkTap,
  }) : super(key: key);

  @override
  _BookmarkBottomSheetState createState() => _BookmarkBottomSheetState();
}

class _BookmarkBottomSheetState extends State<BookmarkBottomSheet> {
  bool _isClickInProgress = false;
  List<int> chapterQtd = [];
  @override
  void initState() {
    super.initState();
    loadChapter(widget.epubReaderController);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 400,
            offset: const Offset(0, 5),
            spreadRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _isClickInProgress ? null : _handleTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.bookmarksinfo.any(
                          (bookmark) =>
                              bookmark.bookmarkedindex ==
                              widget.epubReaderController.currentValue!
                                  .chapterNumber,
                        )
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Theme.of(context).colorScheme.onBackground,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.bookmarksinfo.any(
                          (bookmark) =>
                              bookmark.bookmarkedindex ==
                              widget.epubReaderController.currentValue!
                                  .chapterNumber,
                        )
                            ? 'Desmarcar essa página'
                            : 'Marcar essa página',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: widget.tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                text: 'Bookmarks',
              ),
              Tab(text: 'Highlights'),
            ],
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 3,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: widget.tabController,
              children: [
                SingleChildScrollView(
                  child: ListView.builder(
                    itemCount: widget.bookmarksinfo.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          int? startIndex = await _getStartIndexByIndex(
                              widget.epubReaderController,
                              widget
                                  .bookmarksinfo[
                                      widget.bookmarksinfo.length - index - 1]
                                  .bookmarkedindex!
                                  .toInt());
                          if (startIndex != null) {
                            widget.onBookmarkTap(startIndex);
                          } else {
                            print('startIndex é nulo para o bookmark $index');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.bookmarksinfo[widget
                                                        .bookmarksinfo.length -
                                                    index -
                                                    1].title??'Erro ao carregar o título do capítulo'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _getNote(widget
                                                .bookmarksinfo[widget
                                                        .bookmarksinfo.length -
                                                    index -
                                                    1]
                                                .note),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                _showNoteDialog(
                                                  context,
                                                  widget.bookmarksinfo[widget
                                                          .bookmarksinfo
                                                          .length -
                                                      index -
                                                      1],
                                                );
                                              },
                                              icon: Icon(
                                                Icons.edit,
                                                size: 15,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onBackground,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _getNote(widget
                                                        .bookmarksinfo[widget
                                                                .bookmarksinfo
                                                                .length -
                                                            index -
                                                            1]
                                                        .note) !=
                                                    ''
                                                ? IconButton(
                                                    onPressed: () {
                                                      _showDeleteDialog(
                                                        context,
                                                        widget.bookmarksinfo[
                                                            widget.bookmarksinfo
                                                                    .length -
                                                                index -
                                                                1],
                                                      );
                                                    },
                                                    icon: Icon(
                                                      Icons.close,
                                                      size: 15,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onBackground,
                                                    ),
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SingleChildScrollView(
                  child: ListView.builder(
                    itemCount: widget.highlightsinfo.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      int? startindexInt = int.tryParse(
                          widget.highlightsinfo[index].startindex!);
                      String? chapter = _obterTituloDoCapitulo(startindexInt!);

                      return Dismissible(
                        key: Key(
                          widget.highlightsinfo[index].highlighted_text
                              .toString(),
                        ),
                        confirmDismiss: (direction) async {
                          return await _showConfirmationDialog(
                            context,
                            widget.highlightsinfo[index].highlightid,
                          );
                        },
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          // width: 10,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.85,
                                    child: Text(
                                      '${widget.highlightsinfo[index].highlighted_text}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$chapter - Parágrafo:  ${widget.highlightsinfo[index].paragraph}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showDeleteHighlightDialog(context,
                                      widget.highlightsinfo[index].highlightid);
                                },
                                child:
                                    const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _obterTituloDoCapitulo(int startIndex) {
    for (final entry in widget.chapterStartIndices.entries) {
      if (entry.value == startIndex) {
        return entry.key.toString();
      }
    }
    return "Não foi possivel encontrar";
  }

  void _showNoteDialog(BuildContext context, BookmarkModel bookmark) async {
    TextEditingController noteController = TextEditingController(
      text: bookmark.note?.isNotEmpty == true ? bookmark.note![0].notetext : '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            bookmark.note?.isNotEmpty == true
                ? 'Editar Nota'
                : 'Adicionar Nota',
          ),
          content: SingleChildScrollView(
            child: TextField(
              controller: noteController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Digite sua nota aqui...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await postBookmarkNote(
                      bookmark.id!.toInt(), noteController.text);
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                } catch (e) {
                  Navigator.pop(context);
                  print('Erro ao atualizar nota: ${e.toString()}');
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, BookmarkModel bookmark) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar Nota'),
          content: const Text('Tem certeza que deseja apagar esta nota?'),
          backgroundColor: Theme.of(context).colorScheme.background,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  deleteBookmarkNote(bookmark.note![0].id!.toInt());
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                } catch (e) {
                  Navigator.pop(context);
                  print('Erro ao apagar nota: ${e.toString()}');
                }
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteHighlightDialog(BuildContext context, int? highlighId) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar Highlight'),
          content: const Text('Tem certeza que deseja apagar esta Highlight?'),
          backgroundColor: Theme.of(context).colorScheme.background,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deleteHighlight(highlighId!);
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                } catch (e) {
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                  print('Erro ao apagar highlight: ${e.toString()}');
                }
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, int? highlighId) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Apagar Highlight'),
          content: const Text('Tem certeza que deseja apagar esta Highlight?'),
          backgroundColor: Theme.of(context).colorScheme.background,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deleteHighlight(highlighId!);
                  widget.onBookmarkAdded();
                  Navigator.pop(context, true);
                } catch (e) {
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                  print('Erro ao apagar highlight: ${e.toString()}');
                }
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTap() async {
    setState(() {
      _isClickInProgress = true;
    });

    if (widget.bookmarksinfo.any(
      (bookmark) =>
          bookmark.bookmarkedindex ==
          widget.epubReaderController.currentValue!.chapterNumber,
    )) {
      try {
        // print("Remover");
        BookmarkModel bookmarkToRemove = widget.bookmarksinfo.firstWhere(
          (bookmark) =>
              bookmark.bookmarkedindex ==
              widget.epubReaderController.currentValue!.chapterNumber,
        );
        int bookmarkIdToRemove = bookmarkToRemove.id!;
        await deleteBookmark(bookmarkIdToRemove);
        widget.onBookmarkAdded();
        setState(() {
          _isClickInProgress = false;
        });
      } catch (e) {
        widget.onBookmarkAdded();
        print('Erro ao criar bookmark: ${e.toString()}');
        setState(() {
          _isClickInProgress = false;
        });
      }
    } else {
      // print("Marcar");
      try {
        var title ='${widget.epubReaderController.currentValue!.chapter!.Title??''} - Página ${widget.epubReaderController.currentPage.value}';
        await postBookmark(
          widget.bookId == 0 ? 1 : widget.bookId,
          widget.userId == 0 ? 1 : widget.userId,
          widget.epubReaderController.currentValue!.chapterNumber,
          title
        );
        widget.onBookmarkAdded();
        setState(() {
          _isClickInProgress = false;
        });
      } catch (e) {
        widget.onBookmarkAdded();
        print('Erro ao criar bookmark: ${e.toString()}');
        setState(() {
          _isClickInProgress = false;
        });
      }
    }
  }

  Future<void> loadChapter(EpubController controller) async {
    final epubBook = await controller.document;

    for (int i = 0; i < epubBook.Chapters!.length; i++) {
      chapterQtd
          .add(parse(epubBook.Chapters![i].HtmlContent).body!.text.length);
    }
  }

  Future<String> _getChapterTitleByIndex(
      EpubController controller, int index) async {
    final epubBook = await controller.document;
    final chapter = epubBook.Chapters![index - 1];
    int total = chapterQtd.reduce((a, b) => a + b);
    double pagTam = total / charactersPerPage;
    int totalCap = 0;
    int pag = 0;

    for (int i = 0; i < index; i++) {
      totalCap += chapterQtd[i];
    }

    pag = (totalCap / pagTam).floor();
    return chapter.Title == null
        ? 'Título não disponível'
        : '${chapter.Title}-$pag';
  }
}

_getStartIndexByIndex(EpubController controller, int index) async {
  final epubBook = await controller.document;
  final chapter = epubBook.Chapters![index - 1];
  final startIndex = controller.chapterStartIndices[chapter.Title];
  return startIndex;
}

_getNote(note) {
  try {
    return note[0].notetext;
  } catch (e) {
    return '';
  }
}
