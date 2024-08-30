import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/issue/issue_bloc.dart';

class IssueColor {
  Color error = Colors.red;
}

class IssueScreen extends StatefulWidget {
  final PageController pageController;
  final SupabaseClient supabase;
  const IssueScreen({super.key, required this.pageController, required this.supabase});

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
    final userid = widget.supabase.auth.currentUser!.id;
    try {
      final data = await widget.supabase.schema('eaquasaver').from('issue').select().eq('submitter', userid);
      setState(() {
        _issueData = data;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unexpected error occurred'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteIssue(int id) async {
    debugPrint('Id eliminado: $id');
    try {
      final response =
          await widget.supabase.schema('eaquasaver').from('issue').delete().eq('id', id).eq('status', 'new').select();
      if (response.length == 1) {
        setState(() {
          _issueData.removeWhere((issue) => issue['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Issue eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error: no se pudo eliminar'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      // Manejo de errores
    }
  }

  /*void _saveIssue() async {
    if (issueTitleController.text.isEmpty || issueBodyController.text.isEmpty) {
      return;
    }
    try {
      final List<dynamic> data = await widget.supabase.schema('eaquasaver').from('issue').insert(
        {
          'submitter': widget.supabase.auth.currentUser?.id,
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
            title: const Text('¡Eliminación!'),
            content: const Text("¿Desea eliminar este Issue?"),
            actions: [
              TextButton(
                  child: const Text("Aceptar", style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _deleteIssue(id);
                    Navigator.of(context).pop();
                  }),
              TextButton(
                  child: const Text("Cancelar", style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IssueBloc, IssueState>(builder: (context, state) {
      return Scaffold(
        body: BlocBuilder<ConnectivityBloc, ConnectivityState>(
          builder: (context, connectivityState) {
            if (connectivityState is ConnectivityOffline) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No internet connection'),
                    SizedBox(height: 8),
                    Icon(Icons.cloud_off_outlined, size: 40),
                  ],
                ),
              );
            }

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return _newIssue
                ? SingleChildScrollView(
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
                  )
                : ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    shrinkWrap: true,
                    itemCount: _issueData.length,
                    itemBuilder: (BuildContext context, int index) {
                      final formattedDate = Moment(DateTime.parse(_issueData[index]['created_at']))
                          .startOf(DurationUnit.second)
                          .fromNow();
                      return Card(
                        color: const Color.fromARGB(255, 191, 241, 239),
                        child: ListTile(
                          key: GlobalKey(),
                          title: Text(
                            '${_issueData[index]['id']}-${_issueData[index]['summary']}',
                            style: const TextStyle(fontWeight: FontWeight.w400, color: Color.fromARGB(255, 1, 24, 43)),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(_issueData[index]['description']),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: 'target: ',
                                      style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 5, 69, 85)),
                                      children: [
                                        TextSpan(
                                          text: '${_issueData[index]['target']} | ',
                                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(text: 'status: '),
                                        TextSpan(
                                          text: '${_issueData[index]['status']} | ',
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
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          context.read<IssueBloc>().add(EditIssue(_issueData[index]['id']));
                                          widget.pageController.jumpToPage(5);
                                        },
                                        splashColor: const Color.fromARGB(255, 122, 191, 245),
                                        borderRadius: BorderRadius.circular(50),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Color.fromARGB(255, 12, 73, 120),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      InkWell(
                                        onTap: () {
                                          _showAlertDialog(context, _issueData[index]['id']);
                                        },
                                        splashColor: const Color.fromARGB(255, 122, 191, 245),
                                        borderRadius: BorderRadius.circular(50),
                                        child: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Color.fromARGB(255, 12, 73, 120),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
          },
        ),
        floatingActionButton: BlocBuilder<ConnectivityBloc, ConnectivityState>(
          builder: (context, connectivityState) {
            return Visibility(
              visible: connectivityState is! ConnectivityOffline,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _newIssue = true;
                  });
                  widget.pageController.jumpToPage(4);
                },
                backgroundColor: Colors.blue,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  size: 40,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
