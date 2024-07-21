import 'package:eaquasaver_flutter_app/bloc/bloc/bloc_bloc.dart';
import 'package:eaquasaver_flutter_app/screens/issue_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_screen.dart';
import 'issue_screen.dart';

class UserTabs extends StatefulWidget {
  const UserTabs({super.key});

  @override
  State<UserTabs> createState() => _UserTabsState();
}

class _UserTabsState extends State<UserTabs> {
  final PageController _userTabController = PageController(keepPage: false);
  int _pageChanged = 0;
  String _pageTitle = 'Profile';
  late SupabaseClient supabase;

  List<Widget> _actionsDefault(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.manage_accounts_outlined),
        onPressed: () => _userTabController.jumpToPage(0),
      ),
      IconButton(
        icon: const Icon(Icons.star_half_outlined),
        onPressed: () => _userTabController.jumpToPage(1),
      ),
      IconButton(
        icon: const Icon(Icons.comment_outlined),
        onPressed: () => _userTabController.jumpToPage(2),
      ),
      IconButton(
        icon: const Icon(Icons.bug_report_outlined),
        onPressed: () => _userTabController.jumpToPage(3),
      )
    ];
  }

  List<Widget> _actionsIssue(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.checklist_outlined),
        onPressed: () => _userTabController.jumpToPage(0),
      ),
      IconButton(
        icon: const Icon(Icons.star_half_outlined),
        onPressed: () => _userTabController.jumpToPage(1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supa = BlocProvider.of<IssueBloc>(context).supabase;
    return Scaffold(
      appBar: AppBar(
        actions: _actionsDefault(context),
        backgroundColor: Colors.green[100],
        elevation: 0,
        title: Text(_pageTitle),
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        pageSnapping: false,
        controller: _userTabController,
        onPageChanged: (index) {
          setState(() {
            _pageChanged = index;
            _pageTitle = ['Profile', 'Rating', 'Comments', 'Issues', 'New Issue'][index];
          });
        },
        children: [
          const AccountScreen(),
          const Center(child: Text('Rating')),
          const Center(child: Text('Comments')),
          IssueScreen(pageController: _userTabController),
          IssueForm(typeForm: 'new', supabase: supa, pageController: _userTabController),
          IssueForm(typeForm: 'edit', supabase: supa, pageController: _userTabController),
        ],
      ),
    );
  }
}
