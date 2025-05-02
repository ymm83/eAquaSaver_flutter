import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../bloc/issue/issue_bloc.dart';
import '../bloc/issue/issue_bloc.dart';
import '../provider/supabase_provider.dart';
import '../utils/snackbar_helper.dart';

class IssueForm extends StatefulWidget {
  final String typeForm;
  final PageController pageController;

  const IssueForm({super.key, required this.typeForm, required this.pageController});

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  TextEditingController issueTitleController = TextEditingController();
  TextEditingController issueBodyController = TextEditingController();
  int selectedRadio = 1;
  late bool isLoading;
  late Map _issueData;
  late SupabaseClient supabase;
  late SupabaseQuerySchema supabaseEAS;

  @override
  void initState() {
    issueTitleController.text = '';
    issueBodyController.text = '';
    supabase = SupabaseProvider.getClient(context);
    supabaseEAS = SupabaseProvider.getEASClient(context);
    if (widget.typeForm == 'edit') {
      final issueId = context.read<IssueBloc>().state.selectId;
      //_issueData = _getAsyncIssueById(issueId);
      _getIssueById(issueId);

      //debugPrint('------------- _issueData: ${_issueData['user_id']}');
      // issueTitleController = TextEditingController(text: _issueData['summary']);
      //issueBodyController = TextEditingController(text: _issueData['description']);
      //issueTitleController.text = 'summary';
      //issueBodyController.text = 'description';
      setState(() {});
    }
    super.initState();
  }

  @override
  void dispose() {
    issueTitleController.dispose();
    issueBodyController.dispose();
    //debugPrint('DISPOSE CALLED');
    super.dispose();
  }

  /*Future<Map> _getAsyncIssueById(int id) async {
    try {
      final supabase = widget.supabase;
      final data = await supabase.schema('eaquasaver').from('issue').select().eq('id', id).single();
      return Future.value(data);
    } catch (error) {
      return Future.value({});
    }
  }*/

  void _getIssueById(int id) async {
    try {
      setState(() {
        isLoading = true;
      });
      final data = await supabaseEAS.from('issue').select().eq('id', id).single();
      if (data.isNotEmpty) {
        if (mounted) {
          setState(() {
            _issueData = data;
            //issueTitleController.text = data['summary'];
            //issueBodyController.text = data['description'];
            issueTitleController = TextEditingController(text: _issueData['summary']);
            issueBodyController = TextEditingController(text: _issueData['description']);
            selectedRadio = _issueData['target'] == 'app' ? 1 : 2;
            isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('errors.unexpected'.tr(), theme: 'error');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addIssue() async {
    setState(() {
      isLoading = true;
    });
    try {
      final List<dynamic> data = await supabaseEAS.from('issue').insert(
        {
          'user_id': supabase.auth.currentUser?.id,
          'summary': issueTitleController.text,
          'description': issueBodyController.text,
          'target': selectedRadio == 1 ? 'app' : 'device'
        },
      ).select();
      if (data.isNotEmpty) {
        // debugPrint('Issue añadido correctamente!');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('${'errors.error'.tr()}: $error', theme: 'error');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
      Future.delayed(const Duration(seconds: 1), () {
        widget.pageController.jumpToPage(3);
        //super.dispose();
      });
    }
  }

  void _updateIssueById(int id, IssueBloc bloc) async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await supabaseEAS
          .from('issue')
          .update({
            'user_id': supabase.auth.currentUser!.id,
            'summary': issueTitleController.text,
            'description': issueBodyController.text,
            'target': selectedRadio == 1 ? 'app' : 'device'
          })
          .eq('id', id)
          .select()
          .single();
      if (data.isNotEmpty) {
        //debugPrint('Issue actualizado correctamente!');
        showSnackBar('success.issue_updated'.tr(), theme: 'success');
      }
    } catch (error) {
      if (mounted) {
        showSnackBar('errors.unexpected', theme: 'error');
      }
    } finally {
      setState(() {
        isLoading = false;
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
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: BlocBuilder<IssueBloc, IssueState>(builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text((widget.typeForm == 'new') ? 'issue.describe'.tr() : '${'issue.edit'.tr()} [id#${state.selectId}]'),
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
                  Text('issue.app'.tr()),
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
                  Text('issue.device'.tr()),
                ],
              ),
              TextFormField(
                maxLines: 2,
                controller: issueTitleController,
                decoration:  InputDecoration(
                 labelText: 'issue.summary'.tr(),
                  border: const OutlineInputBorder(
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
                decoration:  InputDecoration(
                   labelText: 'issue.description'.tr(),
                  border: const OutlineInputBorder(
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
        onPressed: () {
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
