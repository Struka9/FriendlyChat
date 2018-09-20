import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _username;
  bool _isButtonEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: (String text) {
                setState(() {
                  this._username = text;
                  this._isButtonEnabled = this._username.length > 0;
                });
              },
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter your Username",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            RaisedButton(
              color: _isButtonEnabled ? Colors.blueAccent : Colors.grey[300],
              child: Text(
                "Login",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _isButtonEnabled
                  ? () {
                      // Move to the next screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatScreen(username: _username)));
                    }
                  : null,
            )
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({this.text, this.author});
  final String text;
  final String author;

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: new CircleAvatar(child: new Text(author[0])),
          ),
          new Expanded(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(author, style: Theme.of(context).textTheme.subhead),
                new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: new Text(text))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  ChatScreen({this.username});
  final String username;
  @override
  State createState() {
    return ChatScreenState(username: username);
  }
}

class ChatScreenState extends State {
  ChatScreenState({this.username});
  final String username;
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  void _handleSubmitted(String value) {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    final CollectionReference collectionReference =
        Firestore.instance.collection("messages");
    Firestore.instance.runTransaction((Transaction tx) async {
      collectionReference
          .add({"message": value, "author": username}).then((value) {
        print(value);
      });
    });
  }

  Widget _buildChatMessage(BuildContext context, document) {
    return new ChatMessage(
        text: document["message"], author: document["author"]);
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.all(10.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _controller,
              decoration:
                  InputDecoration.collapsed(hintText: "Enter your message"),
              onSubmitted: _handleSubmitted,
              onChanged: (String text) {
                setState(() {
                  _isComposing = text.length > 0;
                });
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10.0),
            child: IconButton(
              icon: Icon(Icons.send),
              color: _isComposing ? Colors.blueAccent : Colors.grey,
              onPressed: _isComposing
                  ? () => _handleSubmitted(_controller.text)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: Firestore.instance.collection("messages").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Text("Loading...");
                return ListView.builder(
                  reverse: false,
                  itemBuilder: (context, index) => _buildChatMessage(
                      context, snapshot.data.documents[index]),
                  itemCount: snapshot.data.documents.length,
                  padding: const EdgeInsets.all(10.0),
                  itemExtent: 55.0,
                );
              },
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration: new BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          )
        ],
      ),
    );
  }
}
