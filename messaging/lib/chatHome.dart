import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dart:async';



class ChatHome extends StatefulWidget{
  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  QuerySnapshot info;

  getData() async {
    return await Firestore.instance.collection('users').getDocuments();
  }

  @override
  void initState() {
    super.initState();
    getData().then((val) {
      FirebaseAuth.instance
          .currentUser().then((val) {
        Firestore.instance.collection('users')
            .where('uid', isEqualTo: val.uid)
            .getDocuments()
            .then((docs) {
          Firestore.instance.document(
              '/users/${docs.documents[0].documentID}')
              .collection('friends')
              .getDocuments()
              .then((results) {
            setState(() {
              info = results;
            });
          }).catchError((e) {
            print(e);
          });
        }).catchError((e) {
          print(e);
        });
      }).catchError((e) {
        print(e);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          elevation: 0.0,
          backgroundColor: Colors.white,
          title: new Text('Intee Chat', style: TextStyle(
            color: Colors.black,
          ),),
             leading: new IconButton(icon: Icon(Icons.arrow_back, color: Colors.black,),
                 onPressed: () { Navigator.of(context).pushReplacementNamed('/homepage');
             }),
             actions: <Widget>[
             new IconButton(
              icon: Icon(Icons.person_add, color: Colors.black,),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/addfriendpage');
              }
            )
          ]
        ),
        body: new ListView.builder(
            itemCount: info == null? 0: info.documents.length,
            itemBuilder: (BuildContext context, i) {
              if(info == null){
                return Text('No friends added',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black38
                ),);
              }
              return new ListTile(
                title: new Text(info.documents[i].data["friendName"]),
                leading: new CircleAvatar(
                  backgroundImage: new NetworkImage(info.documents[i]["friendPhoto"]),
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (BuildContext context) =>
                          new SecondPage(info.documents[i])));
                },
              );
            }
        )
    );
  }
}

class SecondPage extends StatefulWidget {
  final data;
  SecondPage(this.data);

createState() => _SecondPageState(this.data);
}

class _SecondPageState extends State<SecondPage> {

  _SecondPageState(this.data);

  final data;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _firestore = Firestore.instance;
  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  QuerySnapshot info;

  getData() async {
    return await Firestore.instance.collection('users').getDocuments();
  }

  Future<void> callback() async {
    if (messageController.text.length > 0) {
      await _firestore.collection('messages').document(data['friendship']).collection('message').add({
        'text': messageController.text,
        'from': (info.documents[0].data['uid']),
        'date': DateTime.now().toIso8601String().toString(),
      });
      messageController.clear();
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }


  @override
  void initState() {
    getData().then((val) {
      FirebaseAuth.instance
          .currentUser().then((val) {
        Firestore.instance.collection('users')
            .where('uid', isEqualTo: val.uid)
            .getDocuments().then((results) {
              if(!mounted) return;
              setState(() {
                info = results;
              });
          });
        });
        initState();
      });
  }

  @override
  Widget build(BuildContext context) {
    if (info != null) {
      return Scaffold(
        appBar: AppBar(
          title: new Text(data['friendName']),
          leading: new CircleAvatar(
            backgroundImage: NetworkImage(data['friendPhoto']),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/chathomepage');
              },
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('messages')
                      .document(data['friendship'])
                      .collection('message')
                      .orderBy('date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(
                        child: CircularProgressIndicator(),
                      );

                    List<DocumentSnapshot> docs = snapshot.data.documents;

                    List<Widget> messages = docs
                        .map((doc) =>
                        Message(
                          from: doc.data['from'],
                          text: doc.data['text'],
                          me: (info.documents[0].data['uid']) ==
                              doc.data['from'],
                        ))
                        .toList();

                    return ListView(
                      controller: scrollController,
                      children: <Widget>[
                        ...messages,
                      ],
                    );
                  },
                ),
              ),

              Container(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onSubmitted: (value) => callback(),
                        decoration: InputDecoration(
                          hintText: "Enter a Message...",
                          border: const OutlineInputBorder(),
                        ),
                        controller: messageController,
                      ),
                    ),
                    SendButton(
                      text: "Send",
                      callback: callback,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else return Center(child: CircularProgressIndicator(),);
  }
}

class SendButton extends StatelessWidget {
  final String text;
  final VoidCallback callback;

  const SendButton({Key key, this.text, this.callback}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FlatButton(
      color: Colors.orange,
      onPressed: callback,
      child: Text(text),
    );
  }
}

class Message extends StatelessWidget {
  final String from;
  final String text;

  final bool me;

  const Message({Key key, this.from, this.text, this.me}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment:
        me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 5,),
          Material(
            color: me ? Colors.teal : Colors.red,
            borderRadius: BorderRadius.circular(10.0),
            elevation: 6.0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              child: Text(
                text,
              ),
            ),
          )
        ],
      ),
    );
  }
}
