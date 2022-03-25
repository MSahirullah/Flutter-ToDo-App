import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_app/models/todo.dart';
import 'package:todo_app/services/auth.dart';
import 'package:todo_app/services/database.dart';
import 'package:todo_app/widgets/todo_card.dart';

class Home extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore fireStore;

  const Home({
    Key? key,
    required this.auth,
    required this.fireStore,
  }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _todoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo App'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey("signOut"),
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Auth(auth: widget.auth).signOut();
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text(
            "Add Todo Here:",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Card(
            margin: const EdgeInsets.all(20.0),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey("addField"),
                      controller: _todoController,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey("addButton"),
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_todoController.text != "") {
                        setState(() {
                          Database(firestore: widget.fireStore).addTodo(
                              uid: widget.auth.currentUser!.uid,
                              content: _todoController.text);
                          _todoController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your Todos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.done_all_rounded),
                  onPressed: _completedTodos,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: StreamBuilder(
              stream: Database(firestore: widget.fireStore)
                  .streamTodos(uid: widget.auth.currentUser!.uid),
              builder: (BuildContext context,
                  AsyncSnapshot<List<TodoModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data == null) {
                    return const Center(
                      child: Text("You don't have any unfinished Todos"),
                    );
                  }
                  return ListView.builder(
                    itemCount:
                        snapshot.data != null ? snapshot.data?.length : 0,
                    itemBuilder: (_, index) {
                      return TodoCard(
                        firestore: widget.fireStore,
                        uid: widget.auth.currentUser!.uid,
                        todo: snapshot.data![index],
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text("loading..."),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _completedTodos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Completed Todos'),
            centerTitle: true,
            actions: [
              IconButton(
                key: const ValueKey("signOut"),
                icon: const Icon(Icons.exit_to_app),
                onPressed: () {
                  Auth(auth: widget.auth).signOut();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Expanded(
                child: StreamBuilder(
                  stream: Database(firestore: widget.fireStore)
                      .streamCompletedTodos(uid: widget.auth.currentUser!.uid),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<TodoModel>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.data == null) {
                        return const Center(
                          child: Text("You don't have any unfinished Todos"),
                        );
                      }
                      return ListView.builder(
                        itemCount:
                            snapshot.data != null ? snapshot.data?.length : 0,
                        itemBuilder: (_, index) {
                          return TodoCard(
                            firestore: widget.fireStore,
                            uid: widget.auth.currentUser!.uid,
                            todo: snapshot.data![index],
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text("loading..."),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void takePhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
    );

    setState(() {
      _imageFile = pickedFile;
      if (_imageFile != null) {
        Navigator.pop(context);
      }
    });
  }
}
