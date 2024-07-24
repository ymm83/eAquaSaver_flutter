import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/bloc/bloc_bloc.dart';
import 'reviews_screen.dart';
import 'account_screen.dart';
import 'issue_screen.dart';
import 'issue_form.dart';

class UserTabs extends StatefulWidget {
  const UserTabs({super.key});

  @override
  State<UserTabs> createState() => _UserTabsState();
}

class _UserTabsState extends State<UserTabs> {
  final PageController _userTabController = PageController(keepPage: false);
  int _currentPage = 0;
  String _pageTitle = 'Profile';
  late SupabaseClient supabase;

  List<Widget> _actionsDefault(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.manage_accounts_outlined),
        onPressed: () => _userTabController.jumpToPage(1),
      ),
      IconButton(
        icon: const Icon(Icons.reviews_outlined),
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
        onPressed: () => _userTabController.jumpToPage(3),
      ),
      IconButton(
        icon: const Icon(Icons.add_box_outlined),
        onPressed: () => _userTabController.jumpToPage(4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supa = BlocProvider.of<IssueBloc>(context).supabase;
    List act = [3, 4, 5];
    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_outlined),
                onPressed: () => _userTabController.jumpToPage(0),
              )
            : null,
        leadingWidth: 40,
        actions: _currentPage == 0
            ? _actionsDefault(context)
            : ([3, 4, 5].contains(_currentPage))
                ? _actionsIssue(context)
                : _actionsDefault(context),
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
            _currentPage = index;
            _pageTitle = ['Dashboard', 'Profile', 'Reviews', 'My issues', 'New issue', 'Edit issue'][index];
          });
        },
        children: [
          const Center(child: Text('User Dashboard')),
          const AccountScreen(),
          ReviewsScreen(supabase: supa, pageController: _userTabController),
          IssueScreen(pageController: _userTabController),
          IssueForm(typeForm: 'new', supabase: supa, pageController: _userTabController),
          IssueForm(typeForm: 'edit', supabase: supa, pageController: _userTabController),
        ],
      ),
    );
  }
}
