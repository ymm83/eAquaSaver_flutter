import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../main.dart'; // Asegúrate de que este import sea correcto según tu estructura de proyecto

class IssueColor {
  Color error = Colors.red;
}
/*switch (issue_status) {
        case 'new':
            styleBadge = 'error'
            break;
        case 'acepted':
            styleBadge = 'primary'
            break;
        case 'in progress':
            styleBadge = 'secondary'
            break;
        case 'fixed':
            styleBadge = 'success'
            break;
        case 'rejected':
            styleBadge = 'warning'
            break;
    }*/

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  List _issueData = [];
  bool _isLoading = true;
  int selectedRadio = 1;
  bool _newIssue = false;
  TextEditingController issueTitleController = TextEditingController();
  TextEditingController issueBodyController = TextEditingController();
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
      final List<dynamic> data = await supabaseEAS.from('issue').insert(
        {
          'submitter': supabase.auth.currentUser?.id,
          'summary': issueTitleController.text,
          'description': issueBodyController.text,
          'target': selectedRadio == 1
              ? 'app'
              : selectedRadio == 2
                  ? 'device'
                  : null
        },
      ).select();
      setState(() {
        _issueData.add( data[0] );
        _isLoading = false;
      });
      debugPrint('----------$data---------');
    } catch (error) {
      debugPrint('----------$error---------');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
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
          : (_newIssue == false)
              ? ListView.builder(
                  itemCount: _issueData.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      key:GlobalKey(),
                      title: Text(_issueData[index]['id'].toString()),
                      subtitle: Text(_issueData[index]['summary']),
                      
                    );
                  },
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Describe the issue'),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15.0)),
                          ),
                          counterText: "",
                        ),
                        maxLength: 20,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        maxLines: 8,
                        controller: issueBodyController,
                        decoration: const InputDecoration(
                          //hintText: 'The email address?',
                          labelText: 'description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15.0)),
                          ),
                        ),
                      ),
                    ],
                  )),
      floatingActionButton: (_newIssue == false)
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _newIssue = true;
                });
              },
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add,
                size: 40,
              ),
            )
          : FloatingActionButton(
              onPressed: () {
                _saveIssue();
                debugPrint(
                    'user_id ${supabase.auth.currentUser?.id.toString()} summary: ${issueTitleController.text} description: ${issueBodyController.text} target: ${(selectedRadio == 1) ? 'app' : (selectedRadio == 2) ? 'device' : null}');
                setState(() {
                  _newIssue = false;
                });
              },
              backgroundColor: Colors.green,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.check_outlined,
                size: 40,
              ),
            ),
    );
  }
}
