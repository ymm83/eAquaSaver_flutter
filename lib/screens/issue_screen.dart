import 'package:flutter/material.dart';
import '../main.dart';

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  List _issueData = [];
  bool _isLoading = true;

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
        onPressed: _getIssues,
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          size: 40,
        ),
      ),
    );
  }
}
