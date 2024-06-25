import 'package:flutter/material.dart';

class BookmarkBottomSheet extends StatefulWidget {
  final bool isBookmarkMarked;
  final Function() onBookmarkToggle;
  final Function() onClose;
  final TabController tabController;
  final List<Map<String, dynamic>> bookmarkFake;

  const BookmarkBottomSheet({
    Key? key,
    required this.isBookmarkMarked,
    required this.onBookmarkToggle,
    required this.onClose,
    required this.tabController,
    required this.bookmarkFake,
  }) : super(key: key);

  @override
  _BookmarkBottomSheetState createState() => _BookmarkBottomSheetState();
}

class _BookmarkBottomSheetState extends State<BookmarkBottomSheet> {
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
                  onTap: widget.onBookmarkToggle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isBookmarkMarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Theme.of(context).colorScheme.onBackground,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isBookmarkMarked
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
                    itemCount: widget.bookmarkFake.length,
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
                                  Text(
                                    '${widget.bookmarkFake[index]["local"]}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${widget.bookmarkFake[index]["conteudo"]}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {},
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
                    itemCount: widget.bookmarkFake.length,
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
                              '${widget.bookmarkFake[index]["conteudo"]}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.bookmarkFake[index]["local"]}',
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
}
