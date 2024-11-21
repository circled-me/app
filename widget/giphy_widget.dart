import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class GiphyWidget extends StatefulWidget {
  final bool stickers;
  final String query;
  final Function(String) onSelected;
  const GiphyWidget({Key? key, required this.stickers, required this.query, required this.onSelected}) : super(key: key);

  void show(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (ctx, anim1, anim2) => this,
      transitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (ctx, anim1, anim2, child) => SlideTransition(position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim1), child: child),
    ));
  }

  @override
  State<GiphyWidget> createState() => _GiphyWidgetState();
}

class _GiphyWidgetState extends State<GiphyWidget> {
  static const apiKey = String.fromEnvironment("GIPHY_API_KEY");
  late Future<Response> apiResponse;

  Future<Response> newApiRequest(String query) {
    final params = "?api_key=$apiKey&q=$query&limit=50&offset=0&rating=g&lang=en";
    if (query.isEmpty) {
      return get(Uri.parse("https://api.giphy.com/v1/"+(widget.stickers ? "stickers" : "gifs")+"/trending"+params));
    }
    return get(Uri.parse("https://api.giphy.com/v1/"+(widget.stickers ? "stickers" : "gifs")+"/search"+params));
  }
  @override
  void initState() {
    super.initState();
    apiResponse = newApiRequest(widget.query);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Column(
        children: [
          const SizedBox(height: 100,),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Search"+(widget.stickers ? " stickers" : " GIFs"),
                      // border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        apiResponse = newApiRequest(value);
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: Image.asset("img/giphy.png")
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: FutureBuilder<Response>(future: apiResponse, builder: (context, snapshot) {
                if (snapshot.data == null || snapshot.connectionState != ConnectionState.done) {
                  return Center(child: CircularProgressIndicator(color: Colors.grey.withOpacity(0.25)));
                }
                // TODO: Handle errors
                final json = jsonDecode(snapshot.data!.body);
                final data = json["data"] as List<dynamic>;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    crossAxisCount: 3,
                  ),
                  padding: const EdgeInsets.fromLTRB(2, 10, 2, 2),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        widget.onSelected(data[index]["images"]["downsized"]["url"]);
                        Navigator.of(context).pop();
                      },
                      child: CachedNetworkImage(
                        imageUrl: data[index]["images"]["downsized"]["url"],
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.grey.withOpacity(0.25)))
                      )
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
