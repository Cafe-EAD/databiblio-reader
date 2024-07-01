// ignore_for_file: use_build_context_synchronously

import 'package:epub_view/epub_view.dart';
import 'package:epub_view_example/model/bookmarkinfo.dart';
import 'package:epub_view_example/network/network_utils.dart';
import 'package:epub_view_example/network/rest.dart';
import 'package:flutter/material.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';

class BookmarkBottomSheet extends StatefulWidget {
  final bool isBookmarkMarked;
  final Function() onBookmarkToggle;
  final Function() onClose;
  final TabController tabController;
  final List<Bookmarkedinfo> bookmarksinfo;
  final EpubChapterViewValue? chapterValue;
  final EpubController epubReaderController;
  final Function() onBookmarkAdded;

  const BookmarkBottomSheet({
    Key? key,
    required this.isBookmarkMarked,
    required this.onBookmarkToggle,
    required this.onClose,
    required this.tabController,
    required this.bookmarksinfo,
    required this.chapterValue,
    required this.epubReaderController,
    required this.onBookmarkAdded,
  }) : super(key: key);

  @override
  _BookmarkBottomSheetState createState() => _BookmarkBottomSheetState();
}

class _BookmarkBottomSheetState extends State<BookmarkBottomSheet> {
  final List<Map<String, dynamic>> bookmarkFake = [
    {
      "local": "Chapter I. - Parágrafo 1",
      "conteudo":
          "BILLY BYRNE was a product of the streets and alleys of Chicago's great West Side. From Halsted to Robey, and from Grand Avenue to Lake Street there was scarce a bartender whom Billy knew not by his first name. And, in proportion to their number which was considerably less, he knew the patrolmen and plain clothes men equally as well, but not so pleasantly.",
    },
    {
      "local": "Chapter II. - Parágrafo 1",
      "conteudo":
          "WHEN Billy opened his eyes again he could not recall, for the instant, very much of his recent past. At last he remembered with painful regret the drunken sailor it had been his intention to roll. He felt deeply chagrined that his rightful prey should have escaped him. He couldn't understand how it had happened.",
    },
    {
      "local": "Chapter II. - Parágrafo 3",
      "conteudo":
          "His head ached frightfully and he was very sick. So sick that the room in which he lay seemed to be rising and falling in a horribly realistic manner. Every time it dropped it brought Billy's stomach nearly to his mouth.",
    },
    {
      "local": "Chapter IV. - Parágrafo 4",
      "conteudo":
          "Ward was pleased that he had not been forced to prolong the galling masquerade of valet to his inferior officer. He was hopeful, too,",
    },
    {
      "local": "Chapter V. - Parágrafo 14",
      "conteudo":
          "The girl made no comment, but Divine saw the contempt in her face.",
    },
  ];
  final TextEditingController _noteController = TextEditingController();
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
                  onTap: () async {
                    if (widget.bookmarksinfo.any(
                      (bookmark) =>
                          bookmark.bookmarkedindex ==
                          widget.chapterValue?.chapterNumber,
                    )) {
                      try {
                        print("Remover");
                        Bookmarkedinfo bookmarkToRemove =
                            widget.bookmarksinfo.firstWhere(
                          (bookmark) =>
                              bookmark.bookmarkedindex ==
                              widget.chapterValue?.chapterNumber,
                        );
                        // Obtém o ID do bookmark encontrado
                        int bookmarkIdToRemove = bookmarkToRemove.id!;
                        print(bookmarkIdToRemove);
                        await (handleResponse(
                            await removeBookmarkInfo(bookmarkIdToRemove)));
                        widget.onBookmarkAdded();
                      } catch (e) {
                        widget.onBookmarkAdded();
                        print('Erro ao criar bookmark: ${e.toString()}');
                      }
                    } else {
                      print("Marcar");
                      try {
                        await (handleResponse(await postBookmarkInfo(
                            1, 1, widget.chapterValue!.chapterNumber)));
                        widget.onBookmarkAdded();
                      } catch (e) {
                        widget.onBookmarkAdded();
                        print('Erro ao criar bookmark: ${e.toString()}');
                      }
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.bookmarksinfo.any(
                          (bookmark) =>
                              bookmark.bookmarkedindex ==
                              widget.chapterValue?.chapterNumber,
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
                              widget.chapterValue?.chapterNumber,
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
                      return Container(
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
                                  FutureBuilder<String>(
                                    future: _getChapterTitleByIndex(
                                        widget.epubReaderController,
                                        widget
                                            .bookmarksinfo[
                                                widget.bookmarksinfo.length -
                                                    index -
                                                    1]
                                            .bookmarkedindex!
                                            .toInt()),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Text(
                                          snapshot.data ??
                                              'Título não disponível',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                            'Erro ao carregar o título do capítulo');
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    },
                                  ),
                                  Text(widget
                                      .bookmarksinfo[
                                          widget.bookmarksinfo.length -
                                              index -
                                              1]
                                      .id
                                      .toString()),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getNote(widget
                                        .bookmarksinfo[
                                            widget.bookmarksinfo.length -
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
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _showNoteDialog(
                                      context,
                                      widget.bookmarksinfo[
                                          widget.bookmarksinfo.length -
                                              index -
                                              1],
                                    );
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    _showDeleteDialog(
                                      context,
                                      widget.bookmarksinfo[
                                          widget.bookmarksinfo.length -
                                              index -
                                              1],
                                    );
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SingleChildScrollView(
                  child: ListView.builder(
                    itemCount: bookmarkFake.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bookmarkFake[index]["local"]}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${bookmarkFake[index]["conteudo"]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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

  void _showNoteDialog(BuildContext context, Bookmarkedinfo bookmark) async {
    TextEditingController _noteController = TextEditingController(
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
              controller: _noteController,
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
                  await (handleResponse(await postBookmarkNotesInfo(
                      bookmark.id!.toInt(), _noteController.text)));
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                } catch (e) {
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
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

  void _showDeleteDialog(BuildContext context, Bookmarkedinfo bookmark) async {
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
                  await (handleResponse(
                      await removeBookmarkNotesInfo(bookmark.id!.toInt())));
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
                } catch (e) {
                  Navigator.pop(context);
                  widget.onBookmarkAdded();
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
}

Future<String> _getChapterTitleByIndex(
    EpubController controller, int index) async {
  final epubBook = await controller.document;
  final chapter = epubBook.Chapters![index - 1];
  return chapter.Title ?? 'Título não disponível';
}

_getNote(note) {
  try {
    return note[0].notetext;
  } catch (e) {
    return '';
  }
}
