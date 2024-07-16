import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/issue/issue_bloc.dart';

class IssueForm extends StatefulWidget {
  final String typeForm;
  final int? issueId;

  const IssueForm({super.key, required this.typeForm, this.issueId});

  @override
  State<IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  final TextEditingController issueTitleController = TextEditingController();
  final TextEditingController issueBodyController = TextEditingController();
  int selectedRadio = 1;

  @override
  void dispose() {
    issueTitleController.dispose();
    issueBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<IssueBloc, IssueState>(
        builder: (context, state) {
          return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text((widget.typeForm == 'new') ? 'Describe the issue' : 'Edit this issue ${state.issue.id}'),
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
      }
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        onPressed: () {
          final issueBloc = BlocProvider.of<IssueBloc>(context);
          if (widget.typeForm == 'new') {
            //issueBloc.add(AddIssue(issueTitleController.text, issueBodyController.text, selectedRadio ));
          } else if (widget.typeForm == 'edit') {
            //issueBloc.add(EditIssue(widget.issueId!,issueTitleController.text,issueBodyController.text, selectedRadio ));
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
