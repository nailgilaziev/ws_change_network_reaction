import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConState issue',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String wsurl = 'ws://echo.websocket.org';

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();

  Future<WebSocket> wsFuture;
  WebSocket ws;
  Exception ex;
  String transferredData;

  void initws() {
    transferredData = null;
    ex = null;
    ws = null;
    wsFuture =
        WebSocket.connect(widget.wsurl).timeout(Duration(seconds: 15)).then(
          _configureWsAfterConnecting,
          onError: (Object e) => tPrint('connect.onError $e'),
        );
    tPrint('connect to ${widget.wsurl} requested');
  }

  FutureOr<WebSocket> _configureWsAfterConnecting(WebSocket ws) {
    this.ws = ws;
    ws.handleError((Object e) {
      tPrint('ws.handleError $e');
    });
    // ignore: avoid_annotating_with_dynamic
    ws.done.then((dynamic d) {
      // ignore: avoid_as
      final ws = d as WebSocket;
      final details =
          'closecode ${ws.closeCode} closeReason ${ws
          .closeReason} readyState ${ws.readyState}';
      return tPrint('ws.done.then with details:\n$details');
    });

    ws.listen(
      // ignore: avoid_annotating_with_dynamic
          (dynamic d) => tPrint('ws.listen received = $d'),
      onError: (Object e) => tPrint('ws.listen.onError $e'),
      onDone: () => tPrint('ws.listen.onDone called'),
    );
    tPrint('connect successfully established');
    return ws;
  }

  void tPrint(String msg) {
    print(DateTime.now().toString() + '   ' + msg);
  }

  @override
  void initState() {
    initws();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConState issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: RaisedButton(
                onPressed: () {
                  if (ws == null) {
                    print('ws is not inited yet');
                    return;
                  }
                  print('ready state ${ws.readyState}');
                  print('close code ${ws.closeCode}');
                  print('close reason ${ws.closeReason}');
                  print('extensions ${ws.extensions}');
                  print('protocol ${ws.protocol}');
                },
                child: const Text('check state'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ),
    );
  }

  void _sendMessage() {
    if (ws != null) {
      var text = _controller.text;
      if (text.isNotEmpty) {
        ws.add(text);
        tPrint('sended $text');
        _controller.text = '';
      }
    }
  }

  @override
  void dispose() {
    ws.close();
    super.dispose();
  }
}
