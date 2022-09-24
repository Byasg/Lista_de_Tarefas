// ignore_for_file: unused_element

import 'dart:convert' show json;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final todoController = TextEditingController();

  List todoList = [];
  late Map<String, dynamic> lastRemoved;
  late int lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      todoList = json.decode(data);
    });
  }

  void addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = todoController.text;
      todoController.text = "";
      newTodo["ok"] = false;
      todoList.add(newTodo);
      _saveData();
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      todoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
    });

    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Tarefas"),
        backgroundColor: const Color.fromARGB(255, 41, 86, 165),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1, 17, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: todoController,
                    decoration: const InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 41, 86, 165),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: addTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 41, 86, 165),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ADD"),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: todoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(todoList[index]["title"]),
        value: todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
            todoList[index]["ok"] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (c) {
          setState(() {
            todoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(todoList[index]);
          lastRemovedPos = index;
          todoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa $lastRemoved removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (() {
                setState(() {
                  todoList.insert(lastRemovedPos, lastRemoved);
                  _saveData();
                });
              }),
            ),
            duration: const Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null!;
    }
  }
}
