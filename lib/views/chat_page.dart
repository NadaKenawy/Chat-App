// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, use_build_context_synchronously

import 'package:chat_app/constants.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/widgets/chat_buble.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  static String id = "ChatPage";

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  CollectionReference messages =
      FirebaseFirestore.instance.collection(kMessagesCollections);
  TextEditingController controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String email = ModalRoute.of(context)!.settings.arguments as String;
    return StreamBuilder<QuerySnapshot>(
      stream: messages.orderBy(kCreatedAt, descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Message> messagesList = [];
          for (int i = 0; i < snapshot.data!.docs.length; i++) {
            messagesList.add(Message.fromJson(snapshot.data!.docs[i]));
          }
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    kLogo,
                    height: 50,
                  ),
                  const Text(
                    "Chat",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              foregroundColor: Colors.white,
              backgroundColor: kPrimaryColor,
              automaticallyImplyLeading: false,
            ),
            body: Stack(
              children: [
                Dismissible(
                  key: const Key('dismiss'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop();
                  },
                  background: SlideTransition(
                    position: _offsetAnimation,
                    child: Container(
                      color: Colors.redAccent,
                      padding: const EdgeInsets.only(left: 16.0),
                      alignment: Alignment.centerLeft,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                            reverse: true,
                            controller: _controller,
                            itemCount: messagesList.length,
                            itemBuilder: (context, index) {
                              return messagesList[index].id == email
                                  ? ChatBuble(
                                      message: messagesList[index],
                                    )
                                  : ChatBubleForAnother(
                                      message: messagesList[index]);
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                            controller: controller,
                            onSubmitted: (data) {
                              sendMessage(email);
                            },
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    sendMessage(email);
                                  },
                                  icon: const Icon(
                                    Icons.send,
                                    color: kPrimaryColor,
                                  )),
                              hintText: "Send Message",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: kPrimaryColor,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            )),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  void sendMessage(String email) {
    if (controller.text.trim().isNotEmpty) {
      messages.add({
        kMessage: controller.text.trim(),
        kCreatedAt: DateTime.now(),
        'id': email
      });

      controller.clear();
      _controller.animateTo(0,
          duration: const Duration(seconds: 1), curve: Curves.easeIn);
    }
  }
}
