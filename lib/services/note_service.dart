import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note_app_with_blockchain/models/note.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class NoteService extends ChangeNotifier {
  List<Note> notes = [];
  final String _rpcUrl =
      Platform.isAndroid ? 'http://10.0.2.2' : 'http://172.0.0.1:7545';
  final String _wsUrl =
      Platform.isAndroid ? 'ws://10.0.2.2' : 'ws://172.0.0.1:7545';
  final String _privateKey =
      'f72714ddc79cdfa778dc34d485040c24e881aded31ad8b8ad1126dc0158f1375';
  bool isLoading = true;
  late Web3Client _web3Client;

  NoteService() {
    init();
  }
  Future<void> init() async {
    _web3Client = Web3Client(_rpcUrl, http.Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });
    await getABI();
    await getCredentials();
    await getDeployedContract();
  }

  late ContractAbi _abiCode;
  late EthereumAddress _contractAddress;
  Future<void> getABI() async {
    String abiFile =
        await rootBundle.loadString('build/contracts/NotesContract.json');
    var jsonABI = jsonDecode(abiFile);
    _abiCode =
        ContractAbi.fromJson(jsonEncode(jsonABI['abi']), 'NotesContract');
    _contractAddress =
        EthereumAddress.fromHex(jsonABI['networks']['5777']['address']);
  }

  late EthPrivateKey _creds;
  Future<void> getCredentials() async {
    _creds = EthPrivateKey.fromHex(_privateKey);
  }

  late DeployedContract _deployedContract;
  late ContractFunction _createNote;
  late ContractFunction _deleteNote;
  late ContractFunction _notes;
  late ContractFunction _noteCount;

  Future<void> getDeployedContract() async {
    _deployedContract = DeployedContract(_abiCode, _contractAddress);
    _createNote = _deployedContract.function('createNote');
    _deleteNote = _deployedContract.function('deleteNote');
    _notes = _deployedContract.function('notes');
    _noteCount = _deployedContract.function('noteCount');

    await fetchNotes();
  }

  Future<void> fetchNotes() async {
    List totalNote = await _web3Client
        .call(contract: _deployedContract, function: _noteCount, params: []);
    int notesLen = (totalNote[0] as BigInt).toInt();
    notes.clear();
    for (var i = 0; i < notesLen; i++) {
      var temp = await _web3Client.call(
          contract: _deployedContract,
          function: _notes,
          params: [BigInt.from(i)]);
      if (temp[i] != '') {
        notes.add(Note(
            id: (temp[0] as BigInt).toInt(),
            title: temp[1],
            description: temp[2]));
      }
      debugPrint(notes.toString());
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String title, String description) async {
    await _web3Client.sendTransaction(
      _creds,
      Transaction.callContract(
        contract: _deployedContract,
        function: _createNote,
        parameters: [title, description],
      ),
    );
    isLoading = true;
    notifyListeners();
    fetchNotes();
  }
}
