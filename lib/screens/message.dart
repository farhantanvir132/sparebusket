import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sparebusket/constants/Firebasae_constant.dart';
import 'package:sparebusket/constants/mediaquery.dart';
import 'package:sparebusket/models/message_chat.dart';
import 'package:sparebusket/widgets/chatBubble.dart';

class MessageScreen extends StatefulWidget {
  final String userId;
  final String username;
  MessageScreen({Key? key, required this.userId, required this.username})
      : super(key: key);

  @override
  State<MessageScreen> createState() => MessageScreenState();
}

class MessageScreenState extends State<MessageScreen> {
  String groupChatId = "";
  String currentUserId = "";
  String peerId = "";
  String nameOfFrom = "";
  String nameOfTo = "";

  generateGroupId() {
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    peerId = widget.userId;

    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath,
      Map<String, dynamic> dataNeedUpdate) {
    return FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(docPath)
        .update(dataNeedUpdate);
  }

  sendChat({required String message}) async {
    DocumentSnapshot currentUserIdDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    nameOfFrom = currentUserIdDoc.get('firstname');
    DocumentSnapshot peerIdDoc =
        await FirebaseFirestore.instance.collection('users').doc(peerId).get();
    nameOfTo = peerIdDoc.get('firstname');

    MessageChat chat = MessageChat(
      content: message,
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: Timestamp.now().toString(),
    );

    await FirebaseFirestore.instance
        .collection("groupMessages")
        .doc(groupChatId)
        .collection("messages")
        .add(chat.toJson());

    _messageController.text = "";
    QuerySnapshot existingMessages = await FirebaseFirestore.instance
        .collection('displaymessages')
        .where('idfrom', isEqualTo: currentUserId)
        .where('idTo', isEqualTo: peerId)
        .get();

    if (existingMessages.size >= 1) {
      return;
    } else {
      await FirebaseFirestore.instance.collection('displaymessages').add({
        'from': nameOfFrom,
        'to': nameOfTo,
        'idfrom': currentUserId,
        'idTo': peerId
      });
    }
  }

  @override
  void initState() {
    generateGroupId();
    _scrollDown();
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _controller = ScrollController();

  void _scrollDown() {
    if (_controller.hasClients) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    }
  }

  Future<bool> onBackPress() {
    updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: null},
    );
    Navigator.pop(context);

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: false,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                onBackPress();
              }),
          title: Text(widget.username),
          centerTitle: true,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            height: 100,
            width: media(context).width,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: media(context).width / 1.2,
                    child: TextField(
                      decoration:
                          const InputDecoration(label: Text("Enter message")),
                      controller: _messageController,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      sendChat(message: _messageController.text);
                      _messageController.text = "";
                      _scrollDown();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    icon: const Icon(Icons.send),
                  )
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("groupMessages")
              .doc(groupChatId)
              .collection("messages")
              .orderBy(FirestoreConstants.timestamp, descending: true)
              .snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView.builder(
              reverse: true,
              shrinkWrap: true,
              controller: _controller,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                MessageChat chat =
                    MessageChat.fromDocument(snapshot.data!.docs[index]);
                final String message = chat.content;
                return ChatBubble(
                    text: chat.content,
                    isCurrentUser: chat.idFrom == currentUserId ? true : false);
              },
            );
          },
        ),
        backgroundColor: Color.fromARGB(255, 233, 230, 230),
      ),
    );
  }
}
