import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _todoList = [];
  final _txtController = TextEditingController();
  Map<String, dynamic> _lastRemove = Map();
  int _lastRemovedPos;

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo['title'] = _txtController.text;
      newTodo['value'] = false;

      _todoList.add(newTodo);
      _txtController.clear();

      _saveData();
    });
  }

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'List de Tarefas',
          ),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _txtController,
                      decoration: InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed: _addToDo,
                  )
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _todoList.length,
                    itemBuilder: buidItem),
              ),
            )
          ],
        ));
  }

  Widget buidItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        _lastRemove = Map.from(_todoList[index]);
        _lastRemovedPos = index;
        _todoList.removeAt(index);

        setState(() {
          _saveData();
        });

        final snack = SnackBar(
          content: Text('Tarefa ${_lastRemove["title"]} removida!'),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: () {
              _todoList.insert(_lastRemovedPos, _lastRemove);

              setState(() {
                _saveData();
              });
            },
          ),
          duration: Duration(seconds: 2),
        );
        
        Scaffold.of(context).removeCurrentSnackBar();  
        Scaffold.of(context).showSnackBar(snack);
      },
      child: CheckboxListTile(
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['value'],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]['value'] ? Icons.check : Icons.error),
        ),
        onChanged: (check) {
          setState(() {
            _todoList[index]['value'] = check;

            _saveData();
          });
        },
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    _todoList.sort((a, b) {
      if (a['value'] && !b['value']) return 1;
      else if (!a['value'] && b['value']) return -1;
      else return 0;
    });

    setState(() {
      _saveData();
    });

    return null;
  }
}
