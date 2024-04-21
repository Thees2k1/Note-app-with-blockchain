import 'package:flutter/material.dart';
import 'package:note_app_with_blockchain/services/note_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    var notesService = context.watch<NoteService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: notesService.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await notesService.fetchNotes();
              },
              child: ListView.builder(
                itemCount: notesService.notes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(notesService.notes[index].title),
                    subtitle: Text(notesService.notes[index].description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () {},
                    ),
                  );
                },
              ),
            ),

      // Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       const Text('no note yet man :('),
      //     ],
      //   ),
      // ),
      floatingActionButton:
          FloatingActionButton(onPressed: () => openDialog(notesService)),
    );
  }

  Future openDialog(NoteService noteService) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('New note'),
          content: Column(
            children: [
              const Text('title'),
              TextField(
                autofocus: true,
                controller: _titleCtrl,
                decoration:
                    const InputDecoration(hintText: "Enter note's title"),
              ),
              const Text('description'),
              TextField(
                controller: _descriptionCtrl,
                decoration:
                    const InputDecoration(hintText: "Enter your content"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                noteService.addNote(_titleCtrl.text, _descriptionCtrl.text);
                Navigator.of(context).pop();
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      );
  void submit() {
    debugPrint(
        'Title: ${_titleCtrl.text}// Description: ${_descriptionCtrl.text}');
    //notesService.addNote(_titleCtrl.text, _descriptionCtrl.text);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }
}
