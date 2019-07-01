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
  StreamSubscription<dynamic> wsSubscription;

  void _initws() {
    final f =
        WebSocket.connect(widget.wsurl).timeout(Duration(seconds: 15)).then(
          _configureWsAfterConnecting,
          onError: (Object e) => tPrint('connect.onError $e'),
        );
    tPrint('connect to ${widget.wsurl} requested');
    setState(() {
      wsFuture = f;
    });
  }

  FutureOr<WebSocket> _configureWsAfterConnecting(WebSocket ws) {
    ws.pingInterval = Duration(seconds: 10);
    ws.handleError((Object e) {
      tPrint('ws.handleError $e');
    });
    // ignore: avoid_annotating_with_dynamic
    ws.done.then((dynamic d) {
      // ignore: avoid_as
      final ws = d as WebSocket;
      tPrint('ws.done.then with details:\n${_wsDetails(ws)}');
    });

    wsSubscription = ws.listen(
      // ignore: avoid_annotating_with_dynamic
          (dynamic d) => tPrint('ws.listen received = $d'),
      onError: (Object e) => tPrint('ws.listen.onError $e'),
      onDone: () =>
          tPrint('ws.listen.onDone called. ws state is:\n${_wsDetails(ws)}'),
    );
    tPrint('connect successfully established');
    setState(() {
      this.ws = ws;
    });
    return ws;
  }

  void _manualCloseConnection() {
    tPrint('manual disconnect pressed');
    ws
        .close(WebSocketStatus.normalClosure, 'bye')
        .then((dynamic ws
        /*WebSocket*/) {
      tPrint('ws closed successfully');
    })
        .catchError((Object e) {
      // TODO(n): how this can happen?
      // and if happen how app must react on it?
      tPrint('ws closing failed with $e');
    })
        .then<dynamic>((_) => wsSubscription.cancel())
        .then((dynamic paramIsNull) {
      tPrint('wsSubscription closed successfully');
    })
        .catchError((Object e) {
      tPrint('error catched on wsSubscription close $e');
    })
        .then((_) {
      setState(() {
        wsFuture = null;
        wsSubscription = null;
      });
    });

//    with subscription cancel code ws.listen.onDone doesn't called
  }

  void _printState() {
    print('ready state ${ws.readyState}');
    print('close code ${ws.closeCode}');
    print('close reason ${ws.closeReason}');
    print('extensions ${ws.extensions}');
    print('protocol ${ws.protocol}');
  }

  String _wsDetails(WebSocket ws) =>
      'readyState:${ws.readyState} closeCode:${ws.closeCode} closeReason:${ws
          .closeReason}';

  void tPrint(String msg) {
    print(DateTime.now().toString() + '   ' + msg);
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
            Row(
              children: <Widget>[
                RaisedButton(
                  onPressed: wsFuture != null ? null : _initws,
                  child: const Text('conn'),
                ),
                const SizedBox(width: 8),
                RaisedButton(
                  onPressed: ws == null ? null : _printState,
                  child: const Text('state'),
                ),
                const SizedBox(width: 8),
                RaisedButton(
                  onPressed:
                  wsSubscription == null ? null : _manualCloseConnection,
                  child: const Text('disconn'),
                ),
              ],
            ),
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ws == null ? null : _sendMessage,
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
