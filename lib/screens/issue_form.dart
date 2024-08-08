import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../bloc/issue/issue_bloc.dart';
import '../bloc/issue/issue_bloc.dart';

class IssueForm extends StatefulWidget {
  final String typeForm;
  final SupabaseClient supabase;
  final PageController pageController;

  const IssueForm({Key? key, required this.typeForm, required this.supabase, required this.pageController})
      : super(key: key);

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  TextEditingController issueTitleController = TextEditingController();
  TextEditingController issueBodyController = TextEditingController();
  int selectedRadio = 1;
  bool _isLoading = true;
  late Map _issueData;

  @override
  void initState() {
    debugPrint('INITSTATE CALLED');
    issueTitleController.text = '';
    issueBodyController.text = '';
    if (widget.typeForm == 'edit') {
      final issueId = context.read<IssueBloc>().state.selectId;
      //_issueData = _getAsyncIssueById(issueId);
      _getIssueById(issueId);

      //debugPrint('------------- _issueData: ${_issueData['submitter']}');
      // issueTitleController = TextEditingController(text: _issueData['summary']);
      //issueBodyController = TextEditingController(text: _issueData['description']);
      //issueTitleController.text = 'summary';
      //issueBodyController.text = 'description';
      setState(() {});
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    debugPrint('didChangeDependencies CALLED');
    if (widget.typeForm == 'edit') {
      final issueId = context.read<IssueBloc>().state.selectId;
      // _getIssueById(issueId);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    issueTitleController.dispose();
    issueBodyController.dispose();
    debugPrint('DISPOSE CALLED');
    super.dispose();
  }

  Future<Map> _getAsyncIssueById(int id) async {
    try {
      final supabase = widget.supabase;
      final data = await supabase.schema('eaquasaver').from('issue').select().eq('id', id).single();
      return Future.value(data);
    } catch (error) {
      return Future.value({});
    }
  }

  void _getIssueById(int id) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final supabase = widget.supabase;
      final data = await supabase.schema('eaquasaver').from('issue').select().eq('id', id).single();
      if (data.isNotEmpty) {
        if (mounted) {
          setState(() {
            _issueData = data;
            //issueTitleController.text = data['summary'];
            //issueBodyController.text = data['description'];
            issueTitleController = TextEditingController(text: _issueData['summary']);
            issueBodyController = TextEditingController(text: _issueData['description']);
            selectedRadio = _issueData['target'] == 'app' ? 1 : 2;
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addIssue() async {
    final supabase = widget.supabase;
    setState(() {
      _isLoading = true;
    });
    try {
      final List<dynamic> data = await supabase.schema('eaquasaver').from('issue').insert(
        {
          'submitter': supabase.auth.currentUser?.id,
          'summary': issueTitleController.text,
          'description': issueBodyController.text,
          'target': selectedRadio == 1 ? 'app' : 'device'
        },
      ).select();
      if (data.length > 0) {
        debugPrint('Issue añadido correctamente!');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      Future.delayed(const Duration(seconds: 1), () {
        widget.pageController.jumpToPage(3);
        //super.dispose();
      });
    }
  }

  void _updateIssueById(int id, IssueBloc bloc) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = widget.supabase;
      final data = await supabase
          .schema('eaquasaver')
          .from('issue')
          .update({
            'submitter': supabase.auth.currentUser!.id,
            'summary': issueTitleController.text,
            'description': issueBodyController.text,
            'target': selectedRadio == 1 ? 'app' : 'device'
          })
          .eq('id', id)
          .select()
          .single();
      if (data.isNotEmpty) {
        debugPrint('Issue actualizado correctamente!');
        /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Issue updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );*/
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unexpected error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 1), () {
        widget.pageController.jumpToPage(3);
        //super.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<IssueBloc, IssueState>(builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text((widget.typeForm == 'new') ? 'Describe the issue' : 'Edit this issue [id#${state.selectId}]'),
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
      }),
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        onPressed: _isLoading == true ? null : () {
          FocusScope.of(context).unfocus();
          if (widget.typeForm == 'new') {
            _addIssue();
          } else if (widget.typeForm == 'edit') {
            final issueBloc = BlocProvider.of<IssueBloc>(context);
            _updateIssueById(issueBloc.state.selectId, issueBloc);
          }
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
