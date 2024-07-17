import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment_dart/moment_dart.dart';
import '../bloc/issue/issue_bloc.dart';
import '../model/issue.dart';

class IssueScreen extends StatefulWidget {
  final PageController pageController;

  const IssueScreen({super.key, required this.pageController});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  TextEditingController issueTitleController = TextEditingController();
  TextEditingController issueBodyController = TextEditingController();
  int selectedRadio = 1;
  bool _newIssue = false;
  late int issueId;

  @override
  void initState() {
    super.initState();
    context.read<IssueBloc>().add(LoadIssues());
    issueId = context.read<IssueBloc>().state.selectId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<IssueBloc, IssueState>(
        builder: (context, state) {
          if (state is IssueLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is IssueLoaded) {
            return (_newIssue == false)
                ? ListView.builder(
                    itemCount: state.issues.length,
                    itemBuilder: (BuildContext context, int index) {
                      final formattedDate = Moment(DateTime.parse(state.issues[index]['created_at']))
                          .startOf(DurationUnit.second)
                          .fromNow();
                      return Card(
                        color: const Color.fromARGB(255, 191, 241, 239),
                        child: ListTile(
                          title: Text(
                            '${state.issues[index]['summary']}',
                            style: const TextStyle(fontWeight: FontWeight.w400, color: Color.fromARGB(255, 1, 24, 43)),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(state.issues[index]['description']),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: '${state.issues[index]['id']} target: ',
                                      style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 5, 69, 85)),
                                      children: [
                                        TextSpan(
                                          text: '${state.issues[index]['target']} | ',
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(text: 'status: '),
                                        TextSpan(
                                          text: '${state.issues[index]['status']} | ',
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                        TextSpan(
                                          text: formattedDate,
                                          style: const TextStyle(color: Color.fromARGB(255, 2, 116, 17)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          widget.pageController.jumpToPage(5);
                                          context.read<IssueBloc>().add(SelectIssueID(state.issues[index]['id']));
                                          //context.read<IssueBloc>().add(GetIssue(state.issues[index]['id']));
                                          //context.read<IssueBloc>().add(SelectIssueID(state.issues[index]['id']));
                                        },
                                        splashColor: Color.fromARGB(255, 122, 191, 245),
                                        borderRadius: BorderRadius.circular(50),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Color.fromARGB(255, 12, 73, 119),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          _showAlertDialog(context, state.issues[index]['id']);
                                        },
                                        splashColor: Color.fromARGB(255, 122, 191, 245),
                                        borderRadius: BorderRadius.circular(50),
                                        child: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Color.fromARGB(255, 12, 73, 119),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
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
                            const SizedBox(width: 20),
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
                            labelText: 'description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(15.0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
          } else if (state is IssueError) {
            return Center(
              child: Text(state.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            );
          }
          return Container();
        },
      ),
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
                context.read<IssueBloc>().add(
                      AddIssue(issueTitleController.text, issueBodyController.text, selectedRadio),
                    );
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

  void _showAlertDialog(BuildContext context, int id) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Eliminación!'),
          content: const Text("¿Desea eliminar este Issue?"),
          actions: [
            TextButton(
              child: const Text("Aceptar", style: TextStyle(color: Colors.red)),
              onPressed: () {
                context.read<IssueBloc>().add(DeleteIssue(id));
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Cancelar", style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
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
    final PageController pageController;

  const IssueScreen({super.key, required this.pageController});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  List _issueData = [];
   List _issueEditData = [];
  bool _isLoading = true;
  int selectedRadio = 1;
  bool _newIssue = false;
  bool _editIssue = false;
  final userid = supabase.auth.currentUser!.id;
  TextEditingController issueTitleController = TextEditingController();
  TextEditingController issueBodyController = TextEditingController();

  void _getIssues({int id=0}) async {
    try {
      var data;
      if (id==0) {
        data = await supabaseEAS.from('issue').select().eq('submitter', userid);
       } else if (id>0) {
        data = await supabaseEAS.from('issue').select().eq('id', id);
        int idTarget = (data[0]['target']=='app') ? 1 : (data[0]['target']=='device') ? 2 : 0;
        setState(() {selectedRadio = idTarget;});
      }
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

  /*void _saveIssue(int id) async {
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
        _issueData.add(data[0]);
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
  }*/

  void _deleteIssue(int id) async {
    debugPrint('Id eliminado: $id');
    try {
      final response = await supabaseEAS.from('issue').delete().eq('id', id).eq('status', 'new').select();
      if (response.length == 1) {
        setState(() {
          _issueData.removeWhere((issue) => issue['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Issue eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: no se pudo eliminar'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );*/
    }
  }

  void _saveIssue() async {
    if (issueTitleController.text.isEmpty || issueBodyController.text.isEmpty) {
      return;
    }
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
        _issueData.add(data[0]);
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

  void _showAlertDialog(BuildContext context, id) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('¡Eliminación!'),
            content: Text("¿Desea eliminar este Issue?"),
            actions: [
              TextButton(
                  child: Text("Aceptar", style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _deleteIssue(id);
                    Navigator.of(context).pop();
                  }),
              TextButton(
                  child: Text("Cancelar", style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }

  Widget _buildAlertDialog() {
    return AlertDialog(
      title: const Text('Issue delete', style: TextStyle(fontSize: 12)),
      content: Text("¿Desea eliminar este issue?"),
      actions: [
        TextButton(
            child: Text("Aceptar", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        TextButton(
            child: Text("Cancelar", style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ],
    );
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
                    final formattedDate =
                        Moment(DateTime.parse(_issueData[index]['created_at'])).startOf(DurationUnit.second).fromNow();
                    //debugPrint('$formattedDate');
                    return Card(
                      color: Color.fromARGB(255, 191, 241, 239),
                      child: ListTile(
                        key: GlobalKey(),
                        title: Text(
                          '${_issueData[index]['summary']}',
                          style: const TextStyle(fontWeight: FontWeight.w400, color: Color.fromARGB(255, 1, 24, 43)),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(_issueData[index]['description']),
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              RichText(
                                text: TextSpan(
                                    text: 'target: ',
                                    style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 5, 69, 85)),
                                    children: [
                                      TextSpan(
                                          text: '${_issueData[index]['target']} | ',
                                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      const TextSpan(text: 'status: '),
                                      TextSpan(
                                          text: '${_issueData[index]['status']} | ',
                                          style: TextStyle(color: Colors.red)),
                                      TextSpan(
                                          text: formattedDate,
                                          style: TextStyle(color: Color.fromARGB(255, 2, 116, 17))),
                                    ]),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      //_newIssue
                                      widget.pageController.jumpToPage(5);
                                      
                                      _getIssues(id:_issueData[index]['id']);
                                    },
                                    splashColor: Color.fromARGB(255, 122, 191, 245),
                                    borderRadius: BorderRadius.circular(50),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Color.fromARGB(255, 12, 73, 119),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      _showAlertDialog(context, _issueData[index]['id']);
                                    },
                                    splashColor: Color.fromARGB(255, 122, 191, 245),
                                    borderRadius: BorderRadius.circular(50),
                                    child: const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Color.fromARGB(255, 12, 73, 119),
                                    ),
                                  ),
                                ],
                              ),
                            ])
                          ],
                        ),
                        /*leading: _issueData[index]['target'] == 'app'
                            ? const Icon(Icons.app_shortcut)
                            : const Icon(Icons.bathroom_outlined),*/
                      ),
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
*/