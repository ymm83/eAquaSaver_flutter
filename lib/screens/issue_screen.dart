import 'package:flutter/material.dart';
import '../main.dart'; // Asegúrate de que este import sea correcto según tu estructura de proyecto

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  List _issueData = [];
  bool _isLoading = true;
  int selectedRadio = 0;

  void _getIssues() async {
    try {
      final data = await supabaseEAS.from('issue').select();
      setState(() {
        _issueData = data;
        _isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveIssue() async {
    try {
      final data = await supabaseEAS.from('issue').select();
      setState(() {
        _issueData = data;
        _isLoading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _issueData.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_issueData[index]['id'].toString()),
                  subtitle: Text(_issueData[index]['summary']),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAlertDialog(context);
        },
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          size: 40,
        ),
      ),
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'New Issue Form',
            style: TextStyle(fontSize: 14),
          ),          
          content: StatefulBuilder(            
            builder: (BuildContext context, StateSetter setState) {
              TextEditingController issueTitleController = TextEditingController();
              TextEditingController issueBodyController = TextEditingController();
              return SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Radio<int>(
                        value: 1,
                        groupValue: selectedRadio,
                        onChanged: (int? val) {
                          setState(() {
                            selectedRadio = val!;
                          });
                        },
                      ),
                      const Text('App'),
                      const SizedBox(width: 20), // Espaciado entre los radios
                      Radio<int>(
                        value: 2,
                        groupValue: selectedRadio,
                        onChanged: (int? val) {
                          setState(() {
                            selectedRadio = val!;
                          });
                        },
                      ),
                      const Text('Device'),
                    ],
                  ),
                  TextFormField(
                    maxLines: 2,
                    controller: issueTitleController,
                    decoration: const InputDecoration(
                        //hintText: 'The email address?',
                        labelText: 'summary',
                        border: OutlineInputBorder(),
                        counterText: ""),
                    maxLength: 20,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    maxLines: 6,
                    controller: issueBodyController,
                    decoration: const InputDecoration(
                      //hintText: 'The email address?',
                      labelText: 'description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ));
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
