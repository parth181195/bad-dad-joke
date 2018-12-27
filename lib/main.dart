import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

void main() {
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((orientation) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bad Dad Joke',
      home: Scaffold(
        appBar: PreferredSize(
            child: JokeAppBar(), preferredSize: Size(double.maxFinite, 54)),
        body: MyHomePage(),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> typesOfDad = [
    'Cranky',
    'Angry',
    'Hungry',
    'Calm',
    'Sleepy',
    'Corny'
  ];
  GlobalKey _globalKey = new GlobalKey();

  Future<String> getAJoke() async {
    String jokeData;
    var res = await http.get('https://icanhazdadjoke.com/',
        headers: {"Accept": "application/json"}).then((joke) {
      if (joke.statusCode == 200) {
        print(joke.body);
        jokeData = json.decode(joke.body)['joke'];
      }
    });
    return jokeData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getAJoke(),
      builder: (context, snapshot) {
        return Stack(
          children: <Widget>[
            SafeArea(
              child: snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.done
                  ? RepaintBoundary(
                      key: _globalKey,
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              QuoteImage(),
                              Text(
                                '${snapshot.data}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'Roboto slab', fontSize: 25.0),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  'A ${typesOfDad[Random().nextInt(typesOfDad.length - 1)]} Dad',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'League spartan',
                                      color: Colors.blueAccent),
                                ),
                              ),
                              QuoteImage(
                                isTopImage: false,
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildBottomBar(
                  snapshot.data,
                  snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.done),
            ),
            snapshot.hasData && snapshot.connectionState == ConnectionState.done
                ? Container()
                : Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.0,
                    ),
                  )
          ],
        );
      },
    );
  }

  Widget buildBottomBar(String joke, bool enabled) {
    print(enabled);
    return SizedBox(
      width: double.maxFinite,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.share,
                ),
                color: Colors.black.withOpacity(0.5),
                disabledColor: Colors.black12,
                onPressed: enabled
                    ? () async {
                        RenderRepaintBoundary boundary =
                            _globalKey.currentContext.findRenderObject();
                        ui.Image image =
                            await boundary.toImage(pixelRatio: 3.0);
                        ByteData byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png);
                        await EsysFlutterShare.shareImage(
                            'img.png', byteData, 'title');
                      }
                    : null,
                tooltip: 'Share Image',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.content_copy,
                ),
                color: Colors.black.withOpacity(0.5),
                disabledColor: Colors.black12,
                onPressed: enabled
                    ? () {
                        Clipboard.setData(ClipboardData(text: joke))
                            .then((data) {
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Joke coppied to clipboard',
                              style: TextStyle(color: Colors.white),
                            ),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.blueAccent,
                          ));
                        });
                      }
                    : null,
                tooltip: 'Copy to clipboard',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  Icons.refresh,
                ),
                tooltip: 'Crack a new one!',
                color: Colors.black.withOpacity(0.5),
                disabledColor: Colors.black12,
                onPressed: enabled
                    ? () {
                        setState(() {});
                      }
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class QuoteImage extends StatelessWidget {
  final bool isTopImage;

  const QuoteImage({Key key, this.isTopImage = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: EdgeInsets.only(
            top: isTopImage ? 0.0 : 10.0, bottom: isTopImage ? 10.0 : 0.0),
        child: Align(
          alignment: isTopImage ? Alignment.topLeft : Alignment.bottomRight,
          child: SizedBox(
            child: FadeInImage(
              fadeInDuration: Duration(milliseconds: 300),
              placeholder: MemoryImage(kTransparentImage),
              fadeInCurve: Curves.easeInOut,
              image: AssetImage(
                isTopImage
                    ? 'assets/images/left-quote.png'
                    : 'assets/images/right-quote.png',
              ),
            ),
            height: 80,
          ),
        ),
      ),
    );
  }
}

class JokeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Platform.isAndroid
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                  tooltip: 'Exit App',
                  onPressed: () {
                    SystemNavigator.pop();
                  })
              : Container(),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Text(
              'Bad Joke',
              style: TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'Sarabun',
                  color: Colors.blueAccent),
            ),
          )
        ],
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
    );
  }
}
