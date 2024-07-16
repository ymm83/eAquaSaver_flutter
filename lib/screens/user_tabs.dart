import 'package:eaquasaver_flutter_app/screens/issue_form.dart';
import 'package:flutter/material.dart';
import 'account_screen.dart';
import 'issue_screen.dart';

class UserTabs extends StatefulWidget {
  const UserTabs({super.key});

  @override
  State<UserTabs> createState() => _UserTabsState();
}

class _UserTabsState extends State<UserTabs> {
  final PageController _userTabController = PageController();
  int _pageChanged = 0;
  String _pageTitle = 'Profile';

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
    return Scaffold(
      appBar: AppBar(
        actions: _actionsDefault(context),
        backgroundColor: Colors.green[100],
        elevation: 0,
        title: Text(_pageTitle),
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        pageSnapping: true,
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
          IssueForm(typeForm: 'new'),
          IssueForm(typeForm: 'edit'),
        ],
      ),
    );
  }
}
